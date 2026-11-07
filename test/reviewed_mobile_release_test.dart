import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/config/mobile_release.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/beta_login.dart';
import 'package:ilm_ai_flutter/features/learning/data/assessment_repository.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  if (!reviewedMobileRelease) {
    test(
      'reviewed release is opt-in',
      () => expect(reviewedLearning, integratedBeta),
    );
    return;
  }
  test(
    'reviewed release keeps Beta auth off and uses published assessment API',
    () {
      expect(integratedBeta, false);
      expect(integratedBetaRequested, false);
      expect(biologyOnly, false);
      expect(
        mobileAppScheme,
        reviewedMobileStaging ? 'ilmai-staging' : 'ilmai',
      );
      for (final subject in betaSubjectSlugs.where((s) => s != 'biologiya')) {
        expect(isPublishedMobileSubject(subject), true);
        expect(
          AssessmentRepository(Dio(), subject).prefix,
          '/mobile/v2/$subject',
        );
      }
      requireReviewedReleaseConfiguration('https://staging.example.test');
      for (final url in [
        'http://127.0.0.1:8930',
        'http://staging.example.test',
        'https://secret@staging.example.test',
        'https://staging.example.test/api',
        'https://staging.example.test?key=secret',
      ]) {
        expect(
          () => requireReviewedReleaseConfiguration(url),
          throwsStateError,
        );
      }
      if (reviewedMobileStaging) {
        expect(
          () => requireReviewedReleaseConfiguration(
            'https://ilm-ai-backend-256x.onrender.com',
          ),
          throwsStateError,
        );
      }
    },
  );

  testWidgets(
    'one registration action; textbook notice uses persisted onboarding state',
    (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();
      final container = ProviderContainer(
        overrides: [prefsServiceProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const OnboardingScreen()),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('provider-login')),
          ),
        ],
      );
      addTearDown(router.dispose);
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
      expect(
        find.byKey(const ValueKey('onboarding_textbook_notice')),
        findsOneWidget,
      );
      expect(find.byType(BetaLogin), findsNothing);
      expect(
        find.byKey(const ValueKey('welcome_have_account_btn')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('welcome_start_btn')), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('welcome_register_btn')),
      );
      await tester.tap(find.byKey(const ValueKey('welcome_register_btn')));
      await tester.pumpAndSettle();
      expect(find.text('provider-login'), findsOneWidget);
      expect(container.read(onboardingCompleteProvider), true);
      router.go('/');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('onboarding_textbook_notice')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      // Recreate the provider container to cover a later process opening.
      final reopened = ProviderContainer(
        overrides: [prefsServiceProvider.overrideWithValue(prefs)],
      );
      expect(reopened.read(onboardingCompleteProvider), true);
      reopened.dispose();
    },
  );
}
