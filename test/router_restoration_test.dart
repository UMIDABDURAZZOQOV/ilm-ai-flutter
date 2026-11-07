import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/router/app_router.dart';
import 'package:ilm_ai_flutter/core/services/sound_service.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_lesson_screen.dart';
import 'support/offline_preferences.dart';
import 'subject_experience_test.dart' as fixture;

class _RestorationAuth extends AuthController {
  @override
  Future<StoredTokens?> build() async => const StoredTokens(
    userId: 7,
    accessToken: 'synthetic-before',
    refreshToken: 'synthetic-refresh',
  );

  void renew() {
    state = const AsyncData(
      StoredTokens(
        userId: 7,
        accessToken: 'synthetic-after',
        refreshToken: 'synthetic-next-refresh',
      ),
    );
  }
}

void main() {
  testWidgets(
    'pushed lesson survives serialized router state and auth refresh',
    (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await PrefsService.create();
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_RestorationAuth.new),
          needsProfileSetupProvider.overrideWith((ref) => false),
          learningPreferencesProvider.overrideWith(
            (ref) => OfflinePreferences(ref.read(prefsServiceProvider)),
          ),
          skillTreeRepositoryProvider.overrideWithValue(
            fixture.FakeRepository(),
          ),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
        ],
      );
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: buildAppTheme(lightColors),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      router.push('/skills/lesson', extra: fixture.lesson);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SkillLessonScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Exercise go_router's actual route-information codec, including the
      // imperative child above /learn, not a direct bare deep-link redirect.
      final information = router.routeInformationParser.restoreRouteInformation(
        router.routerDelegate.currentConfiguration,
      )!;
      final restored = await router.routeInformationParser
          .parseRouteInformationWithDependencies(
            information,
            tester.element(find.byType(SkillLessonScreen)),
          );
      router.restore(restored);
      (container.read(authControllerProvider.notifier) as _RestorationAuth)
          .renew();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(SkillLessonScreen), findsOneWidget);
      expect(
        tester
            .widget<SkillLessonScreen>(find.byType(SkillLessonScreen))
            .lesson
            .id,
        fixture.lesson.id,
      );
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      container.dispose();
    },
  );
}
