part of 'math_models.dart';

/// Source-aligned teaching models; logical lengths are never physical pixels.
class _Grade2GeometryExplorer extends StatefulWidget {
  final String mode;
  const _Grade2GeometryExplorer(this.mode);
  @override
  State<_Grade2GeometryExplorer> createState() =>
      _Grade2GeometryExplorerState();
}

class _Grade2GeometryExplorerState extends State<_Grade2GeometryExplorer> {
  int kind = 0, turn = 0, extension = 1, angle = 1, rayLength = 2;
  int width = 4, height = 3;
  bool square = false, same = true;
  Widget chip(String key, String title, bool selected, VoidCallback action) =>
      ChoiceChip(
        key: ValueKey(key),
        label: Text(title),
        selected: selected,
        onSelected: (_) => setState(action),
      );
  Widget board(String label, _Grade2GeometryPainter painter) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: SizedBox(
        height: 225,
        width: double.infinity,
        child: CustomPaint(painter: painter),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final mode = widget.mode;
    if (mode == 'geometry_line_ray_segment') {
      const names = ['To‘g‘ri chiziq', 'Nur', 'Kesma'];
      children.addAll([
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var n = 0; n < 3; n++)
              chip('geo-line-$n', names[n], kind == n, () => kind = n),
          ],
        ),
        board(
          '${names[kind]}. ${kind == 0
              ? 'Ikki tomonga davom etadi'
              : kind == 1
              ? 'A dan boshlanib B orqali davom etadi'
              : 'A va B oxirgi nuqtalar'}',
          _Grade2GeometryPainter(mode, kind: kind, turn: turn),
        ),
        Text('Oxirgi nuqtalar: $kind', key: const ValueKey('geo-endpoints')),
        OutlinedButton(
          key: const ValueKey('geo-turn'),
          onPressed: () => setState(() => turn = (turn + 1) % 4),
          child: const Text('Butun chizmani burish'),
        ),
        Text('${names[kind]}: burish uning chegaralarini o‘zgartirmaydi.'),
      ]);
    } else if (mode == 'geometry_flat_plane') {
      children.addAll([
        Wrap(
          spacing: 8,
          children: [
            chip('geo-plane-bounded', 'Yassi karta', kind == 0, () => kind = 0),
            chip(
              'geo-plane-infinite',
              'Tekislik tasviri',
              kind == 1,
              () => kind = 1,
            ),
          ],
        ),
        board(
          kind == 0
              ? 'Chegaralangan yassi karta. To‘rtta cheti ko‘rsatilgan.'
              : 'Tekislik barcha yo‘nalishda davom etadi; strelkalar davom etishni bildiradi.',
          _Grade2GeometryPainter(mode, kind: kind, extension: extension),
        ),
        Text(
          kind == 0
              ? 'Kartaning cheti bor; uning sirti yassi.'
              : 'Matematik tekislik cheksiz. Ekran faqat bir qismini ko‘rsatadi.',
          key: const ValueKey('geo-plane-description'),
        ),
        OutlinedButton(
          key: const ValueKey('geo-plane-extend'),
          onPressed: kind == 1
              ? () => setState(() => extension = extension % 3 + 1)
              : null,
          child: const Text('Tasvirda ko‘proq joy ko‘rsatish'),
        ),
        const Text('Ekrandagi kataklar santimetr o‘lchagich emas.'),
      ]);
    } else if (mode == 'geometry_angle_kinds') {
      const names = ['O‘tkir', 'To‘g‘ri', 'O‘tmas'];
      children.addAll([
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var n = 0; n < 3; n++)
              chip('geo-angle-$n', names[n], angle == n, () => angle = n),
          ],
        ),
        board(
          '${names[angle]} burchak; umumiy uch va ikkita tomon. Butun burilish burchak turini o‘zgartirmaydi.',
          _Grade2GeometryPainter(
            mode,
            kind: angle,
            turn: turn,
            rayLength: rayLength,
          ),
        ),
        Text('${names[angle]} burchak', key: const ValueKey('geo-angle-kind')),
        OutlinedButton(
          key: const ValueKey('geo-angle-turn'),
          onPressed: () => setState(() => turn = (turn + 1) % 4),
          child: const Text('Ikkala tomonni birga burish'),
        ),
        const Text(
          'Tomonning chizilgan qismini o‘zgartiring; ochilish saqlanadi.',
        ),
        Slider(
          key: const ValueKey('geo-ray-length'),
          value: rayLength.toDouble(),
          min: 1,
          max: 3,
          divisions: 2,
          label: '$rayLength',
          onChanged: (v) => setState(() => rayLength = v.round()),
        ),
        const Text(
          'Kichik kvadrat belgisi to‘g‘ri burchakni bildiradi. Raqamli model qog‘ozdagi goniya mashqini almashtirmaydi.',
        ),
      ]);
    } else if (mode == 'geometry_rect_square') {
      final total = width + height + width + height;
      children.addAll([
        SwitchListTile(
          key: const ValueKey('geo-square-lock'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Kvadrat: barcha tomonlar teng'),
          value: square,
          onChanged: (v) => setState(() {
            square = v;
            if (square) height = width;
          }),
        ),
        board(
          '${width == height ? 'Kvadrat va to‘g‘ri to‘rtburchak' : 'To‘g‘ri to‘rtburchak'}. To‘rtta to‘g‘ri burchak. Tomonlar $width va $height cm deb belgilangan.',
          _Grade2GeometryPainter(mode, columns: width, rows: height),
        ),
        Text('Uzunlik: $width cm'),
        Slider(
          key: const ValueKey('geo-rectangle-width'),
          value: width.toDouble(),
          min: 2,
          max: 8,
          divisions: 6,
          label: '$width cm',
          onChanged: (v) => setState(() {
            width = v.round();
            if (square) height = width;
          }),
        ),
        Text('En: $height cm'),
        Slider(
          key: const ValueKey('geo-rectangle-height'),
          value: height.toDouble(),
          min: 2,
          max: 8,
          divisions: 6,
          label: '$height cm',
          onChanged: square ? null : (v) => setState(() => height = v.round()),
        ),
        Text(
          '$width + $height + $width + $height = $total cm',
          key: const ValueKey('geo-rectangle-perimeter'),
        ),
        Text(
          width == height
              ? 'Barcha tomonlar teng va barcha burchaklar to‘g‘ri: kvadrat. U to‘g‘ri to‘rtburchak hamdir.'
              : 'Burchaklari to‘g‘ri; barcha tomonlari teng emas. Bu to‘g‘ri to‘rtburchak.',
          key: const ValueKey('geo-rectangle-kind'),
        ),
        const Text(
          'Chizmadagi cm sonlari berilgan o‘lchamlar; ekran pikseli santimetr emas.',
        ),
      ]);
    } else {
      children.addAll([
        SwitchListTile(
          key: const ValueKey('geo-overlay-same'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Ikkinchi burchak ham to‘g‘ri'),
          value: same,
          onChanged: (v) => setState(() => same = v),
        ),
        board(
          same
              ? 'Ikki to‘g‘ri burchakning uchi va ikki tomon yo‘nalishi ustma-ust.'
              : 'Uch va bir tomon mos, ikkinchi tomon mos emas; burchaklar teng emas.',
          _Grade2GeometryPainter(mode, kind: same ? 1 : 0, turn: turn),
        ),
        Text(
          same
              ? 'Uch va ikkala tomon yo‘nalishi mos. Burchaklar teng.'
              : 'Faqat uch va bitta tomon mos. Burchaklar teng emas.',
          key: const ValueKey('geo-overlay-result'),
        ),
        OutlinedButton(
          key: const ValueKey('geo-overlay-turn'),
          onPressed: () => setState(() => turn = (turn + 1) % 4),
          child: const Text('Ikkalasini birga burish'),
        ),
        const Text(
          'Rangli nurlarning chizilgan qismlari uzunligi turlicha bo‘lsa ham, ochilishi mos kelishi mumkin.',
        ),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in children)
          Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: c),
      ],
    );
  }
}

class _Grade2GeometryPainter extends CustomPainter {
  final String mode;
  final int kind, turn, extension, rayLength, columns, rows;
  _Grade2GeometryPainter(
    this.mode, {
    this.kind = 0,
    this.turn = 0,
    this.extension = 1,
    this.rayLength = 2,
    this.columns = 4,
    this.rows = 3,
  });
  Paint stroke(Color color, [double width = 3]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  void arrow(Canvas c, Offset a, Offset b, Color color) {
    c.drawLine(a, b, stroke(color));
    final v = (a - b) / (a - b).distance;
    final normal = Offset(-v.dy, v.dx);
    c.drawLine(b, b + v * 9 + normal * 5, stroke(color));
    c.drawLine(b, b + v * 9 - normal * 5, stroke(color));
  }

  void text(Canvas c, Offset p, String value) {
    final t = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: mathIndigo,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, p - Offset(t.width / 2, t.height / 2));
  }

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2),
        r = math.min(s.width, s.height) / 2 - 32;
    final teal = const Color(0xFF0F766E);
    if (mode == 'geometry_line_ray_segment') {
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(turn * math.pi / 4);
      final a = Offset(-r * .45, 0), b = Offset(r * .45, 0);
      if (kind == 0) {
        arrow(c, Offset.zero, Offset(-r, 0), mathIndigo);
        arrow(c, Offset.zero, Offset(r, 0), mathIndigo);
      } else if (kind == 1) {
        arrow(c, a, Offset(r, 0), mathIndigo);
      } else {
        c.drawLine(a, b, stroke(mathIndigo));
      }
      c.drawCircle(a, 4, Paint()..color = mathIndigo);
      c.drawCircle(b, 4, Paint()..color = mathIndigo);
      text(c, a + const Offset(0, 19), 'A');
      text(c, b + const Offset(0, 19), 'B');
      c.restore();
    } else if (mode == 'geometry_flat_plane') {
      final w = r * .9, h = r * .55;
      c.drawRect(
        Rect.fromCenter(center: center, width: w * 2, height: h * 2),
        Paint()..color = mathTurquoise.withValues(alpha: .15),
      );
      c.drawRect(
        Rect.fromCenter(center: center, width: w * 2, height: h * 2),
        stroke(mathIndigo),
      );
      for (var i = 1; i <= extension + 2; i++) {
        final x = center.dx - w + 2 * w * i / (extension + 3);
        c.drawLine(
          Offset(x, center.dy - h),
          Offset(x, center.dy + h),
          stroke(teal, 1),
        );
      }
      if (kind == 1) {
        for (final delta in [
          Offset(r + 18, 0),
          Offset(-r - 18, 0),
          Offset(0, r + 18),
          Offset(0, -r - 18),
        ]) {
          arrow(c, center + delta * .6, center + delta, mathIndigo);
        }
      }
    } else if (mode == 'geometry_rect_square') {
      final unit = r / 5, w = columns * unit, h = rows * unit;
      final rect = Rect.fromCenter(center: center, width: w, height: h);
      c.drawRect(rect, Paint()..color = mathYellow.withValues(alpha: .25));
      c.drawRect(rect, stroke(mathIndigo));
      for (final corner in [
        (rect.topLeft, 1.0, 1.0),
        (rect.topRight, -1.0, 1.0),
        (rect.bottomLeft, 1.0, -1.0),
        (rect.bottomRight, -1.0, -1.0),
      ]) {
        final p = corner.$1;
        final dx = corner.$2 * 9, dy = corner.$3 * 9;
        c.drawLine(p + Offset(dx, 0), p + Offset(dx, dy), stroke(teal, 2));
        c.drawLine(p + Offset(0, dy), p + Offset(dx, dy), stroke(teal, 2));
      }
      text(c, Offset(center.dx, rect.top - 14), '$columns cm');
      text(c, Offset(center.dx, rect.bottom + 14), '$columns cm');
      text(c, Offset(rect.left - 23, center.dy), '$rows');
      text(c, Offset(rect.right + 23, center.dy), '$rows');
    } else {
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(turn * math.pi / 4);
      final angle =
          (kind == 0
              ? 45
              : kind == 1
              ? 90
              : 140) *
          math.pi /
          180;
      void rays(double a, double len, Color color) {
        arrow(c, Offset.zero, Offset(len, 0), color);
        arrow(c, Offset.zero, Offset(math.cos(a), -math.sin(a)) * len, color);
      }

      if (mode == 'geometry_equal_angles') {
        rays(math.pi / 2, r, mathIndigo);
        rays(angle, r * .73, teal);
      } else {
        rays(angle, r * (.55 + rayLength * .12), mathIndigo);
      }
      c.drawCircle(Offset.zero, 4, Paint()..color = mathIndigo);
      if (kind == 1) {
        c.drawLine(const Offset(12, 0), const Offset(12, -12), stroke(teal, 2));
        c.drawLine(
          const Offset(12, -12),
          const Offset(0, -12),
          stroke(teal, 2),
        );
      }
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_Grade2GeometryPainter old) =>
      mode != old.mode ||
      kind != old.kind ||
      turn != old.turn ||
      extension != old.extension ||
      rayLength != old.rayLength ||
      columns != old.columns ||
      rows != old.rows;
}
