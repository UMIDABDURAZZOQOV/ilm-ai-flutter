import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/router/app_router.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/application/google_auth.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/login_screen.dart';

class FakeLoggedOutAuth extends AuthController {
  @override
  Future<StoredTokens?> build() async => null;
}

class FakeLoggedInAuth extends AuthController {
  @override
  Future<StoredTokens?> build() async => const StoredTokens(
        accessToken: 'tok',
        refreshToken: 'ref',
        userId: 42,
        name: 'Learner',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LoginScreen renders Google button with uz and en localization',
      (tester) async {
    SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
    final prefs = await PrefsService.create();

    final container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(FakeLoggedOutAuth.new),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Google bilan davom etish'), findsOneWidget);
  });

  testWidgets('router sends authed user needing setup to /setup, else to /learn',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await PrefsService.create();

    // Case 1: needsProfileSetupProvider is true -> redirects to /setup
    final container1 = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(FakeLoggedInAuth.new),
        needsProfileSetupProvider.overrideWith((ref) => true),
      ],
    );

    final router1 = container1.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container1,
        child: MaterialApp.router(
          theme: buildAppTheme(lightColors),
          routerConfig: router1,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(router1.state.matchedLocation, '/setup');

    // Case 2: needsProfileSetupProvider is false -> redirects to /learn
    final container2 = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(FakeLoggedInAuth.new),
        needsProfileSetupProvider.overrideWith((ref) => false),
      ],
    );

    final router2 = container2.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container2,
        child: MaterialApp.router(
          theme: buildAppTheme(lightColors),
          routerConfig: router2,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(router2.state.matchedLocation, '/learn');
  });

  test('googleAuthTimeout is set to 30 seconds', () {
    expect(googleAuthTimeout, const Duration(seconds: 30));
  });
}
