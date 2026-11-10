import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/utils/reviewed_text.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_feedback_panel.dart';

void main() {
  const answer = 'Sovutkich oziq-ovqatni saqlash vazifasiga mos texnik misol.';
  for (final prefix in ['', 'Yana o‘ylab ko‘r: ', "Yana o'ylab ko'r: "]) {
    test('whole shown answer is not repeated after $prefix', () {
      expect(explanationAfterCorrectAnswer('$prefix$answer', answer), '');
    });
  }
  test(
    'only duplicate passage removed, distinct steps keep original order',
    () {
      expect(
        explanationAfterCorrectAnswer(
          'Birinchi qadam.\n\n$answer\n\nIkkinchi qadam.',
          answer,
        ),
        'Birinchi qadam.\n\nIkkinchi qadam.',
      );
    },
  );
  test(
    'whitespace normalization is for comparison, not scientific rewriting',
    () {
      expect(explanationAfterCorrectAnswer('H = 2.', 'H = 2n + 2.'), 'H = 2.');
      expect(explanationAfterCorrectAnswer('h = 2.', 'H = 2.'), 'h = 2.');
      expect(
        explanationAfterCorrectAnswer('Boshqa sabab. $answer', answer),
        'Boshqa sabab. $answer',
      );
      expect(
        explanationAfterCorrectAnswer('Ikki  qator\nizoh.', 'Ikki qator izoh.'),
        '',
      );
      expect(explanationAfterCorrectAnswer('Asl matn.\n', ''), 'Asl matn.\n');
    },
  );
  for (final correct in [true, false]) {
    testWidgets(
      'feedback $correct keeps answer, distinct evidence and actions',
      (tester) async {
        var continued = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(lightColors),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: LessonFeedbackPanel(
                  language: 'uz',
                  correct: correct,
                  correctAnswer: answer,
                  explanation: 'Yana o‘ylab ko‘r: $answer',
                  onContinue: () => continued++,
                  help: const Text('Synthetic help'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(answer), correct ? findsNothing : findsOneWidget);
        expect(
          find.text('Yana o‘ylab ko‘r: $answer'),
          correct ? findsOneWidget : findsNothing,
        );
        expect(find.text('Synthetic help'), findsOneWidget);
        await tester.tap(find.text('Davom etish'));
        expect(continued, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
