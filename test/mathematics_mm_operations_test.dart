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

  testWidgets('mm conversion keeps zero cm and complete groups through999', (
    t,
  ) async {
    await pump(t, 'millimetre_conversion');
    for (final c in [
      (100, '1 dm 0 cm 0 mm'),
      (341, '3 dm 4 cm 1 mm'),
      (705, '7 dm 0 cm 5 mm'),
      (901, '9 dm 0 cm 1 mm'),
    ]) {
      await tap(t, 'metric-sample-${c.$1}');
      expect(find.text('${c.$1} mm = ${c.$2}'), findsOneWidget);
    }
    final slider = t.widget<Slider>(
      find.byKey(const ValueKey('metric-cm-slider')),
    );
    expect(slider.max, 999);
    slider.onChanged!(999);
    await t.pumpAndSettle();
    expect(find.text('999 mm = 9 dm 9 cm 9 mm'), findsOneWidget);
  });
  testWidgets('mm operations keep millimetre units and donor labels', (
    t,
  ) async {
    await pump(t, 'millimetre_operations');
    await tap(t, 'metric-next');
    await tap(t, 'metric-next');
    expect(
      find.text('276 mm + 348 mm = 624 mm = 6 dm 2 cm 4 mm'),
      findsOneWidget,
    );
    await tap(t, 'metric-operation-1');
    expect(find.textContaining('donor santimetr 2'), findsOneWidget);
    await tap(t, 'metric-next');
    expect(find.textContaining('donor detsimetr 5'), findsOneWidget);
    await tap(t, 'metric-next');
    expect(
      find.text('632 mm − 278 mm = 354 mm = 3 dm 5 cm 4 mm'),
      findsOneWidget,
    );
  });
  testWidgets(
    'open/closed path has correct links, vertices and one-scale totals',
    (t) async {
      await pump(t, 'metric_path_lengths');
      expect(find.text('3 bo‘g‘in, 4 belgilangan uch.'), findsOneWidget);
      expect(find.text('30 + 20 + 30 = 80 mm'), findsOneWidget);
      await tap(t, 'path-closed');
      expect(find.text('4 tomon, 4 uch.'), findsOneWidget);
      expect(find.text('30 + 20 + 30 + 20 = 100 mm'), findsOneWidget);
      t.widget<Slider>(find.byKey(const ValueKey('path-width'))).onChanged!(40);
      await t.pumpAndSettle();
      t.widget<Slider>(find.byKey(const ValueKey('path-height'))).onChanged!(
        30,
      );
      await t.pumpAndSettle();
      expect(find.text('40 + 30 + 40 + 30 = 140 mm'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'explicit transforms and leading zero normalization preserve rule',
    (t) async {
      await pump(t, 'three_digit_operation_machine');
      expect(find.text('624 → 724'), findsOneWidget);
      await tap(t, 'operation-1');
      expect(find.text('624 → 544'), findsOneWidget);
      await tap(t, 'operation-2');
      expect(find.text('624 → 264'), findsOneWidget);
      await tap(t, 'operation-3');
      expect(find.text('624 → 426'), findsOneWidget);
      t
          .widget<Slider>(find.byKey(const ValueKey('operation-input')))
          .onChanged!(400);
      await t.pumpAndSettle();
      expect(find.text('400 → 4'), findsOneWidget);
      await tap(t, 'operation-colour');
      expect(find.text('400 → 4'), findsOneWidget);
    },
  );
  testWidgets('bracket branches show independent values and reset steps', (
    t,
  ) async {
    await pump(t, 'bracket_branch_flow');
    final expected = [
      '240 + 167 − (500 − 238) = 145',
      '285 + 326 − 247 = 364',
      '850 − (436 + 218) = 196',
    ];
    for (var i = 0; i < 3; i++) {
      await tap(t, 'branch-sample-$i');
      expect(find.byKey(const ValueKey('branch-result')), findsNothing);
      await tap(t, 'branch-next');
      await tap(t, 'branch-next');
      expect(find.text(expected[i]), findsOneWidget);
      await tap(t, 'branch-back');
      expect(find.byKey(const ValueKey('branch-result')), findsNothing);
    }
  });
}
