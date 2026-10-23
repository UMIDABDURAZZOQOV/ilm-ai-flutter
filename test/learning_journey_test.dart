import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/learning_journey_widgets.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_path_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_ui.dart';
import 'subject_experience_test.dart' as fixture;

class _RefreshRepository extends fixture.FakeRepository {
  bool offline = false;
  @override
  Future<SkillTreeResponse> getTree({
    required int userId,
    required String subjectSlug,
    int? grade,
  }) {
    if (offline) throw TimeoutException('offline');
    return super.getTree(
      userId: userId,
      subjectSlug: subjectSlug,
      grade: grade,
    );
  }
}

void main() {
  testWidgets(
    'failed pull refresh finishes cleanly and retry restores the same path',
    (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
      final prefs = await PrefsService.create();
      final repo = _RefreshRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue(7),
            skillTreeRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: SkillPathScreen(subject: fixture.subject),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('10/20 XP'), findsOneWidget);
      repo.offline = true;
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();
      expect(find.text('Request timed out. Please try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      repo.offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('10/20 XP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      for (final size in [const Size(320, 568), const Size(640, 360)]) {
        testWidgets(
          'journey $lang/$dark/$size is scrollable at 200% and preserves actions',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            var continues = 0, goals = 0, inspections = 0;
            final goalLabel = str3(
              lang,
              'KUNLIK MAQSAD',
              'ЦЕЛЬ ДНЯ',
              'DAILY GOAL',
            );
            final continueLabel = str3(
              lang,
              'DAVOM ETISH',
              'ПРОДОЛЖИТЬ',
              'CONTINUE',
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(dark ? darkColors : lightColors),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          LearningContinueCard(
                            language: lang,
                            title: str3(
                              lang,
                              'Keyingi o‘quv qadamingiz',
                              'Следующий учебный шаг',
                              'Your next learning step',
                            ),
                            todayXp: 10,
                            goalXp: 20,
                            onContinue: () => continues++,
                            onGoal: () => goals++,
                          ),
                          const SizedBox(height: 24),
                          for (final state in [
                            'current',
                            'locked',
                            'completed',
                            'checkpoint',
                          ])
                            LearningJourneyTile(
                              key: ValueKey(state),
                              title: str3(
                                lang,
                                'Uzun dars nomi to‘liq o‘qilishi kerak',
                                'Длинное название урока должно читаться полностью',
                                'A long lesson title must remain fully readable',
                              ),
                              stateLabel: state,
                              semanticLabel: state,
                              current: state == 'current',
                              locked: state == 'locked',
                              completed: state == 'completed',
                              checkpoint: state == 'checkpoint',
                              stars: state == 'completed' ? 2 : 0,
                              onTap: () => inspections++,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('10/20 XP'), findsOneWidget);
            await tester.ensureVisible(find.text(continueLabel));
            await tester.tap(find.text(continueLabel));
            await tester.pumpAndSettle();
            expect(continues, 1);
            await tester.ensureVisible(find.text(goalLabel));
            await tester.tap(find.text(goalLabel));
            await tester.pumpAndSettle();
            expect(goals, 1);
            final locked = find.byKey(const ValueKey('locked'));
            await tester.ensureVisible(locked);
            await tester.pumpAndSettle();
            expect(tester.getSize(locked).height, greaterThanOrEqualTo(48));
            final node = tester.getSemantics(locked);
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.tap),
              true,
            );
            await tester.tap(locked);
            await tester.pumpAndSettle();
            expect(inspections, 1);
            expect(tester.takeException(), isNull);
            semantics.dispose();
          },
        );
      }
    }
  }
}
