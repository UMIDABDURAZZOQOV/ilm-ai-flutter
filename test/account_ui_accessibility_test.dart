import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/login_screen.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/duo_onboarding_screen.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/settings_screen.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_profile_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_quests_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_leaderboard_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/streak_calendar_widget.dart';
import 'subject_experience_test.dart' show FakeAuth;
import 'uiux_visual_review_test.dart' show reviewDio, reviewLeague;
import 'support/offline_preferences.dart';

void main() {
  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      for (final size in [const Size(320, 568), const Size(640, 360)]) {
        testWidgets(
          'account screens $lang/$dark/$size, 200%, keyboard and reduced motion',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            final dio = reviewDio();
            addTearDown(() => dio.close(force: true));
            Future<void> mount(Widget screen, {bool keyboard = false}) async {
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
              SharedPreferences.setMockInitialValues({
                PrefsKeys.language: lang,
              });
              final prefs = await PrefsService.create();
              await tester.pumpWidget(
                ProviderScope(
                  key: UniqueKey(),
                  overrides: [
                    prefsServiceProvider.overrideWithValue(prefs),
                    currentUserIdProvider.overrideWithValue(7),
                    authControllerProvider.overrideWith(FakeAuth.new),
                    dioProvider.overrideWithValue(dio),
                    skillTreeRepositoryProvider.overrideWithValue(
                      SkillTreeRepository(dio),
                    ),
                    skillExtrasRepositoryProvider.overrideWithValue(
                      SkillExtrasRepository(dio, lang),
                    ),
                    learningPreferencesProvider.overrideWithValue(
                      OfflinePreferences(prefs),
                    ),
                    skillProfileProvider.overrideWith(
                      (ref) async => SkillProfile.fromJson({
                        'name':
                            'A long learner name with several words for layout review',
                        'xp_total': 123456,
                        'streak_days': 15,
                        'lessons_completed': 406,
                        'league': reviewLeague,
                        'subjects': <dynamic>[],
                        'activity': {'2026-10-01': 3},
                      }),
                    ),
                  ],
                  child: MaterialApp(
                    theme: buildAppTheme(dark ? darkColors : lightColors),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(2),
                        disableAnimations: true,
                        viewInsets: EdgeInsets.only(
                          bottom: keyboard ? size.height * .35 : 0,
                        ),
                      ),
                      child: child!,
                    ),
                    home: screen,
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$screen initial layout',
              );
            }

            for (final screen in [
              const SkillProfileScreen(),
              const SkillQuestsScreen(),
              const SkillLeaderboardScreen(),
              const SettingsScreen(),
              const LoginScreen(),
            ]) {
              await mount(screen);
              final scrollables = find.byType(Scrollable);
              if (scrollables.evaluate().isNotEmpty) {
                await tester.drag(scrollables.first, const Offset(0, -700));
                await tester.pumpAndSettle();
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '$screen scroll',
                );
              }
            }
            await mount(
              const DuoOnboardingScreen(initialStep: 11),
              keyboard: true,
            );
            final next = find.byKey(const ValueKey('onboarding_continue_btn'));
            expect(tester.widget<Duo3DButton>(next).onPressed, isNull);
            final nameField = find.byWidgetPredicate(
              (w) => w is TextField && w.keyboardType != TextInputType.number,
            );
            final ageField = find.byWidgetPredicate(
              (w) => w is TextField && w.keyboardType == TextInputType.number,
            );
            await tester.scrollUntilVisible(
              nameField,
              100,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.enterText(nameField, 'Ali');
            await tester.pumpAndSettle();
            await tester.ensureVisible(ageField);
            await tester.enterText(ageField, '16');
            await tester.pumpAndSettle();
            expect(tester.widget<Duo3DButton>(next).onPressed, isNotNull);
            expect(next.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
            await mount(
              Scaffold(
                body: SingleChildScrollView(
                  child: StreakCalendarWidget(
                    targetMonth: DateTime(2026, 10),
                    activity: const {'2026-10-01': 3},
                    streakDays: 1,
                    language: lang,
                  ),
                ),
              ),
            );
            expect(
              find.bySemanticsLabel(RegExp('2026-10-01.*3')),
              findsOneWidget,
            );
            semantics.dispose();
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      }
    }
  }
}
