import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/beta_login.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_repository.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_models.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'release_hardening_test.dart' show Adapter, reply;

class _VerifiedGoogle extends AuthRepository {
  _VerifiedGoogle() : super(Dio());
  int prepares = 0, exchanges = 0;
  String? exchangedCode, exchangedVerifier;
  @override
  Future<GoogleLoginUrlResponse> prepareGoogleLogin(String challenge) async {
    prepares++;
    return const GoogleLoginUrlResponse(
      authUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
      state: 'widget-state',
    );
  }

  @override
  Future<Map<String, dynamic>> exchangeMobileCode(
    String code,
    String verifier,
  ) async {
    exchangedCode = code;
    exchangedVerifier = verifier;
    exchanges++;
    return {
      'user_id': 77,
      'access_token': 'widget-access',
      'refresh_token': 'widget-refresh',
      'name': 'Verified learner',
      'email': 'verified@example.test',
      'needs_onboarding': false,
    };
  }
}

void main() {
  if (!integratedBeta) {
    test(
      'unified beta registration remains opt-in',
      () => expect(integratedBetaRequested, isFalse),
    );
    return;
  }
  testWidgets(
    'configured registration uses only verified Google exchange and blocks repeat taps',
    (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await PrefsService.create();
      final repository = _VerifiedGoogle();
      String? browserScheme;
      const channel = MethodChannel('flutter_web_auth_2');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method != 'authenticate') return null;
        browserScheme = (call.arguments as Map)['callbackUrlScheme'] as String?;
        return 'ilmai-beta://auth/callback?code=one-use-widget-code&state=widget-state';
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      var localLogins = 0;
      final dio = Dio()
        ..httpClientAdapter = Adapter((r) {
          if (r.path == '/beta/auth/test-login') localLogins++;
          return reply(200, {'preferences': {}});
        });
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          dioProvider.overrideWithValue(dio),
          authRepositoryProvider.overrideWithValue(repository),
          betaConfigProvider.overrideWith(
            (ref) async => {
              'google_configured': true,
              'test_auth_available': true,
            },
          ),
        ],
      );
      await container.read(authControllerProvider.future);
      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/register',
            builder: (_, _) => const Scaffold(body: BetaLogin()),
          ),
          GoRoute(
            path: '/learn',
            builder: (_, _) => const Scaffold(body: Text('verified-account')),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: buildAppTheme(lightColors),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final press = tester
          .widget<Duo3DButton>(find.byKey(const ValueKey('beta_register')))
          .onPressed!;
      press();
      press();
      await tester.pumpAndSettle();
      expect(repository.prepares, 1);
      expect(repository.exchanges, 1);
      expect(repository.exchangedCode, 'one-use-widget-code');
      expect(repository.exchangedVerifier!.length, greaterThanOrEqualTo(43));
      expect(browserScheme, 'ilmai-beta');
      expect(localLogins, 0);
      expect(find.text('verified-account'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      container.dispose();
      dio.close();
    },
  );
  for (final fresh in [true, false]) {
    testWidgets(
      'single registration authenticates once and routes fresh=$fresh',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          PrefsKeys.language: 'uz',
          'subject_77': 'kimyo',
          'class_77': '7',
          'subject_88': 'biologiya',
        });
        FlutterSecureStorage.setMockInitialValues({});
        final prefs = await PrefsService.create();
        final gate = Completer<ResponseBody>();
        var logins = 0;
        final dio = Dio()
          ..httpClientAdapter = Adapter((r) {
            if (r.path == '/beta/auth/test-login') {
              logins++;
              return gate.future;
            }
            if (r.path.endsWith('/preferences')) {
              return reply(200, {
                'preferences': {'subject': 'kimyo', 'grade': '7'},
              });
            }
            return reply(200, {});
          });
        final container = ProviderContainer(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            dioProvider.overrideWithValue(dio),
            betaConfigProvider.overrideWith(
              (ref) async => {
                'google_configured': false,
                'test_auth_available': true,
              },
            ),
          ],
        );
        await container.read(authControllerProvider.future);
        final router = GoRouter(
          initialLocation: '/welcome',
          routes: [
            GoRoute(
              path: '/welcome',
              builder: (_, _) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/setup',
              builder: (_, _) =>
                  const Scaffold(body: Text('setup-destination')),
            ),
            GoRoute(
              path: '/learn',
              builder: (_, _) =>
                  const Scaffold(body: Text('learn-destination')),
            ),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: buildAppTheme(lightColors),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('welcome_start_btn')), findsNothing);
        expect(
          find.byKey(const ValueKey('welcome_have_account_btn')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('beta_register')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('onboarding_textbook_notice')),
          findsOneWidget,
        );
        expect(find.text('RO‘YXATDAN O‘TISH'), findsOneWidget);
        final callback = tester
            .widget<Duo3DButton>(find.byKey(const ValueKey('beta_register')))
            .onPressed!;
        callback();
        callback(); // Includes a stale callback before the next frame.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(logins, 1);
        gate.complete(
          reply(200, {
            'user_id': 77,
            'access_token': 'widget-access',
            'refresh_token': 'widget-refresh',
            'name': 'Learner',
            'email': 'learner@example.test',
            'needs_onboarding': fresh,
          }),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(fresh ? 'setup-destination' : 'learn-destination'),
          findsOneWidget,
        );
        expect(container.read(authControllerProvider).valueOrNull?.userId, 77);
        expect(container.read(needsProfileSetupProvider), fresh);
        expect(prefs.getBool(PrefsKeys.onboardingComplete), isTrue);
        expect(prefs.getString('subject_88'), 'biologiya');
        expect(prefs.getString('subject_77'), 'kimyo');
        expect(
          find.byKey(const ValueKey('onboarding_textbook_notice')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        container.dispose();
        dio.close();
      },
    );
  }

  testWidgets(
    'network failure allows retry without changing the installation identity',
    (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await PrefsService.create();
      final identities = <String>[];
      final dio = Dio()
        ..httpClientAdapter = Adapter((r) {
          if (r.path == '/beta/auth/test-login') {
            identities.add((r.data as Map)['installation_secret'] as String);
            return reply(503, {'detail': 'unavailable'});
          }
          return reply(200, {});
        });
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          dioProvider.overrideWithValue(dio),
          betaConfigProvider.overrideWith(
            (ref) async => {
              'google_configured': false,
              'test_auth_available': true,
            },
          ),
        ],
      );
      await container.read(authControllerProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const Scaffold(body: BetaLogin()),
          ),
        ),
      );
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('beta_register')));
        await tester.pumpAndSettle();
        expect(container.read(authControllerProvider).valueOrNull, isNull);
        expect(
          find.text(
            'Ulanish yoki autentifikatsiya bajarilmadi. Qayta urining.',
          ),
          findsOneWidget,
        );
      }
      expect(identities.length, 2);
      expect(identities.first, identities.last);
      expect(prefs.getBool(PrefsKeys.onboardingComplete), isFalse);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      dio.close();
    },
  );
}
