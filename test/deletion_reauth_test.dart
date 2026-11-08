import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/settings/application/deletion_google_auth.dart';
import 'package:ilm_ai_flutter/features/settings/data/account_deletion_repository.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/account_deletion_button.dart';
import 'account_deletion_test.dart' show DeletionAuth;
import 'release_hardening_test.dart' show Adapter, reply;

void main() {
  final id = 'dap_${'a' * 39}';
  final proof = 'p' * 43;
  for (final callback in [
    '$mobileAppScheme://auth/callback?state=del_state&code=${'a' * 43}',
    '$mobileAppScheme://deletion/callback?state=other&code=${'a' * 43}',
    '$mobileAppScheme://deletion/callback?state=del_state&state=del_state&code=${'a' * 43}',
    '$mobileAppScheme://deletion/callback?state=del_state&code=${'a' * 43}&access_token=forbidden',
    '$mobileAppScheme://deletion/callback?state=del_state&error=cancelled',
  ]) {
    test('deletion callback rejects login/cross-state/cancelled/token URL', () {
      expect(
        () => validatedDeletionCode(callback, 'del_state'),
        throwsFormatException,
      );
    });
  }
  test('deletion callback accepts only its dedicated code/state', () {
    expect(
      validatedDeletionCode(
        '$mobileAppScheme://deletion/callback?state=del_state&code=${'a' * 43}',
        'del_state',
      ),
      'a' * 43,
    );
  });
  test('proof confirmation retains bearer and disables refresh only', () async {
    final dio = Dio(apiOptions())
      ..httpClientAdapter = Adapter((request) {
        expect(request.path, '/account/deletion/reauth/confirm');
        expect(request.extra['skipAuth'], isNot(true));
        expect(request.extra['skipAuthRefresh'], isTrue);
        expect(request.data['confirmation'], 'DELETE');
        return reply(200, {'state': 'deleted', 'account_revoked': true});
      });
    expect(
      await AccountDeletionRepository(
        dio,
      ).confirmProof(DeletionProof(id, proof), CancelToken()),
      'deleted',
    );
    dio.close();
  });
  for (final method in ['google', 'password']) {
    for (final outcome in [
      'deleted',
      'pending_cleanup',
      'retention_review',
      'offline',
    ]) {
      testWidgets(
        'email-free $method requires reauth then separate deletion: $outcome',
        (tester) async {
          SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
          FlutterSecureStorage.setMockInitialValues({});
          DeletionAuth.cleared = 0;
          var verified = 0, confirmed = 0;
          final dio = Dio(apiOptions())
            ..httpClientAdapter = Adapter((request) {
              if (request.path == '/account/deletion/config') {
                return reply(200, {'available': true, 'email_required': false});
              }
              if (request.path.endsWith('/options')) {
                return reply(200, {'method': method});
              }
              if (request.path.endsWith('/password')) {
                verified++;
                expect(request.data['password'], 'test-password');
                return reply(200, {
                  'request_id': id,
                  'proof': proof,
                  'expires_in_seconds': 300,
                });
              }
              expect(request.path, '/account/deletion/reauth/confirm');
              confirmed++;
              if (outcome == 'offline') return reply(503, {});
              return reply(200, {
                'state': outcome,
                'account_revoked': outcome != 'retention_review',
              });
            });
          final container = ProviderContainer(
            overrides: [
              prefsServiceProvider.overrideWithValue(
                await PrefsService.create(),
              ),
              authControllerProvider.overrideWith(DeletionAuth.new),
              accountDeletionRepositoryProvider.overrideWithValue(
                AccountDeletionRepository(dio),
              ),
              googleDeletionReauthProvider.overrideWithValue((_, _) async {
                verified++;
                return DeletionProof(id, proof);
              }),
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
          expect(
            find.byKey(const ValueKey('delete_account_code')),
            findsNothing,
          );
          await tester.tap(
            find.byKey(const ValueKey('delete_account_consent')),
          );
          await tester.pump();
          if (method == 'password') {
            await tester.enterText(
              find.byKey(const ValueKey('delete_account_password')),
              'test-password',
            );
            await tester.pump();
          }
          final submit = find.byKey(const ValueKey('delete_account_submit'));
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(verified, 1);
          expect(confirmed, 0);
          expect(DeletionAuth.cleared, 0);
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(confirmed, 1);
          expect(
            DeletionAuth.cleared,
            ['deleted', 'pending_cleanup'].contains(outcome) ? 1 : 0,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
