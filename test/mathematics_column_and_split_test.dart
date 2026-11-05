import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_models.dart';

void main() {
  Future<void> pump(WidgetTester tester, String mode) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(child: MathExplorer(mode: mode)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final mode in ['column_place_value', 'split_two_digit_subtraction']) {
    testWidgets(
      '$mode every original model at320px/200percent with backwards and reset',
      (tester) async {
        await pump(tester, mode);
        final pairs = mode == 'column_place_value'
            ? ['47 + 21', '68 − 41', '53 + 4']
            : ['54 − 28', '62 − 17', '85 − 39'];
        final expected = mode == 'column_place_value'
            ? ['47 + 21 = 68', '68 − 41 = 27', '53 + 4 = 57']
            : ['30 − 4 = 26', '50 − 5 = 45', '50 − 4 = 46'];
        for (var i = 0; i < pairs.length; i++) {
          await tap(tester, find.widgetWithText(ChoiceChip, pairs[i]));
          expect(
            tester.widget<Text>(find.byKey(const ValueKey('column-step'))).data,
            'Qadam: 1 / 4',
          );
          for (var j = 0; j < 3; j++) {
            await tap(tester, find.byKey(const ValueKey('column-next')));
          }
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('column-expression')))
                .data,
            expected[i],
          );
          expect(
            tester
                .widget<FilledButton>(find.byKey(const ValueKey('column-next')))
                .onPressed,
            isNull,
          );
          await tap(tester, find.byKey(const ValueKey('column-back')));
          expect(
            tester.widget<Text>(find.byKey(const ValueKey('column-step'))).data,
            'Qadam: 3 / 4',
          );
        }
      },
    );
  }
  for (final mode in [
    'two_digit_carry_remainder_addition',
    'two_digit_nonround_two_digit_subtraction',
  ]) {
    testWidgets(
      '$mode all original regrouping identities and unit conservation',
      (tester) async {
        await pump(tester, mode);
        final plus = mode.endsWith('addition');
        final samples = plus
            ? ['46 + 28', '57 + 26', '47 + 28', '56 + 27']
            : ['52 − 27', '64 − 38', '83 − 46'];
        final results = plus
            ? ['70 + 4 = 74', '80 + 3 = 83', '70 + 5 = 75', '80 + 3 = 83']
            : ['20 + 5 = 25', '20 + 6 = 26', '30 + 7 = 37'];
        final before = plus
            ? [
                '6 o‘nlik, 14 birlik',
                '7 o‘nlik, 13 birlik',
                '6 o‘nlik, 15 birlik',
                '7 o‘nlik, 13 birlik',
              ]
            : [
                '5 o‘nlik, 2 birlik',
                '6 o‘nlik, 4 birlik',
                '8 o‘nlik, 3 birlik',
              ];
        final regrouped = plus
            ? before
            : [
                '4 o‘nlik, 12 birlik',
                '5 o‘nlik, 14 birlik',
                '7 o‘nlik, 13 birlik',
              ];
        for (var i = 0; i < samples.length; i++) {
          await tap(tester, find.widgetWithText(ChoiceChip, samples[i]));
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('regroup-counts')))
                .data,
            before[i],
          );
          await tap(tester, find.byKey(const ValueKey('regroup-next')));
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('regroup-counts')))
                .data,
            regrouped[i],
          );
          for (var j = 0; j < 2; j++) {
            await tap(tester, find.byKey(const ValueKey('regroup-next')));
          }
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('regroup-expression')))
                .data,
            results[i],
          );
        }
      },
    );
  }
}
