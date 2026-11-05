import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_models.dart';

void main() {
  testWidgets(
    'all8nonnegative routes agree and an insufficient component cannot be selected',
    (tester) async {
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
              body: SingleChildScrollView(
                child: MathExplorer(mode: 'sum_remove_part'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      final samples = ['(28 + 17) − 7', '(34 + 27) − 18', '(18 + 26) − 20'];
      final answers = ['38', '43', '24'];
      for (var i = 0; i < 3; i++) {
        await tap(find.widgetWithText(ChoiceChip, samples[i]));
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('sum-remove-step')))
              .data,
          'Qadam: 1 / 3',
        );
        if (i == 2) {
          expect(
            tester
                .widget<ChoiceChip>(
                  find.byKey(const ValueKey('sum-remove-route-1')),
                )
                .onSelected,
            isNull,
          );
        }
        for (var route = 0; route < 3; route++) {
          if (i == 2 && route == 1) {
            continue;
          }
          await tap(find.byKey(ValueKey('sum-remove-route-$route')));
          for (var j = 0; j < 2; j++) {
            await tap(find.byKey(const ValueKey('sum-remove-next')));
          }
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('sum-remove-expression')),
                )
                .data,
            answers[i],
          );
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('sum-remove-next')),
                )
                .onPressed,
            isNull,
          );
          await tap(find.byKey(const ValueKey('sum-remove-back')));
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('sum-remove-step')))
                .data,
            'Qadam: 2 / 3',
          );
        }
      }
    },
  );
}
