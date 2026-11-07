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
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: MathExplorer(mode: mode),
              ),
            ),
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

  Future<void> change(WidgetTester t, String key, int n) async {
    t.widget<Slider>(find.byKey(ValueKey(key))).onChanged!(n.toDouble());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  String value(WidgetTester t, String key) =>
      t.widget<Text>(find.byKey(ValueKey(key))).data!;
  testWidgets('line ray segment preserve0/1/2endpoints through rotations', (
    t,
  ) async {
    await pump(t, 'geometry_line_ray_segment');
    for (var n = 0; n < 3; n++) {
      await tap(t, 'geo-line-$n');
      for (var r = 0; r < 4; r++) {
        await tap(t, 'geo-turn');
        expect(value(t, 'geo-endpoints'), 'Oxirgi nuqtalar: $n');
      }
    }
  });
  testWidgets('bounded flat card stays distinct from unbounded plane', (
    t,
  ) async {
    await pump(t, 'geometry_flat_plane');
    expect(value(t, 'geo-plane-description'), contains('Kartaning cheti bor'));
    expect(
      t
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('geo-plane-extend')),
          )
          .onPressed,
      isNull,
    );
    await tap(t, 'geo-plane-infinite');
    for (var i = 0; i < 4; i++) {
      await tap(t, 'geo-plane-extend');
      expect(value(t, 'geo-plane-description'), contains('tekislik cheksiz'));
    }
    await tap(t, 'geo-plane-bounded');
    expect(value(t, 'geo-plane-description'), contains('Kartaning cheti bor'));
  });
  testWidgets('opening controls angle kind,not ray length or whole rotation', (
    t,
  ) async {
    await pump(t, 'geometry_angle_kinds');
    for (final pair in [(0, 'O‘tkir'), (1, 'To‘g‘ri'), (2, 'O‘tmas')]) {
      await tap(t, 'geo-angle-${pair.$1}');
      for (var r = 0; r < 4; r++) {
        await change(t, 'geo-ray-length', r % 3 + 1);
        await tap(t, 'geo-angle-turn');
        expect(value(t, 'geo-angle-kind'), '${pair.$2} burchak');
      }
    }
  });
  testWidgets(
    'square is inclusive rectangle and side-lock keeps all four equal',
    (t) async {
      await pump(t, 'geometry_rect_square');
      expect(value(t, 'geo-rectangle-perimeter'), '4 + 3 + 4 + 3 = 14 cm');
      expect(
        value(t, 'geo-rectangle-kind'),
        contains('barcha tomonlari teng emas'),
      );
      t
          .widget<SwitchListTile>(find.byKey(const ValueKey('geo-square-lock')))
          .onChanged!(true);
      await t.pumpAndSettle();
      await change(t, 'geo-rectangle-width', 7);
      expect(value(t, 'geo-rectangle-perimeter'), '7 + 7 + 7 + 7 = 28 cm');
      expect(
        value(t, 'geo-rectangle-kind'),
        contains('U to‘g‘ri to‘rtburchak hamdir'),
      );
      expect(
        t
            .widget<Slider>(find.byKey(const ValueKey('geo-rectangle-height')))
            .onChanged,
        isNull,
      );
      t
          .widget<SwitchListTile>(find.byKey(const ValueKey('geo-square-lock')))
          .onChanged!(false);
      await t.pumpAndSettle();
      await change(t, 'geo-rectangle-height', 2);
      expect(value(t, 'geo-rectangle-perimeter'), '7 + 2 + 7 + 2 = 18 cm');
    },
  );
  testWidgets(
    'equal angles require both ray directions,not just common vertex',
    (t) async {
      await pump(t, 'geometry_equal_angles');
      expect(value(t, 'geo-overlay-result'), contains('Burchaklar teng.'));
      t
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('geo-overlay-same')),
          )
          .onChanged!(false);
      await t.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tap(t, 'geo-overlay-turn');
        expect(
          value(t, 'geo-overlay-result'),
          contains('Burchaklar teng emas'),
        );
      }
      t
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('geo-overlay-same')),
          )
          .onChanged!(true);
      await t.pumpAndSettle();
      expect(value(t, 'geo-overlay-result'), contains('Burchaklar teng.'));
      expect(t.takeException(), isNull);
    },
  );
}
