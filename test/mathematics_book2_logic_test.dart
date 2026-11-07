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

  Future<void> select(WidgetTester t, String key, int n) async {
    t.widget<DropdownButton<int>>(find.byKey(ValueKey(key))).onChanged!(n);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  String value(WidgetTester t, String key) =>
      t.widget<Text>(find.byKey(ValueKey(key))).data!;

  testWidgets('overnight offset and base60 intervals stay explicit', (t) async {
    await pump(t, 'clock_offsets_overnight');
    expect(value(t, 'overnight-result'), contains('Jami 10 soat'));
    await tap(t, 'overnight-1');
    expect(value(t, 'overnight-result'), contains('5 minut kech'));
    await tap(t, 'overnight-2');
    expect(value(t, 'overnight-result'), contains('95 minut'));
  });
  testWidgets('digit search rejects wrong item and progresses exactly1to15', (
    t,
  ) async {
    await pump(t, 'logic_digit_search');
    await tap(t, 'logic-digit-7');
    expect(value(t, 'logic-digit-next'), contains('1'));
    for (var n = 1; n <= 15; n++) {
      await tap(t, 'logic-digit-$n');
    }
    expect(value(t, 'logic-digit-next'), contains('Barcha 15 son'));
    await tap(t, 'logic-digit-reset');
    expect(value(t, 'logic-digit-next'), contains('1'));
  });
  testWidgets('route returns to origin after12 steps and can reset', (t) async {
    await pump(t, 'logic_grid_route');
    for (final pair in [(4, '4,0'), (6, '4,2'), (10, '0,2'), (12, '0,0')]) {
      await tap(t, 'logic-route-next');
      expect(value(t, 'logic-route-state'), contains(pair.$2));
      expect(value(t, 'logic-route-state'), contains('${pair.$1} qadam'));
    }
    expect(
      t
          .widget<FilledButton>(find.byKey(const ValueKey('logic-route-next')))
          .onPressed,
      isNull,
    );
    await tap(t, 'logic-route-reset');
    expect(value(t, 'logic-route-state'), contains('0 qadam'));
  });
  testWidgets(
    'constraint box swap preserves unique digits and checks every constraint',
    (t) async {
      await pump(t, 'logic_constraint_boxes');
      expect(value(t, 'logic-box-result'), 'Shartlar: mos');
      await select(t, 'logic-box-0', 1);
      expect(value(t, 'logic-box-result'), contains('hali mos emas'));
      final values = List.generate(
        3,
        (i) => t
            .widget<DropdownButton<int>>(find.byKey(ValueKey('logic-box-$i')))
            .value,
      );
      expect(values.toSet(), {1, 7, 9});
      await select(t, 'logic-box-0', 7);
      expect(value(t, 'logic-box-result'), 'Shartlar: mos');
    },
  );
  testWidgets('weights cannot duplicate and all four groups must equal7kg', (
    t,
  ) async {
    await pump(t, 'logic_equal_bags');
    await tap(t, 'logic-bags-example');
    expect(value(t, 'logic-bags-result'), contains('To‘rtta guruh 7 kg'));
    await tap(t, 'logic-weight-7');
    await tap(t, 'logic-bag-2');
    expect(value(t, 'logic-bags-result'), contains('davom ettiring'));
    expect(find.text('1-guruh:  = 0 kg'), findsOneWidget);
    expect(find.text('2-guruh: 1+6+7 = 14 kg'), findsOneWidget);
    await tap(t, 'logic-bags-reset');
    expect(value(t, 'logic-bags-result'), contains('davom ettiring'));
  });
  testWidgets('tiling rejects offboard overlap and covers exactly20 cells', (
    t,
  ) async {
    await pump(t, 'logic_tiling_lab');
    await select(t, 'logic-piece-x', 3);
    await tap(t, 'logic-piece-place');
    expect(value(t, 'logic-tiling-feedback'), contains('chetdan chiqdi'));
    expect(value(t, 'logic-tiling-covered'), 'Qoplangan: 0 / 20');
    await select(t, 'logic-piece-x', 0);
    await tap(t, 'logic-piece-place');
    expect(value(t, 'logic-tiling-covered'), 'Qoplangan: 5 / 20');
    await tap(t, 'logic-piece-1');
    await tap(t, 'logic-piece-place');
    expect(value(t, 'logic-tiling-feedback'), contains('ustma-ust'));
    expect(value(t, 'logic-tiling-covered'), 'Qoplangan: 5 / 20');
    await tap(t, 'logic-tiling-example');
    expect(value(t, 'logic-tiling-covered'), 'Qoplangan: 20 / 20');
    await tap(t, 'logic-piece-remove');
    expect(value(t, 'logic-tiling-covered'), 'Qoplangan: 15 / 20');
    await tap(t, 'logic-tiling-reset');
    for (final p in [(0, 0, 0), (1, 2, 0), (2, 1, 2), (3, 0, 3)]) {
      await tap(t, 'logic-piece-${p.$1}');
      await select(t, 'logic-piece-x', p.$2);
      await select(t, 'logic-piece-y', p.$3);
      await tap(t, 'logic-piece-place');
    }
    expect(value(t, 'logic-tiling-covered'), 'Qoplangan: 20 / 20');
    await tap(t, 'logic-tiling-reset');
    await tap(t, 'logic-piece-rotate');
    expect(find.text('Burilish: 90°'), findsOneWidget);
  });
  testWidgets('hourglass measures interval3to7 rather than coldstart4', (
    t,
  ) async {
    await pump(t, 'logic_hourglass_interval');
    await tap(t, 'hourglass-1');
    expect(
      value(t, 'logic-hourglass-state'),
      contains('endi interval boshlanadi'),
    );
    await tap(t, 'hourglass-2');
    expect(value(t, 'logic-hourglass-state'), contains('7 − 3 = 4'));
    expect(find.textContaining('0 dan emas, 3 dan 7 gacha'), findsOneWidget);
  });
  testWidgets(
    'whole clock reflects and rotational rosette returns after6 turns',
    (t) async {
      await pump(t, 'logic_mirror_clock');
      expect(value(t, 'logic-clock-view'), 'Ko‘zgudagi aks');
      await tap(t, 'logic-clock-mirror');
      expect(value(t, 'logic-clock-view'), 'Asl 3:25');
      await pump(t, 'logic_rosette_pairs');
      for (var n = 1; n <= 6; n++) {
        await tap(t, 'logic-rosette-turn');
        expect(
          find.textContaining('Burilish: ${(n % 6) * 60}°'),
          findsOneWidget,
        );
      }
    },
  );
  for (final mode in [
    'mixed_review_quantities',
    'book2_final_summary',
    'logic_periodic_patterns',
    'logic_menu_pairs',
    'logic_layer_stack',
    'logic_scaled_bars',
  ]) {
    testWidgets('$mode has no overflow at320px200percent', (t) async {
      await pump(t, mode);
    });
  }
}
