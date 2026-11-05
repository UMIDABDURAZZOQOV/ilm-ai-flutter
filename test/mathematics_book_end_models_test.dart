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

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  testWidgets('subtracting a sum has9equivalent original nonnegative paths', (
    t,
  ) async {
    await pump(t, 'number_remove_sum');
    final samples = ['72 − (18 + 27)', '83 − (24 + 29)', '68 − (17 + 26)'];
    final answers = ['27', '30', '25'];
    for (var i = 0; i < 3; i++) {
      await tap(t, find.widgetWithText(ChoiceChip, samples[i]));
      expect(
        t.widget<Text>(find.byKey(const ValueKey('remove-sum-step'))).data,
        'Qadam: 1 / 3',
      );
      for (var route = 0; route < 3; route++) {
        await tap(t, find.byKey(ValueKey('remove-sum-route-$route')));
        for (var j = 0; j < 2; j++) {
          await tap(t, find.byKey(const ValueKey('remove-sum-next')));
        }
        expect(
          t
              .widget<Text>(find.byKey(const ValueKey('remove-sum-expression')))
              .data,
          answers[i],
        );
        expect(
          t
              .widget<FilledButton>(
                find.byKey(const ValueKey('remove-sum-next')),
              )
              .onPressed,
          isNull,
        );
        await tap(t, find.byKey(const ValueKey('remove-sum-back')));
        expect(
          t.widget<Text>(find.byKey(const ValueKey('remove-sum-step'))).data,
          'Qadam: 2 / 3',
        );
      }
    }
  });
  testWidgets('two-line arrow counts composite shapes for every toggle state', (
    t,
  ) async {
    await pump(t, 'arrow_two_lines');
    String counts() =>
        t.widget<Text>(find.byKey(const ValueKey('arrow-counts'))).data!;
    expect(counts(), 'Uchburchaklar: 0; to‘g‘ri to‘rtburchaklar: 0');
    await tap(t, find.byKey(const ValueKey('arrow-horizontal')));
    expect(counts(), 'Uchburchaklar: 0; to‘g‘ri to‘rtburchaklar: 0');
    await tap(t, find.byKey(const ValueKey('arrow-vertical')));
    expect(counts(), 'Uchburchaklar: 3; to‘g‘ri to‘rtburchaklar: 3');
    await tap(t, find.byKey(const ValueKey('arrow-horizontal')));
    expect(counts(), 'Uchburchaklar: 1; to‘g‘ri to‘rtburchaklar: 1');
    await tap(t, find.byKey(const ValueKey('arrow-vertical')));
    expect(counts(), 'Uchburchaklar: 0; to‘g‘ri to‘rtburchaklar: 0');
  });
  testWidgets('all6proper colourings accepted;conflict and reset explained', (
    t,
  ) async {
    await pump(t, 'three_colour_regions');
    for (final colours in [
      [0, 1, 2],
      [0, 2, 1],
      [1, 0, 2],
      [1, 2, 0],
      [2, 0, 1],
      [2, 1, 0],
    ]) {
      final assignment = [colours[0], colours[1], colours[2], colours[0]];
      for (var region = 0; region < 4; region++) {
        await tap(t, find.byKey(ValueKey('region-$region')));
        await tap(
          t,
          find.byKey(ValueKey('region-colour-${assignment[region]}')),
        );
      }
      expect(
        t.widget<Text>(find.byKey(const ValueKey('region-feedback'))).data,
        'Barcha qo‘shni juftlar turli rangda.',
      );
      await tap(t, find.byKey(const ValueKey('region-1')));
      await tap(t, find.byKey(ValueKey('region-colour-${colours[0]}')));
      expect(
        t.widget<Text>(find.byKey(const ValueKey('region-feedback'))).data,
        contains('A–B'),
      );
      await tap(t, find.byKey(const ValueKey('region-reset')));
      expect(
        t.widget<Text>(find.byKey(const ValueKey('region-feedback'))).data,
        'Barcha hududlar hali ranglanmagan.',
      );
    }
  });
  testWidgets(
    'Venn counts explicit sectors once including zero and overlapping sets',
    (t) async {
      await pump(t, 'venn_distinct_sectors');
      final cases = [
        [0, 0, 0],
        [14, 5, 9],
        [10, 3, 7],
        [20, 20, 20],
      ];
      final expected = [
        'A jami: 0; B jami: 0; kamida bittasida: 0',
        'A jami: 19; B jami: 14; kamida bittasida: 28',
        'A jami: 13; B jami: 10; kamida bittasida: 20',
        'A jami: 40; B jami: 40; kamida bittasida: 60',
      ];
      for (var n = 0; n < cases.length; n++) {
        for (var i = 0; i < 3; i++) {
          final f = find.byKey(ValueKey('venn-sector-$i'));
          await t.ensureVisible(f);
          await t.pumpAndSettle();
          t.widget<Slider>(f).onChanged!(cases[n][i].toDouble());
          await t.pumpAndSettle();
        }
        expect(
          t.widget<Text>(find.byKey(const ValueKey('venn-totals'))).data,
          expected[n],
        );
        expect(t.takeException(), isNull);
      }
    },
  );
}
