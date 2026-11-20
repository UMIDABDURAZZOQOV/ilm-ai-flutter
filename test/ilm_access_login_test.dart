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
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/ilm_access_login.dart';
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
  for (final create in [true, false]) {
    testWidgets(
      'ILM key supports create=$create and reuses a failed request key',
      (tester) async {
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
        if (create) {
          await tester.tap(find.text('Create a key'));
          await tester.pumpAndSettle();
          expect(tester.widget<FilledButton>(submit).onPressed, isNull);
          await tester.tap(find.text('I saved my key'));
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
        expect(bodies[0]['mode'], create ? 'create' : 'login');
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
      },
    );
  }
}
