import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_models.dart';

void main() {
  Future<void> pump(WidgetTester t, String mode) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
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
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Future<void> tap(WidgetTester t, String key) async {
    final f = find.byKey(ValueKey(key));
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  for (final mode in ['metre_conversion', 'metre_mixed_lengths']) {
    testWidgets('$mode same length in units, zero place and full groups', (
      t,
    ) async {
      await pump(t, mode);
      final cases = mode == 'metre_conversion'
          ? [
              (100, '1 m 0 dm 0 cm'),
              (300, '3 m 0 dm 0 cm'),
              (460, '4 m 6 dm 0 cm'),
              (700, '7 m 0 dm 0 cm'),
            ]
          : [
              (127, '1 m 2 dm 7 cm'),
              (208, '2 m 0 dm 8 cm'),
              (280, '2 m 8 dm 0 cm'),
              (450, '4 m 5 dm 0 cm'),
              (608, '6 m 0 dm 8 cm'),
            ];
      for (final c in cases) {
        await tap(t, 'metric-sample-${c.$1}');
        expect(find.text('${c.$1} cm = ${c.$2}'), findsOneWidget);
      }
      final slider = t.widget<Slider>(
        find.byKey(const ValueKey('metric-cm-slider')),
      );
      slider.onChanged!(0);
      await t.pumpAndSettle();
      expect(find.text('0 cm = 0 m 0 dm 0 cm'), findsOneWidget);
      slider.onChanged!(900);
      await t.pumpAndSettle();
      expect(find.text('900 cm = 9 m 0 dm 0 cm'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'unit additions and double regrouping subtraction are equivalent to cm',
    (t) async {
      await pump(t, 'metre_length_operations');
      final expected = [
        '276 cm + 348 cm = 624 cm = 6 m 2 dm 4 cm',
        '632 cm − 278 cm = 354 cm = 3 m 5 dm 4 cm',
        '346 cm + 213 cm = 559 cm = 5 m 5 dm 9 cm',
      ];
      for (var i = 0; i < 3; i++) {
        await tap(t, 'metric-operation-$i');
        expect(
          find.byKey(const ValueKey('metric-operation-result')),
          findsNothing,
        );
        await tap(t, 'metric-next');
        await tap(t, 'metric-next');
        expect(find.text(expected[i]), findsOneWidget);
        await tap(t, 'metric-back');
        expect(
          find.byKey(const ValueKey('metric-operation-result')),
          findsNothing,
        );
      }
    },
  );
  testWidgets('metric donor unit changes are explicit rather than duplicated', (
    t,
  ) async {
    await pump(t, 'metre_length_operations');
    await tap(t, 'metric-operation-1');
    expect(find.textContaining('12 − 8 = 4'), findsOneWidget);
    expect(find.textContaining('donor detsimetr 2'), findsOneWidget);
    await tap(t, 'metric-next');
    expect(find.textContaining('12 − 7 = 5'), findsOneWidget);
    expect(find.textContaining('donor metr 5'), findsOneWidget);
  });
  testWidgets('original chart uses labelled synthetic values and selection', (
    t,
  ) async {
    await pump(t, 'metric_height_chart');
    for (final c in [
      (0, 'A', 150),
      (1, 'B', 135),
      (2, 'C', 168),
      (3, 'D', 122),
    ]) {
      await tap(t, 'metric-height-${c.$1}');
      expect(find.text('Tanlangan ${c.$2}: ${c.$3} cm'), findsOneWidget);
    }
    expect(
      find.textContaining('haqiqiy odamlar statistikasi emas'),
      findsOneWidget,
    );
  });
}
