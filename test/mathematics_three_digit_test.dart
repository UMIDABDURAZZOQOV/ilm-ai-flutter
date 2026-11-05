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

  for (final mode in ['compare_three_places', 'compare_digit_lengths']) {
    testWidgets(
      '$mode first differing place, equality, swap and 21 are correct',
      (t) async {
        await pump(t, mode);
        for (final c in [
          (583, 547, '>', 'O‘nlik'),
          (672, 679, '<', 'Birlik'),
          (103, 98, '>', 'Yuzlik'),
          (21, 210, '<', 'Yuzlik'),
          (405, 405, '=', 'Teng'),
        ]) {
          await tap(t, 'compare-${c.$1}-${c.$2}');
          expect(find.text('${c.$1} ${c.$3} ${c.$2}'), findsOneWidget);
          expect(find.text('Birinchi farq: ${c.$4}'), findsOneWidget);
        }
        await tap(t, 'compare-704-740');
        await tap(t, 'compare-swap');
        expect(find.text('740 > 704'), findsOneWidget);
        final slider = t.widget<Slider>(
          find.byKey(const ValueKey('compare-left')),
        );
        slider.onChanged!(0);
        await t.pumpAndSettle();
        expect(find.text('0 < 704'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'order is ascending or descending, without lost/duplicated values',
    (t) async {
      await pump(t, 'order_three_places');
      expect(find.text('73 < 106 < 308 < 415'), findsOneWidget);
      await tap(t, 'order-descending');
      expect(find.text('415 > 308 > 106 > 73'), findsOneWidget);
      await tap(t, 'order-ascending');
      expect(find.text('73 < 106 < 308 < 415'), findsOneWidget);
    },
  );
  for (final mode in ['add_three_no_carry', 'add_three_carry']) {
    testWidgets('$mode shows independent expected results and resets steps', (
      t,
    ) async {
      await pump(t, mode);
      final cases = mode == 'add_three_carry'
          ? [(268, 157, 425), (245, 326, 571), (185, 127, 312), (150, 170, 320)]
          : [(432, 245, 677), (621, 58, 679), (304, 210, 514), (110, 123, 233)];
      for (final c in cases) {
        await tap(t, 'add-${c.$1}-${c.$2}');
        expect(
          find.byKey(const ValueKey('three-digit-add-result')),
          findsNothing,
        );
        await tap(t, 'three-digit-next');
        await tap(t, 'three-digit-next');
        expect(find.text('${c.$1} + ${c.$2} = ${c.$3}'), findsOneWidget);
        expect(
          t
              .widget<FilledButton>(
                find.byKey(const ValueKey('three-digit-next')),
              )
              .onPressed,
          isNull,
        );
        await tap(t, 'three-digit-back');
        expect(
          find.byKey(const ValueKey('three-digit-add-result')),
          findsNothing,
        );
      }
    });
  }
  testWidgets(
    'both carry values are in the correct columns, not counted twice',
    (t) async {
      await pump(t, 'add_three_carry');
      expect(find.textContaining('8 + 7 = 15'), findsOneWidget);
      await tap(t, 'three-digit-next');
      expect(find.textContaining('6 + 5 + 1 = 12'), findsOneWidget);
      expect(
        find.text('Birlikdan: 1 o‘nlik; o‘nlikdan: 1 yuzlik'),
        findsOneWidget,
      );
      await tap(t, 'three-digit-next');
      expect(find.text('Yozilgan natija: 4 | 2 | 5'), findsOneWidget);
    },
  );
}
