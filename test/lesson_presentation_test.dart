import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/features/skills/data/lesson_draft_store.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_widgets.dart';

void main() {
  test(
    'optional content language survives snapshots; legacy payload remains valid',
    () {
      for (final language in [null, 'uz']) {
        final start = LessonStartResult.fromJson({
          'attempt_id': 1,
          'content_language': ?language,
          'theory': [
            {'title': 'Original', 'body': 'Unchanged content'},
          ],
          'questions': <dynamic>[],
        });
        final restored = LessonStartResult.fromJson(
          LessonDraftStore.snapshot(start),
        );
        expect(restored.contentLanguage, language);
        expect(restored.theory.single.body, 'Unchanged content');
      }
    },
  );

  testWidgets('choice does not reveal correctness until answered', (
    tester,
  ) async {
    Future<void> mount(bool answered) => tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(lightColors),
        home: Scaffold(
          body: DuoChoiceCard(
            text: 'Original answer',
            selected: true,
            answered: answered,
            isCorrectOption: true,
            onTap: () {},
          ),
        ),
      ),
    );
    await mount(false);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    await mount(true);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      for (final size in [const Size(320, 568), const Size(640, 360)]) {
        testWidgets('feedback $lang/$dark/$size at 200% keeps next reachable', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var taps = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(dark ? darkColors : lightColors),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: Column(
                    children: [
                      const Expanded(child: SizedBox()),
                      LessonFeedbackPanel(
                        language: lang,
                        correct: false,
                        correctAnswer: 'Original correct answer',
                        explanation: List.filled(
                          50,
                          'Original lesson explanation.',
                        ).join(' '),
                        reviewHint: true,
                        saveError: 'Result not saved. Please retry.',
                        onContinue: () => taps++,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final action = find.byType(Duo3DButton);
          expect(action.hitTestable(), findsOneWidget);
          await tester.tap(action);
          await tester.pump();
          expect(taps, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
