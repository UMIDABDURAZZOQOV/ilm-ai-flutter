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

  final cases = <String, List<(int, String, String, String)>>{
    'hundreds_thousand': [
      (
        100,
        '3',
        '100 = 10 to‘liq o‘nlik + 0 birlik',
        '100 = 1 to‘liq yuzlik + 0 birlik',
      ),
      (
        1000,
        '4',
        '1000 = 100 to‘liq o‘nlik + 0 birlik',
        '1000 = 10 to‘liq yuzlik + 0 birlik',
      ),
    ],
    'three_digit_place': [
      (
        536,
        '3',
        '536 = 53 to‘liq o‘nlik + 6 birlik',
        '536 = 5 to‘liq yuzlik + 36 birlik',
      ),
      (
        629,
        '3',
        '629 = 62 to‘liq o‘nlik + 9 birlik',
        '629 = 6 to‘liq yuzlik + 29 birlik',
      ),
    ],
    'zero_tens_place': [
      (
        206,
        '3',
        '206 = 20 to‘liq o‘nlik + 6 birlik',
        '206 = 2 to‘liq yuzlik + 6 birlik',
      ),
      (
        901,
        '3',
        '901 = 90 to‘liq o‘nlik + 1 birlik',
        '901 = 9 to‘liq yuzlik + 1 birlik',
      ),
    ],
    'zero_units_place': [
      (
        640,
        '3',
        '640 = 64 to‘liq o‘nlik + 0 birlik',
        '640 = 6 to‘liq yuzlik + 40 birlik',
      ),
      (
        64,
        '2',
        '64 = 6 to‘liq o‘nlik + 4 birlik',
        '64 = 0 to‘liq yuzlik + 64 birlik',
      ),
    ],
    'full_place_groups': [
      (
        637,
        '3',
        '637 = 63 to‘liq o‘nlik + 7 birlik',
        '637 = 6 to‘liq yuzlik + 37 birlik',
      ),
      (
        1000,
        '4',
        '1000 = 100 to‘liq o‘nlik + 0 birlik',
        '1000 = 10 to‘liq yuzlik + 0 birlik',
      ),
    ],
  };
  for (final entry in cases.entries) {
    testWidgets(
      '${entry.key} exact original representations at320px/200percent',
      (t) async {
        await pump(t, entry.key);
        for (final (value, digits, tens, hundreds) in entry.value) {
          await tap(t, find.byKey(ValueKey('place-sample-$value')));
          expect(
            t.widget<Text>(find.byKey(const ValueKey('thousand-value'))).data,
            '$value',
          );
          expect(
            t.widget<Text>(find.byKey(const ValueKey('thousand-digits'))).data,
            '$digits xonali yozuv',
          );
          await tap(t, find.byKey(const ValueKey('place-representation-1')));
          expect(
            t.widget<Text>(find.byKey(const ValueKey('place-equation'))).data,
            tens,
          );
          await tap(t, find.byKey(const ValueKey('place-representation-2')));
          expect(
            t.widget<Text>(find.byKey(const ValueKey('place-equation'))).data,
            hundreds,
          );
          if (value == 1000 && entry.key == 'full_place_groups') {
            for (var i = 0; i < 3; i++) {
              expect(
                t
                    .widget<Slider>(find.byKey(ValueKey('three-digit-$i')))
                    .onChanged,
                isNull,
              );
            }
          }
        }
      },
    );
  }
  testWidgets('zero placeholders,0and999use ordinary numeral length', (
    t,
  ) async {
    await pump(t, 'three_digit_place');
    Future<void> digit(int i, int n) async {
      final f = find.byKey(ValueKey('three-digit-$i'));
      await t.ensureVisible(f);
      await t.pumpAndSettle();
      t.widget<Slider>(f).onChanged!(n.toDouble());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }

    await digit(0, 0);
    await digit(1, 0);
    await digit(2, 0);
    expect(
      t.widget<Text>(find.byKey(const ValueKey('thousand-value'))).data,
      '0',
    );
    expect(
      t.widget<Text>(find.byKey(const ValueKey('thousand-digits'))).data,
      '1 xonali yozuv',
    );
    await digit(0, 9);
    await digit(1, 9);
    await digit(2, 9);
    expect(
      t.widget<Text>(find.byKey(const ValueKey('thousand-value'))).data,
      '999',
    );
    await digit(1, 0);
    expect(
      t.widget<Text>(find.byKey(const ValueKey('thousand-value'))).data,
      '909',
    );
  });
  testWidgets('hundred slider preserves zero and thousand boundaries', (
    t,
  ) async {
    await pump(t, 'hundreds_thousand');
    for (final value in [0, 900, 1000]) {
      final f = find.byKey(const ValueKey('hundreds-slider'));
      await t.ensureVisible(f);
      await t.pumpAndSettle();
      t.widget<Slider>(f).onChanged!(value.toDouble());
      await t.pumpAndSettle();
      expect(
        t.widget<Text>(find.byKey(const ValueKey('thousand-value'))).data,
        '$value',
      );
      expect(t.takeException(), isNull);
    }
  });
}
