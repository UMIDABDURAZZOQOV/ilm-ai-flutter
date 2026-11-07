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

  Future<void> change(WidgetTester t, String key, int value) async {
    t.widget<Slider>(find.byKey(ValueKey(key))).onChanged!(value.toDouble());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  testWidgets('variable values substitute consistently and stay nonnegative', (
    t,
  ) async {
    await pump(t, 'three_digit_variable_values');
    expect(find.text('240 − 50 + 30 = 220'), findsOneWidget);
    await change(t, 'variable-x', 300);
    await change(t, 'variable-t', 80);
    await change(t, 'variable-y', 45);
    expect(find.text('300 − 80 + 45 = 265'), findsOneWidget);
    await change(t, 'variable-x', 200);
    await change(t, 'variable-t', 200);
    await change(t, 'variable-y', 0);
    expect(find.text('200 − 200 + 0 = 0'), findsOneWidget);
  });
  testWidgets('root restores equality including zero and nested equation', (
    t,
  ) async {
    await pump(t, 'three_digit_equation_root');
    for (final c in [
      (0, 555, 700),
      (1, 325, 275),
      (2, 0, 430),
      (3, 375, 700),
    ]) {
      await tap(t, 'equation-example-${c.$1}');
      await tap(t, 'equation-show');
      await change(t, 'equation-guess', c.$2);
      expect(
        find.text('Chap: ${c.$3}; o‘ng: ${c.$3}. Tenglik to‘g‘ri.'),
        findsOneWidget,
      );
      await change(t, 'equation-guess', c.$2 + 1);
      expect(find.textContaining('Hozir teng emas.'), findsOneWidget);
    }
  });
  testWidgets('inverse add/sub and fixed-width reverse retain lost zeros', (
    t,
  ) async {
    await pump(t, 'inverse_operations_three_digits');
    expect(find.text('240 + 57 = 297'), findsOneWidget);
    await tap(t, 'inverse-return');
    expect(find.text('240 + 57 − 57 = 240'), findsOneWidget);
    await tap(t, 'inverse-mode-1');
    for (final c in [('400', '004'), ('120', '021'), ('276', '672')]) {
      await tap(t, 'inverse-digits-${c.$1}');
      await tap(t, 'inverse-reverse');
      expect(find.text('Uch o‘rinli yozuv: ${c.$2}'), findsOneWidget);
      await tap(t, 'inverse-reverse');
      expect(find.text('Uch o‘rinli yozuv: ${c.$1}'), findsOneWidget);
    }
    await tap(t, 'inverse-mode-2');
    await tap(t, 'inverse-shape-reverse');
    expect(find.text('Kvadrat → Uchburchak → Doira'), findsOneWidget);
    await tap(t, 'inverse-shape-reverse');
    expect(find.text('Doira → Uchburchak → Kvadrat'), findsOneWidget);
  });
  test('clock hand angles have continuous hour position at known readings', () {
    for (final c in [
      (6, 20, 190.0, 120.0),
      (3, 30, 105.0, 180.0),
      (12, 0, 0.0, 0.0),
      (11, 55, 357.5, 330.0),
    ]) {
      final r = MathClockReading(c.$1, c.$2);
      expect(r.hourDegrees, closeTo(c.$3, 0.0001));
      expect(r.minuteDegrees, closeTo(c.$4, 0.0001));
    }
  });
  testWidgets('clock crosses12 and full hour without frozen hour hand', (
    t,
  ) async {
    await pump(t, 'analogue_clock_minutes');
    expect(find.text('6:20'), findsOneWidget);
    await change(t, 'clock-hours', 12);
    await change(t, 'clock-minutes', 55);
    expect(find.text('12:55'), findsOneWidget);
    await tap(t, 'clock-add-5');
    expect(find.text('1:00'), findsOneWidget);
    await tap(t, 'clock-add-60');
    expect(find.text('2:00'), findsOneWidget);
    await tap(t, 'clock-add--5');
    expect(find.text('1:55'), findsOneWidget);
  });
  testWidgets('time arithmetic borrows60,not100,and distinguishes interval', (
    t,
  ) async {
    await pump(t, 'hours_minutes_arithmetic');
    for (final c in [
      (0, '245 minut = 4 soat 5 minut'),
      (1, '155 minut = 2 soat 35 minut'),
      (2, '95 minut = 1 soat 35 minut'),
      (3, '150 minut = 2 soat 30 minut'),
    ]) {
      await tap(t, 'time-example-${c.$1}');
      expect(
        find.byKey(const ValueKey('time-arithmetic-result')),
        findsNothing,
      );
      await tap(t, 'time-next');
      if (c.$1 == 1) {
        expect(find.textContaining('3 soat 70 min'), findsOneWidget);
      }
      await tap(t, 'time-next');
      expect(find.text(c.$2), findsOneWidget);
      await tap(t, 'time-back');
      expect(
        find.byKey(const ValueKey('time-arithmetic-result')),
        findsNothing,
      );
    }
  });
}
