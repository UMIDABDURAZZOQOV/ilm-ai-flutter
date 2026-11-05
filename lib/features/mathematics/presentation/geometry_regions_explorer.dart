part of 'math_models.dart';

/// Original teaching geometry, not assessment rules. The server alone awards XP.
const mathTangramPieces = <List<Offset>>[
  [Offset(0, 0), Offset(4, 0), Offset(2, 2)],
  [Offset(0, 0), Offset(2, 2), Offset(0, 4)],
  [Offset(4, 0), Offset(4, 2), Offset(3, 1)],
  [Offset(2, 2), Offset(3, 1), Offset(4, 2), Offset(3, 3)],
  [Offset(2, 2), Offset(3, 3), Offset(1, 3)],
  [Offset(4, 2), Offset(4, 4), Offset(2, 4)],
  [Offset(0, 4), Offset(1, 3), Offset(3, 3), Offset(2, 4)],
];

enum MathMirrorAxis { vertical, horizontal, diagonal }

Offset mathMirrorPoint(Offset p, MathMirrorAxis axis) => switch (axis) {
  MathMirrorAxis.vertical => Offset(6 - p.dx, p.dy),
  MathMirrorAxis.horizontal => Offset(p.dx, 6 - p.dy),
  MathMirrorAxis.diagonal => Offset(p.dy, p.dx),
};

class _GeometryRegionsExplorer extends StatefulWidget {
  final String mode;
  const _GeometryRegionsExplorer({required this.mode});
  @override
  State<_GeometryRegionsExplorer> createState() =>
      _GeometryRegionsExplorerState();
}

class _GeometryRegionsExplorerState extends State<_GeometryRegionsExplorer> {
  int family = 0, point = 0, overlay = 0, x = 1, y = 2;
  bool closed = true, room = false, rotated = false;
  MathMirrorAxis axis = MathMirrorAxis.vertical;
  final Set<int> positions = {}, pieces = {};
  static const pointPositions = [
    Offset(2, 4),
    Offset(4, 4),
    Offset(6, 4),
    Offset(1, 4),
    Offset(0, 0),
  ];
  @override
  void didUpdateWidget(_GeometryRegionsExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      family = 0;
      point = 0;
      overlay = 0;
      x = 1;
      y = 2;
      closed = true;
      room = false;
      rotated = false;
      axis = MathMirrorAxis.vertical;
      positions.clear();
      pieces.clear();
    }
  }

  Widget live(String text, String key) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  Widget board(String label, CustomPainter painter) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: CustomPaint(painter: painter),
      ),
    ),
  );
  Widget slider(
    String key,
    int value,
    String label,
    ValueChanged<int> change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label: $value'),
      Slider(
        key: ValueKey(key),
        value: value.toDouble(),
        min: 0,
        max: 6,
        divisions: 6,
        semanticFormatterCallback: (v) => '$label ${v.round()}',
        onChanged: (v) => setState(() => change(v.round())),
      ),
    ],
  );
  String location(Offset p, Offset center) {
    final d = (p - center).distanceSquared;
    return d < 4
        ? 'ichida'
        : d == 4
        ? 'chegarasida'
        : 'tashqarisida';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (widget.mode == 'geometry_quadrilateral') {
      const names = [
        'To‘g‘ri to‘rtburchak',
        'Kvadrat',
        'Romb',
        'Boshqa to‘rtburchak',
      ];
      rows.addAll([
        const Text(
          'Original oddiy shakllar: yopilganda 4 tomon va 4 uch. Shaklni burish yoki rangini o‘zgartirish tomonlar sonini almashtirmaydi.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 4; i++)
              ChoiceChip(
                label: Text(names[i]),
                selected: family == i,
                onSelected: (_) => setState(() => family = i),
              ),
          ],
        ),
        OutlinedButton(
          key: const ValueKey('quad-close'),
          onPressed: () => setState(() => closed = !closed),
          child: Text(
            closed
                ? 'Yopuvchi tomonni olib ko‘rish'
                : 'Yopuvchi tomonni qo‘shish',
          ),
        ),
        board(
          '4 uch; ${closed ? 4 : 3} tomon; ${closed ? 'yopiq' : 'ochiq'}',
          _QuadrilateralPainter(family, closed),
        ),
        live(
          '4 uch; ${closed ? 4 : 3} tomon; ${closed ? 'yopiq' : 'ochiq'}',
          'quad-state',
        ),
        Text(
          closed
              ? 'Yopiq to‘rtburchak hosil bo‘ldi.'
              : 'Yopuvchi tomon yo‘q: hali to‘rtburchakning to‘liq yopiq chegarasi emas.',
        ),
        SwitchListTile(
          key: const ValueKey('quad-room-switch'),
          value: room,
          onChanged: (v) => setState(() => room = v),
          title: const Text('Devorlar bo‘yicha sanash'),
        ),
        if (room) ...[
          const Text(
            'Kvadrat xonada har devor bo‘ylab 3 ta belgi bo‘lsin. Burchak belgisi ikkita qo‘shni devorga tegadi.',
          ),
          board(
            'Kvadrat xona: ${positions.length} ta turli belgi qo‘yilgan',
            _RoomPositionPainter(Set.of(positions)),
          ),
          const Text('Bo‘sh halqa — bo‘sh joy; sariq nuqta — qo‘yilgan belgi.'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < 8; i++)
                FilterChip(
                  label: Text(
                    i < 4 ? '${i + 1}-burchak' : '${i - 3}-devor o‘rtasi',
                  ),
                  selected: positions.contains(i),
                  onSelected: (v) => setState(
                    () => v ? positions.add(i) : positions.remove(i),
                  ),
                ),
            ],
          ),
          live('Turli belgilar: ${positions.length}', 'quad-unique'),
          for (var i = 0; i < 4; i++)
            Text(
              '${i + 1}-devor: ${(positions.contains(i) ? 1 : 0) + (positions.contains((i + 1) % 4) ? 1 : 0) + (positions.contains(i + 4) ? 1 : 0)} ta belgi',
            ),
          if (positions.length == 8)
            const Text(
              'Har devorda 3 tadan; jami esa 8 ta turli belgi. Burchak takror ko‘rinishi yangi jism emas.',
            ),
        ],
      ]);
    } else if (widget.mode == 'geometry_regions') {
      final p = pointPositions[point],
          left = location(pointPositions[point], const Offset(3, 4)),
          right = location(pointPositions[point], const Offset(5, 4));
      rows.addAll([
        const Text(
          'Ichki qism, chegaraning o‘zi va tashqari — alohida holatlar. Nuqtani tanlang va har doiraga nisbatan tekshiring.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 5; i++)
              ChoiceChip(
                label: Text(String.fromCharCode(65 + i)),
                selected: point == i,
                onSelected: (_) => setState(() => point = i),
              ),
          ],
        ),
        board(
          '${String.fromCharCode(65 + point)} nuqta: chap doira $left; o‘ng doira $right',
          _RegionPointPainter(p),
        ),
        live('Chap doira: $left; o‘ng doira: $right', 'region-location'),
        Text(
          left == 'ichida' && right == 'ichida'
              ? 'Nuqta ikkala doiraning umumiy ichki qismida.'
              : 'Nuqta ikkala doiraning umumiy ichki qismida emas.',
        ),
        const Text(
          'Chiziqning o‘zidagi nuqta ichki nuqtadan alohida aytiladi. Rasm doskasining tashqi cheti doiraning chegarasi emas. Yuza formulasi so‘ralmagan.',
        ),
      ]);
    } else if (widget.mode == 'geometry_congruent_overlay') {
      const choices = [(3, 6), (5, 4), (6, 4)];
      final b = choices[overlay],
          w = rotated ? b.$2 : b.$1,
          h = rotated ? b.$1 : b.$2;
      final equal = overlay == 0, aligned = w == 6 && h == 3;
      rows.addAll([
        const Text(
          'A — 6 cm ga 3 cmli to‘g‘ri to‘rtburchak. B ni tanlang, kerak bo‘lsa burib moslashtiring. Ikkala chizma bir masshtabda.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < choices.length; i++)
              ChoiceChip(
                label: Text('B: ${choices[i].$1} × ${choices[i].$2} cm'),
                selected: overlay == i,
                onSelected: (_) => setState(() {
                  overlay = i;
                  rotated = false;
                }),
              ),
          ],
        ),
        OutlinedButton(
          key: const ValueKey('congruence-rotate'),
          onPressed: () => setState(() => rotated = !rotated),
          child: const Text('B ni burish'),
        ),
        board(
          'A6ga3cm; B$w ga$h cm; ${aligned ? 'hozir mos' : 'hozir mos emas'}',
          _CongruencePainter(w, h),
        ),
        live(
          'A perimetri: 18 cm; B perimetri: ${2 * (w + h)} cm',
          'congruence-perimeters',
        ),
        Text(
          equal
              ? 'Shakl va o‘lcham bo‘yicha teng shakllar.'
              : 'Shakl va o‘lcham bo‘yicha teng emas.',
        ),
        Text(
          aligned
              ? 'Hozir barcha chegaralar mos keldi.'
              : equal
              ? 'Hozir yo‘nalishlari mos emas; B ni burib moslashtiring.'
              : 'Burish bu ikki o‘lchamni A nikiga aylantirmaydi.',
        ),
        const Text(
          'Hozir ustma-ust mos kelmasligi bilan umuman moslashtirish imkonsizligini aralashtirmang. Faqat teng perimetr teng shakl degani emas.',
        ),
      ]);
    } else if (widget.mode == 'geometry_tangram_guide') {
      rows.addAll([
        const Text(
          'Original 7 qismli kvadrat sxema: 5 uchburchak, 2 to‘rtburchak. Qism tugmasi uni sxemadagi berilgan joyga qo‘yadi yoki olib turadi. Bu yo‘l-yo‘riqli yig‘ish mashqi.',
        ),
        board(
          '${pieces.length} qism qo‘yilgan; jami7qism;5uchburchak va2to‘rtburchak',
          _TangramGuidePainter(Set.of(pieces)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 7; i++)
              FilterChip(
                key: ValueKey('tangram-$i'),
                label: Text(
                  '${i + 1}: ${mathTangramPieces[i].length == 3 ? 'uchburchak' : 'to‘rtburchak'}',
                ),
                selected: pieces.contains(i),
                onSelected: (v) =>
                    setState(() => v ? pieces.add(i) : pieces.remove(i)),
              ),
          ],
        ),
        live('Joylashtirildi: ${pieces.length} / 7', 'tangram-count'),
        if (pieces.length == 7)
          const Text(
            'Kvadrat sxema to‘liq yig‘ildi: ichki qoplash yoki bo‘shliq yo‘q.',
          ),
        OutlinedButton(
          onPressed: () => setState(() => pieces.clear()),
          child: const Text('Qismlarni olib turish'),
        ),
        const Text(
          'Qismlar cho‘zilmaydi yoki kesilmaydi. Qo‘shni qismlarning chegarasi tegib turishi ichki qismlari qoplashgani emas. Boshqa erkin shakllarni yig‘ish bu mashqda tekshirilmaydi.',
        ),
      ]);
    } else {
      final a = Offset(x.toDouble(), y.toDouble()),
          b = mathMirrorPoint(Offset(x.toDouble(), y.toDouble()), axis);
      const names = {
        MathMirrorAxis.vertical: 'Tik',
        MathMirrorAxis.horizontal: 'Yotiq',
        MathMirrorAxis.diagonal: 'Diagonal',
      };
      rows.addAll([
        const Text(
          'Original katakli model. Ustunlar chapdan, qatorlar tepadan 0–6 oraliq bilan sanaladi. O‘q bo‘ylab aks shakl va o‘lchamni saqlaydi.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in MathMirrorAxis.values)
              ChoiceChip(
                label: Text(names[v]!),
                selected: axis == v,
                onSelected: (_) => setState(() => axis = v),
              ),
          ],
        ),
        slider('mirror-column', x, 'Chapdan ustun oralig‘i', (v) => x = v),
        slider('mirror-row', y, 'Tepadan qator oralig‘i', (v) => y = v),
        board(
          '${names[axis]} o‘q; A${a.dx.toInt()},${a.dy.toInt()}; aks${b.dx.toInt()},${b.dy.toInt()}',
          _MirrorGridPainter(a, b, axis),
        ),
        live(
          'A: ustun $x, qator $y; aksi: ustun ${b.dx.toInt()}, qator ${b.dy.toInt()}',
          'mirror-location',
        ),
        Text(
          a == b
              ? 'Nuqta o‘q ustida: aksi aynan shu joyga tushdi.'
              : 'Ikki nuqta o‘qqa nisbatan oynadagi kabi mos.',
        ),
        const Text(
          'Faqat ikkita teng bo‘lak borligi yetarli emas: o‘q bo‘ylab buklaganda moslik zarur. Katak raqamlari joyni sanash uchun; koordinata algebrasi talab qilinmaydi.',
        ),
      ]);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

class _QuadrilateralPainter extends CustomPainter {
  final int family;
  final bool closed;
  _QuadrilateralPainter(this.family, this.closed);
  @override
  void paint(Canvas c, Size s) {
    const shapes = [
      [Offset(0, 0), Offset(6, 0), Offset(6, 3), Offset(0, 3)],
      [Offset(1, 0), Offset(5, 0), Offset(5, 4), Offset(1, 4)],
      [Offset(0, 2), Offset(3, 0), Offset(6, 2), Offset(3, 4)],
      [Offset(0, 0), Offset(5, 0), Offset(4, 3), Offset(1, 4)],
    ];
    final unit = math.min((s.width - 32) / 6, (s.height - 32) / 4),
        o = Offset(
          (s.width - 6 * math.min((s.width - 32) / 6, (s.height - 32) / 4)) / 2,
          16,
        );
    final p = shapes[family].map((v) => o + v * unit).toList();
    for (var i = 0; i < (closed ? 4 : 3); i++) {
      c.drawLine(
        p[i],
        p[(i + 1) % 4],
        Paint()
          ..color = mathIndigo
          ..strokeWidth = 4,
      );
    }
    for (final v in p) {
      c.drawCircle(v, 6, Paint()..color = mathYellow);
    }
  }

  @override
  bool shouldRepaint(_QuadrilateralPainter old) =>
      old.family != family || old.closed != closed;
}

class _RoomPositionPainter extends CustomPainter {
  final Set<int> placed;
  _RoomPositionPainter(this.placed);
  @override
  void paint(Canvas canvas, Size size) {
    final span = math.min(size.width, size.height) - 48;
    final unit = span / 4;
    final origin = Offset((size.width - span) / 2, 24);
    const points = [
      Offset(0, 0),
      Offset(4, 0),
      Offset(4, 4),
      Offset(0, 4),
      Offset(2, 0),
      Offset(4, 2),
      Offset(2, 4),
      Offset(0, 2),
    ];
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, span, span),
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(
        origin + points[i] * unit,
        9,
        Paint()..color = placed.contains(i) ? mathYellow : Colors.white,
      );
      canvas.drawCircle(
        origin + points[i] * unit,
        9,
        Paint()
          ..color = mathIndigo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RoomPositionPainter old) =>
      old.placed.length != placed.length || !old.placed.containsAll(placed);
}

class _RegionPointPainter extends CustomPainter {
  final Offset point;
  _RegionPointPainter(this.point);
  @override
  void paint(Canvas c, Size s) {
    final unit = math.min((s.width - 28) / 8, (s.height - 28) / 8),
        o = Offset(
          (s.width - 8 * math.min((s.width - 28) / 8, (s.height - 28) / 8)) / 2,
          14,
        );
    for (final center in [const Offset(3, 4), const Offset(5, 4)]) {
      c.drawCircle(
        o + center * unit,
        2 * unit,
        Paint()..color = mathTurquoise.withValues(alpha: .22),
      );
      c.drawCircle(
        o + center * unit,
        2 * unit,
        Paint()
          ..color = mathIndigo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    c.drawCircle(o + point * unit, 7, Paint()..color = mathIndigo);
    c.drawCircle(o + point * unit, 4, Paint()..color = mathYellow);
  }

  @override
  bool shouldRepaint(_RegionPointPainter old) => old.point != point;
}

class _CongruencePainter extends CustomPainter {
  final int width, height;
  _CongruencePainter(this.width, this.height);
  @override
  void paint(Canvas c, Size s) {
    final u = math.min((s.width - 32) / 8, (s.height - 32) / 8),
        o = Offset(s.width / 2, s.height / 2);
    c.drawRect(
      Rect.fromCenter(center: o, width: 6 * u, height: 3 * u),
      Paint()..color = mathYellow.withValues(alpha: .4),
    );
    c.drawRect(
      Rect.fromCenter(center: o, width: 6 * u, height: 3 * u),
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    c.drawRect(
      Rect.fromCenter(center: o, width: width * u, height: height * u),
      Paint()..color = mathTurquoise.withValues(alpha: .3),
    );
    c.drawRect(
      Rect.fromCenter(center: o, width: width * u, height: height * u),
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CongruencePainter old) =>
      old.width != width || old.height != height;
}

class _TangramGuidePainter extends CustomPainter {
  final Set<int> placed;
  _TangramGuidePainter(this.placed);
  @override
  void paint(Canvas c, Size s) {
    final u = (math.min(s.width, s.height) - 28) / 4,
        o = Offset((s.width - (math.min(s.width, s.height) - 28)) / 2, 14);
    for (var i = 0; i < mathTangramPieces.length; i++) {
      final points = mathTangramPieces[i].map((p) => o + p * u).toList();
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      if (placed.contains(i)) {
        c.drawPath(
          path,
          Paint()
            ..color = [
              mathTurquoise,
              mathYellow,
              mathIndigo.withValues(alpha: .4),
            ][i % 3],
        );
      }
      c.drawPath(
        path,
        Paint()
          ..color = mathIndigo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_TangramGuidePainter old) =>
      old.placed.length != placed.length || !old.placed.containsAll(placed);
}

class _MirrorGridPainter extends CustomPainter {
  final Offset a, b;
  final MathMirrorAxis axis;
  _MirrorGridPainter(this.a, this.b, this.axis);
  @override
  void paint(Canvas c, Size s) {
    final unit = (math.min(s.width, s.height) - 28) / 6,
        o = Offset((s.width - (math.min(s.width, s.height) - 28)) / 2, 14);
    final grid = Paint()
      ..color = mathIndigo.withValues(alpha: .25)
      ..strokeWidth = 1;
    for (var i = 0; i <= 6; i++) {
      c.drawLine(o + Offset(i * unit, 0), o + Offset(i * unit, 6 * unit), grid);
      c.drawLine(o + Offset(0, i * unit), o + Offset(6 * unit, i * unit), grid);
    }
    final ends = switch (axis) {
      MathMirrorAxis.vertical => (const Offset(3, 0), const Offset(3, 6)),
      MathMirrorAxis.horizontal => (const Offset(0, 3), const Offset(6, 3)),
      MathMirrorAxis.diagonal => (Offset.zero, const Offset(6, 6)),
    };
    c.drawLine(
      o + ends.$1 * unit,
      o + ends.$2 * unit,
      Paint()
        ..color = mathIndigo
        ..strokeWidth = 3,
    );
    c.drawCircle(o + a * unit, 8, Paint()..color = mathIndigo);
    c.drawCircle(o + b * unit, 5, Paint()..color = mathYellow);
  }

  @override
  bool shouldRepaint(_MirrorGridPainter old) =>
      old.a != a || old.b != b || old.axis != axis;
}
