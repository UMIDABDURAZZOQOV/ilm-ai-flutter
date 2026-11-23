import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/ilm_access_login.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/login_screen.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'release_hardening_test.dart' show Adapter, reply;

void main() {
  test('independent access never opens on a public API origin', () {
    expect(
      ilmAccessQaEnabled('https://ilm-ai-backend-256x.onrender.com'),
      isFalse,
    );
    expect(ilmAccessQaEnabled('https://staging.example.test'), isFalse);
    if (!ilmAccessQaRequested) {
      expect(ilmAccessQaEnabled('http://127.0.0.1:8930'), isFalse);
    }
  });

  if (!ilmAccessQaEnabled(apiBaseUrl)) return;
  testWidgets('fresh Beta welcome reaches the ILM key sign-in option', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
    final prefs = await PrefsService.create();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsServiceProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: buildAppTheme(lightColors),
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('welcome_register_btn')),
    );
    await tester.tap(find.byKey(const ValueKey('welcome_register_btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ilm_access_open')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final google in [true, false]) {
    testWidgets(
      'underage QA entry stops before any registration or OAuth call, google=$google',
      (tester) async {
        SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
        final prefs = await PrefsService.create();
        final calls = <String>[];
        final dio = Dio()
          ..httpClientAdapter = Adapter((request) {
            calls.add(request.path);
            return reply(200, {'status': 'ok'});
          });
        addTearDown(dio.close);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              prefsServiceProvider.overrideWithValue(prefs),
              dioProvider.overrideWithValue(dio),
            ],
            child: MaterialApp(
              theme: buildAppTheme(lightColors),
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (google) {
          await tester.tap(find.byKey(const ValueKey('login_google')));
        } else {
          await tester.tap(find.byKey(const ValueKey('ilm_access_open')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Create a key'));
        }
        await tester.pumpAndSettle();
        final next = find.byKey(const ValueKey('qa_entry_age_continue'));
        expect(tester.widget<FilledButton>(next).onPressed, isNull);
        await tester.enterText(
          find.byKey(const ValueKey('qa_entry_age')),
          '12',
        );
        await tester.pump();
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(find.text('Guardian verification required'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('ilm_backup_generated')),
          findsNothing,
        );
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(calls, ['/health']);
        if (google) {
          await tester.tap(find.byKey(const ValueKey('login_google')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('qa_entry_age')),
            '18',
          );
          await tester.pump();
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(calls, ['/health', '/auth/mobile/config']);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final mode in ['create', 'login', 'recover']) {
    final create = mode == 'create';
    final recover = mode == 'recover';
    testWidgets('ILM key supports $mode and reuses credentials after a retry', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await PrefsService.create();
      final bodies = <Map<String, dynamic>>[];
      final dio = Dio()
        ..httpClientAdapter = Adapter((request) {
          if (request.path != '/auth/ilm/access') {
            return reply(200, {'preferences': {}});
          }
          expect(request.extra['skipAuth'], isTrue);
          bodies.add(Map<String, dynamic>.from(request.data as Map));
          if (bodies.length == 1) return reply(503, {'detail': 'try again'});
          return reply(200, {
            'user_id': 29,
            'access_token': 'test-qa-access',
            'refresh_token': 'test-qa-refresh',
            'name': 'Fixture',
            'email': '',
            'needs_onboarding': create,
          });
        });
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          dioProvider.overrideWithValue(dio),
        ],
      );
      await container.read(authControllerProvider.future);
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => Scaffold(
              body: IlmAccessLogin(blocked: false, onBusyChanged: (_) {}),
            ),
          ),
          GoRoute(
            path: '/setup',
            builder: (_, _) => const Text('fresh profile'),
          ),
          GoRoute(
            path: '/learn',
            builder: (_, _) => const Text('existing profile'),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ilm_access_open')));
      await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('ilm_access_submit'));
      if (create || recover) {
        await tester.tap(
          find.text(create ? 'Create a key' : 'Recover with a backup key'),
        );
        await tester.pumpAndSettle();
        if (create) {
          await tester.enterText(
            find.byKey(const ValueKey('qa_entry_age')),
            '25',
          );
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('qa_entry_age_continue')));
          await tester.pumpAndSettle();
        }
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
        if (recover) {
          await tester.enterText(
            find.byKey(const ValueKey('ilm_access_input')),
            'ilmr1_${'B' * 43}',
          );
        }
        final saved = find.text('I saved both keys');
        await tester.ensureVisible(saved);
        await tester.tap(saved);
      } else {
        await tester.enterText(
          find.byKey(const ValueKey('ilm_access_input')),
          'ilm1_${'A' * 43}',
        );
      }
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Sign-in failed. Try again.'), findsOneWidget);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(bodies, hasLength(2));
      expect(bodies[0], bodies[1]);
      expect(bodies[0]['mode'], mode);
      expect(bodies[0].containsKey('age'), isFalse);
      if (create || recover) {
        expect(
          bodies[0]['recovery_key'],
          matches(RegExp(r'^ilmr1_[A-Za-z0-9_-]{43}$')),
        );
      }
      if (recover) {
        expect(bodies[0]['recovery_key'], 'ilmr1_${'B' * 43}');
        expect(
          bodies[0]['next_recovery_key'],
          matches(RegExp(r'^ilmr1_[A-Za-z0-9_-]{43}$')),
        );
      }
      expect(bodies[0]['key'], matches(RegExp(r'^ilm1_[A-Za-z0-9_-]{43}$')));
      expect(container.read(authControllerProvider).valueOrNull?.userId, 29);
      expect(
        find.text(create ? 'fresh profile' : 'existing profile'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      container.dispose();
      dio.close();
    });
  }
}
