import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_repository.dart';
import 'package:ilm_ai_flutter/features/settings/data/account_deletion_repository.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/account_deletion_button.dart';
import 'release_hardening_test.dart' show Adapter, reply, original, SessionRepo;

class DeletionAuth extends AuthController {
  static int cleared = 0;
  @override
  Future<StoredTokens?> build() async => original;
  @override
  Future<void> finishAccountDeletion(
    int userId, {
    required int sessionGeneration,
  }) async {
    cleared++;
    state = const AsyncData(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final switched in [false, true]) {
    test(
      'real deletion controller clears only the acknowledged session: switched=$switched',
      () async {
        SharedPreferences.setMockInitialValues({
          'subject_1': 'biology',
          'subject_2': 'physics',
        });
        FlutterSecureStorage.setMockInitialValues({});
        final prefs = await PrefsService.create();
        final storage = SecureTokenStorage(const FlutterSecureStorage());
        await storage.saveTokens(original);
        final dio = Dio(apiOptions())
          ..httpClientAdapter = Adapter(
            (_) => reply(200, {'preferences': null}),
          );
        final container = ProviderContainer(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            secureTokenStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(SessionRepo()),
            dioProvider.overrideWithValue(dio),
          ],
        );
        await container.read(authControllerProvider.future);
        final generation = storage.sessionGeneration;
        if (switched) {
          await storage.saveTokens(
            const StoredTokens(
              userId: 2,
              accessToken: 'second',
              refreshToken: 'second-refresh',
              needsOnboarding: false,
            ),
          );
        }
        await container
            .read(authControllerProvider.notifier)
            .finishAccountDeletion(1, sessionGeneration: generation);
        await Future<void>.delayed(Duration.zero);
        expect((await storage.getTokens())?.userId, switched ? 2 : null);
        expect(
          container.read(authControllerProvider).valueOrNull?.userId,
          switched ? 2 : null,
        );
        expect(prefs.getString('subject_1'), isNull);
        expect(prefs.getString('subject_2'), 'physics');
        container.dispose();
        storage.dispose();
        dio.close(force: true);
      },
    );
  }

  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('deletion consent fits small screen at 200%: $lang/$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({PrefsKeys.language: lang});
        FlutterSecureStorage.setMockInitialValues({});
        final container = ProviderContainer(
          overrides: [
            prefsServiceProvider.overrideWithValue(await PrefsService.create()),
            authControllerProvider.overrideWith(DeletionAuth.new),
          ],
        );
        addTearDown(container.dispose);
        await container.read(authControllerProvider.future);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: dark ? ThemeData.dark() : ThemeData.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 240),
                ),
                child: child!,
              ),
              home: const Scaffold(body: AccountDeletionButton()),
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('delete_account_entry')));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.byKey(const ValueKey('delete_account_consent')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  test(
    'only the deleted account cache is removed and late writes stay blocked',
    () async {
      SharedPreferences.setMockInitialValues({
        'subject_1': 'biology',
        'subject_11': 'chemistry',
        'onboarding_draft_1': 'private',
        'onboarding_completed_1': true,
        'lesson_ui_v1:origin:1:lesson': 'private',
        'beta_v2:origin:1:physics:lesson': 'private',
        'world_history_v2:origin:1:lesson': 'private',
        PrefsKeys.language: 'uz',
        PrefsKeys.onboardingComplete: true,
      });
      final prefs = await PrefsService.create();
      await prefs.clearAccountData(1);
      expect(prefs.getString('subject_1'), isNull);
      expect(prefs.getString('onboarding_draft_1'), isNull);
      expect(prefs.getString('lesson_ui_v1:origin:1:lesson'), isNull);
      expect(prefs.getString('world_history_v2:origin:1:lesson'), isNull);
      expect(prefs.getString('subject_11'), 'chemistry');
      expect(prefs.getString(PrefsKeys.language), 'uz');
      expect(prefs.getBool(PrefsKeys.onboardingComplete), isTrue);
      final reloaded = await PrefsService.create();
      await reloaded.setString('beta_v2:origin:1:physics:lesson', 'late');
      await reloaded.setInt('daily_goal_1', 30);
      await reloaded.setBool('study_preferences_dirty_1', true);
      expect(prefs.getString('beta_v2:origin:1:physics:lesson'), isNull);
      expect(prefs.getInt('daily_goal_1'), isNull);
      expect(prefs.getBool('study_preferences_dirty_1'), isFalse);
      await reloaded.setString('subject_11', 'physics');
      expect(prefs.getString('subject_11'), 'physics');
    },
  );

  test(
    'late deletion acknowledgement cannot clear a new login to the same account',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureTokenStorage(const FlutterSecureStorage());
      await storage.saveTokens(original);
      final old = storage.sessionGeneration;
      await storage.saveTokens(original.copyWith(refreshToken: 'new-session'));
      await storage.clearTokens(expectedGeneration: old);
      expect((await storage.getTokens())!.refreshToken, 'new-session');
      await storage.clearTokens(expectedGeneration: storage.sessionGeneration);
      expect(await storage.getTokens(), isNull);
      storage.dispose();
    },
  );

  for (final result in ['deleted', 'pending_cleanup', 'retention_review']) {
    test(
      'OTP confirmation accepts honest $result receipt without bearer refresh',
      () async {
        final dio = Dio(apiOptions())
          ..httpClientAdapter = Adapter((request) {
            expect(request.path, '/account/deletion/confirm');
            expect(request.extra['skipAuth'], isTrue);
            expect(request.data['confirmation'], 'DELETE');
            return reply(200, {
              'state': result,
              'account_revoked': result != 'retention_review',
            });
          });
        expect(
          await AccountDeletionRepository(
            dio,
          ).confirm('a' * 43, '123456', CancelToken()),
          result,
        );
        dio.close();
      },
    );
  }
  for (final data in [
    {'state': 'deleted', 'account_revoked': false},
    {'state': 'retention_review', 'account_revoked': true},
    {'state': 'unknown', 'account_revoked': true},
  ]) {
    test('invalid deletion receipt is rejected: $data', () async {
      final dio = Dio(apiOptions())
        ..httpClientAdapter = Adapter((_) => reply(200, data));
      await expectLater(
        AccountDeletionRepository(
          dio,
        ).confirm('a' * 43, '123456', CancelToken()),
        throwsA(isA<FormatException>()),
      );
      dio.close();
    });
  }

  for (final outcome in [
    'deleted',
    'pending_cleanup',
    'retention_review',
    'offline',
  ]) {
    testWidgets('consent, OTP and explicit submit are required: $outcome', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await PrefsService.create();
      DeletionAuth.cleared = 0;
      int requested = 0, confirmed = 0;
      final dio = Dio(apiOptions())
        ..httpClientAdapter = Adapter((request) {
          if (request.path.endsWith('/request')) {
            requested++;
            return reply(200, {'request_id': 'a' * 43});
          }
          confirmed++;
          if (outcome == 'offline') return reply(503, {});
          return reply(200, {
            'state': outcome,
            'account_revoked': outcome != 'retention_review',
          });
        });
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(DeletionAuth.new),
          accountDeletionRepositoryProvider.overrideWithValue(
            AccountDeletionRepository(dio),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => dio.close(force: true));
      await container.read(authControllerProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: AccountDeletionButton()),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('delete_account_entry')));
      await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('delete_account_submit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('delete_account_consent')));
      await tester.pump();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(requested, 1);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('delete_account_code')),
        '123456',
      );
      await tester.pump();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(confirmed, 1);
      if (outcome == 'deleted' || outcome == 'pending_cleanup') {
        expect(DeletionAuth.cleared, 1);
        expect(find.byType(AlertDialog), findsNothing);
      } else {
        expect(DeletionAuth.cleared, 0);
        expect(
          find.byKey(const ValueKey('delete_account_error')),
          findsOneWidget,
        );
        expect(find.byType(AlertDialog), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
