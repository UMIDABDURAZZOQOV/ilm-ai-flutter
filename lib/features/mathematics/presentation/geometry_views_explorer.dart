part of 'math_models.dart';

class _GeometryViewsExplorer extends StatefulWidget {
  final String mode;
  const _GeometryViewsExplorer({required this.mode});
  @override
  State<_GeometryViewsExplorer> createState() => _GeometryViewsExplorerState();
}

class _GeometryViewsExplorerState extends State<_GeometryViewsExplorer> {
  int shape = 0, direction = 0, solid = 0, view = 0;
  bool showAxes = false;
  @override
  void didUpdateWidget(_GeometryViewsExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      shape = 0;
      direction = 0;
      solid = 0;
      view = 0;
      showAxes = false;
    }
  }

  Widget live(String s, String key) => Semantics(
    liveRegion: true,
    child: Text(
      s,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  Widget board(String label, CustomPainter painter) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: SizedBox(
        height: 230,
        width: double.infinity,
        child: CustomPaint(painter: painter),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (widget.mode == 'geometry_shape_axes') {
      const names = [
        'Kvadrat',
        '6 × 4 to‘rtburchak',
        'Kvadrat bo‘lmagan romb',
        'Teng yonli trapetsiya',
        'Doira',
        'Muntazam oltiburchak',
      ];
      const axes = ['Tik', 'Yotiq', 'Diagonal ↘', 'Diagonal ↗'];
      final matches =
          shape == 0 ||
          shape == 4 ||
          direction == 0 ||
          ((shape == 1 || shape == 2 || shape == 5) && direction == 1);
      const counts = [4, 2, 2, 1, 0, 6];
      rows.addAll([
        const Text(
          'Aniq original shakl va markazdan o‘tgan chiziqni tanlang. Buklaganda butun shakl mos kelishi kerak.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < names.length; i++)
              ChoiceChip(
                label: Text(names[i]),
                selected: shape == i,
                onSelected: (_) => setState(() => shape = i),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < axes.length; i++)
              ChoiceChip(
                label: Text(axes[i]),
                selected: direction == i,
                onSelected: (_) => setState(() => direction = i),
              ),
          ],
        ),
        board(
          '${names[shape]};${axes[direction]} chiziq ${matches ? 'mos' : 'mos emas'}',
          _ShapeAxesPainter(shape, direction, showAxes),
        ),
        live(
          matches
              ? 'Bu chiziq simmetriya o‘qi.'
              : 'Bu chiziq shu shaklning simmetriya o‘qi emas.',
          'shape-axis-match',
        ),
        Text(
          shape == 4
              ? 'Doirada o‘qlar 4 dan ham ko‘p; markazdan o‘tgan boshqa yo‘nalishlar ham mos.'
              : 'Ushbu aniq modelning simmetriya o‘qlari soni: ${counts[shape]}.',
        ),
        SwitchListTile(
          key: const ValueKey('shape-all-axes'),
          value: showAxes,
          onChanged: (v) => setState(() => showAxes = v),
          title: Text(
            shape == 4
                ? 'Bir nechta misol o‘qni ko‘rsatish'
                : 'Mos o‘qlarni birga ko‘rsatish',
          ),
        ),
        const Text(
          'Kvadratni kvadrat bo‘lmagan to‘rtburchak bilan almashtirmang. Rasmning qiya turishi o‘qlar sonini kamaytirmaydi.',
        ),
      ]);
    } else {
      const names = [
        'Shar',
        'Kub',
        'Piramida',
        'Konus',
        'Silindr',
        'Kuboid',
        'Prizma',
      ];
      const descriptions = [
        'Hajmli shar modeli. Yassi doira chizmasi bilan butun jism bir narsa emas.',
        'Kub modeli; bu yerda yassi kvadratning o‘zi tasvirlanmagan.',
        'Bu yerda kvadrat asosli piramida modeli ko‘rsatilgan.',
        'Asosi gorizontal, o‘qi tik ideal konus modeli.',
        'Asosi gorizontal, o‘qi tik ideal silindr modeli.',
        'Kuboid — to‘g‘ri burchakli parallelepiped modeli.',
        'Bu uchburchak asosli prizma modeli; boshqa prizmalar ham bo‘lishi mumkin.',
      ];
      final hasViews = solid == 3 || solid == 4;
      rows.addAll([
        const Text(
          'Original chizma hajmli modelni tasvirlaydi. Ekrandagi rasmning o‘zi haqiqiy uch o‘lchamli buyum emas.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < names.length; i++)
              ChoiceChip(
                label: Text(names[i]),
                selected: solid == i,
                onSelected: (_) => setState(() {
                  solid = i;
                  view = 0;
                }),
              ),
          ],
        ),
        if (hasViews)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(
                    ['Hajmli model', 'Tepadagi chizma', 'Yondagi chizma'][i],
                  ),
                  selected: view == i,
                  onSelected: (_) => setState(() => view = i),
                ),
            ],
          ),
        board(
          '${names[solid]};${view == 0
              ? 'hajmli model chizmasi'
              : view == 1
              ? 'tepadagi ko‘rinish'
              : 'yondagi ko‘rinish'}',
          _SolidModelPainter(solid, view),
        ),
        live(names[solid], 'solid-name'),
        Text(descriptions[solid]),
        if (hasViews && view == 1) const Text('Tepadagi ko‘rinish: doira.'),
        if (hasViews && view == 2)
          Text(
            solid == 3
                ? 'Yondagi ko‘rinish: uchburchak.'
                : 'Yondagi ko‘rinish: to‘g‘ri to‘rtburchak.',
          ),
        const Text(
          'Haqiqiy buyum modelga o‘xshashi mumkin; uni rasmiga qarab mutlaqo aniq matematik jism deb taxmin qilmaymiz.',
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

class _ShapeAxesPainter extends CustomPainter {
  final int shape, direction;
  final bool showAll;
  _ShapeAxesPainter(this.shape, this.direction, this.showAll);
  @override
  void paint(Canvas c, Size s) {
    final u = (math.min(s.width, s.height) - 36) / 6,
        o = Offset(s.width / 2, s.height / 2);
    const polygons = [
      [Offset(-2, -2), Offset(2, -2), Offset(2, 2), Offset(-2, 2)],
      [Offset(-3, -2), Offset(3, -2), Offset(3, 2), Offset(-3, 2)],
      [Offset(-3, 0), Offset(0, -2), Offset(3, 0), Offset(0, 2)],
      [Offset(-2, -2), Offset(2, -2), Offset(3, 2), Offset(-3, 2)],
    ];
    final outline = Paint()
      ..color = mathIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    if (shape == 4) {
      c.drawCircle(
        o,
        2 * u,
        Paint()..color = mathYellow.withValues(alpha: .25),
      );
      c.drawCircle(o, 2 * u, outline);
    } else {
      final points = shape == 5
          ? List.generate(
              6,
              (i) => Offset(
                2 * math.cos(-math.pi / 2 + i * math.pi / 3),
                2 * math.sin(-math.pi / 2 + i * math.pi / 3),
              ),
            )
          : polygons[shape];
      final path = Path()
        ..moveTo((o + points.first * u).dx, (o + points.first * u).dy);
      for (final p in points.skip(1)) {
        final v = o + p * u;
        path.lineTo(v.dx, v.dy);
      }
      path.close();
      c.drawPath(path, Paint()..color = mathYellow.withValues(alpha: .25));
      c.drawPath(path, outline);
    }
    void axis(double angle, Color color) {
      final d = Offset(math.cos(angle), math.sin(angle)) * 3 * u;
      c.drawLine(
        o - d,
        o + d,
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
    }

    if (showAll) {
      final angles = shape == 4
          ? List.generate(12, (i) => i * math.pi / 12)
          : shape == 5
          ? List.generate(6, (i) => i * math.pi / 6)
          : shape == 0
          ? [0.0, math.pi / 2, math.pi / 4, -math.pi / 4]
          : shape == 3
          ? [math.pi / 2]
          : [0.0, math.pi / 2];
      for (final a in angles) {
        axis(a, mathTurquoise);
      }
    }
    axis([math.pi / 2, 0.0, math.pi / 4, -math.pi / 4][direction], mathIndigo);
  }

  @override
  bool shouldRepaint(_ShapeAxesPainter old) =>
      old.shape != shape ||
      old.direction != direction ||
      old.showAll != showAll;
}

class _SolidModelPainter extends CustomPainter {
  final int solid, view;
  _SolidModelPainter(this.solid, this.view);
  void polygon(Canvas c, List<Offset> p, Color color) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (final v in p.skip(1)) {
      path.lineTo(v.dx, v.dy);
    }
    path.close();
    c.drawPath(path, Paint()..color = color);
    c.drawPath(
      path,
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void paint(Canvas c, Size s) {
    final u = (math.min(s.width, s.height) - 24) / 200;
    c.save();
    c.translate((s.width - 200 * u) / 2, (s.height - 200 * u) / 2);
    c.scale(u);
    final border = Paint()
      ..color = mathIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (view == 1 && (solid == 3 || solid == 4)) {
      c.drawCircle(
        const Offset(100, 100),
        65,
        Paint()..color = mathTurquoise.withValues(alpha: .45),
      );
      c.drawCircle(const Offset(100, 100), 65, border);
    } else if (view == 2 && (solid == 3 || solid == 4)) {
      if (solid == 3) {
        polygon(c, const [
          Offset(100, 25),
          Offset(35, 175),
          Offset(165, 175),
        ], mathTurquoise.withValues(alpha: .5));
      } else {
        c.drawRect(
          const Rect.fromLTWH(40, 25, 120, 150),
          Paint()..color = mathTurquoise.withValues(alpha: .5),
        );
        c.drawRect(const Rect.fromLTWH(40, 25, 120, 150), border);
      }
    } else if (solid == 0) {
      c.drawCircle(
        const Offset(100, 100),
        70,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.4),
            colors: [Colors.white, mathTurquoise, mathIndigo],
          ).createShader(const Rect.fromLTWH(30, 30, 140, 140)),
      );
      c.drawCircle(const Offset(100, 100), 70, border);
    } else if (solid == 1 || solid == 5) {
      final left = solid == 1 ? 40.0 : 25.0,
          width = solid == 1 ? 95.0 : 125.0,
          top = 60.0,
          height = solid == 1 ? 95.0 : 75.0;
      final a = Offset(left, top),
          b = Offset(left + width, top),
          d = Offset(left, top + height),
          e = Offset(left + width, top + height),
          shift = const Offset(28, -25);
      polygon(c, [
        a,
        b,
        b + shift,
        a + shift,
      ], mathTurquoise.withValues(alpha: .6));
      polygon(c, [
        b,
        e,
        e + shift,
        b + shift,
      ], mathIndigo.withValues(alpha: .45));
      polygon(c, [a, b, e, d], mathYellow.withValues(alpha: .7));
    } else if (solid == 2) {
      const peak = Offset(95, 25),
          a = Offset(30, 145),
          b = Offset(125, 175),
          d = Offset(175, 130);
      polygon(c, [peak, a, b], mathYellow.withValues(alpha: .75));
      polygon(c, [peak, b, d], mathTurquoise.withValues(alpha: .6));
    } else if (solid == 3) {
      polygon(c, const [
        Offset(100, 25),
        Offset(35, 165),
        Offset(165, 165),
      ], mathTurquoise.withValues(alpha: .65));
      c.drawOval(
        const Rect.fromLTWH(35, 148, 130, 34),
        Paint()..color = mathYellow.withValues(alpha: .75),
      );
      c.drawOval(const Rect.fromLTWH(35, 148, 130, 34), border);
    } else if (solid == 4) {
      c.drawOval(
        const Rect.fromLTWH(40, 145, 120, 38),
        Paint()..color = mathYellow.withValues(alpha: .7),
      );
      c.drawOval(const Rect.fromLTWH(40, 145, 120, 38), border);
      c.drawRect(
        const Rect.fromLTWH(40, 45, 120, 120),
        Paint()..color = mathTurquoise.withValues(alpha: .7),
      );
      c.drawLine(const Offset(40, 45), const Offset(40, 165), border);
      c.drawLine(const Offset(160, 45), const Offset(160, 165), border);
      c.drawOval(
        const Rect.fromLTWH(40, 26, 120, 38),
        Paint()..color = mathYellow.withValues(alpha: .7),
      );
      c.drawOval(const Rect.fromLTWH(40, 26, 120, 38), border);
    } else {
      const a = Offset(35, 170),
          b = Offset(135, 170),
          d = Offset(85, 60),
          shift = Offset(35, -30);
      polygon(c, [
        d,
        b,
        b + shift,
        d + shift,
      ], mathTurquoise.withValues(alpha: .6));
      polygon(c, [
        a,
        b,
        b + shift,
        a + shift,
      ], mathIndigo.withValues(alpha: .4));
      polygon(c, [a, b, d], mathYellow.withValues(alpha: .75));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_SolidModelPainter old) =>
      old.solid != solid || old.view != view;
}
