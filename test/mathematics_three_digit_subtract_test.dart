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

  final cases = <String, List<(int, int, int)>>{
    'subtract_three_regroup': [
      (463, 158, 305),
      (574, 236, 338),
      (572, 240, 332),
    ],
    'subtract_three_double': [
      (634, 278, 356),
      (745, 386, 359),
      (820, 290, 530),
    ],
    'subtract_round_hundred': [
      (700, 286, 414),
      (800, 357, 443),
      (900, 460, 440),
    ],
    'mixed_three_operations': [
      (800, 372, 428),
      (200, 176, 24),
      (900, 368, 532),
    ],
  };
  for (final mode in cases.keys) {
    testWidgets('$mode donor places and final differences at320px/200percent', (
      t,
    ) async {
      await pump(t, mode);
      for (final c in cases[mode]!) {
        await tap(t, 'sub-${c.$1}-${c.$2}');
        expect(
          find.byKey(const ValueKey('three-digit-sub-result')),
          findsNothing,
        );
        await tap(t, 'three-digit-sub-next');
        await tap(t, 'three-digit-sub-next');
        expect(find.text('${c.$1} − ${c.$2} = ${c.$3}'), findsOneWidget);
        expect(
          find.text('Tekshiruv: ${c.$3} + ${c.$2} = ${c.$1}.'),
          findsOneWidget,
        );
        expect(
          t
              .widget<FilledButton>(
                find.byKey(const ValueKey('three-digit-sub-next')),
              )
              .onPressed,
          isNull,
        );
        await tap(t, 'three-digit-sub-back');
        expect(
          find.byKey(const ValueKey('three-digit-sub-result')),
          findsNothing,
        );
      }
    });
  }
  testWidgets('634 donor tens decrease before hundreds is exchanged', (
    t,
  ) async {
    await pump(t, 'subtract_three_double');
    expect(find.textContaining('o‘nlik 2 bo‘lib qoldi'), findsOneWidget);
    await tap(t, 'three-digit-sub-next');
    expect(find.textContaining('O‘nlik: 12 − 7 = 5'), findsOneWidget);
    expect(find.textContaining('yuzlik 5 bo‘lib qoldi'), findsOneWidget);
  });
  testWidgets('700 through-zero exchange conserves value', (t) async {
    await pump(t, 'subtract_round_hundred');
    expect(
      find.text('Nolli o‘nlik orqali: 700 = 6 yuzlik + 9 o‘nlik + 10 birlik.'),
      findsOneWidget,
    );
    await tap(t, 'three-digit-sub-next');
    await tap(t, 'three-digit-sub-next');
    expect(find.text('Qolgan natija: 4 | 1 | 4'), findsOneWidget);
  });
  testWidgets('mixed preview switches to addition without grading locally', (
    t,
  ) async {
    await pump(t, 'mixed_three_operations');
    await tap(t, 'mixed-addition');
    await tap(t, 'three-digit-next');
    await tap(t, 'three-digit-next');
    expect(find.text('268 + 157 = 425'), findsOneWidget);
    await tap(t, 'mixed-subtraction');
    expect(find.byKey(const ValueKey('three-digit-sub-step')), findsOneWidget);
  });
  testWidgets('three addends carry2 rather than1 and reset between samples', (
    t,
  ) async {
    await pump(t, 'add_three_rows');
    expect(find.textContaining('2 o‘nlik o‘tadi'), findsOneWidget);
    for (final c in [
      (126, 238, 147, 511),
      (215, 167, 128, 510),
      (260, 270, 350, 880),
    ]) {
      await tap(t, 'multi-${c.$1}-${c.$2}-${c.$3}');
      await tap(t, 'multi-next');
      await tap(t, 'multi-next');
      expect(
        find.text('${c.$1} + ${c.$2} + ${c.$3} = ${c.$4}'),
        findsOneWidget,
      );
      await tap(t, 'multi-back');
      expect(find.byKey(const ValueKey('multi-result')), findsNothing);
    }
  });
  testWidgets('equal-cell arrangements compare counts without physical units', (
    t,
  ) async {
    await pump(t, 'equal_cell_grid');
    expect(find.text('3 + 3 = 6 katak'), findsOneWidget);
    await tap(t, 'grid-3-2');
    expect(find.text('2 + 2 + 2 = 6 katak'), findsOneWidget);
    await tap(t, 'grid-2-4');
    expect(find.text('4 + 4 = 8 katak'), findsOneWidget);
  });
}
