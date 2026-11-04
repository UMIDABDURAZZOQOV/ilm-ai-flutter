part of 'math_models.dart';

/// Original labelled models. Pixels never certify physical centimetres or
/// handwriting. No answer/XP is computed by an explorer.
class _GeometryLengthExplorer extends StatefulWidget {
  final String mode;
  const _GeometryLengthExplorer({required this.mode});
  @override
  State<_GeometryLengthExplorer> createState() =>
      _GeometryLengthExplorerState();
}

class _GeometryLengthExplorerState extends State<_GeometryLengthExplorer> {
  int origin = 2, length = 7, endpoint = 6, cut = 3, first = 3, vertices = 5;
  bool reverse = false, closed = true, rotated = false;

  @override
  void didUpdateWidget(_GeometryLengthExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      origin = 2;
      length = 7;
      endpoint = 6;
      cut = 3;
      first = 3;
      vertices = 5;
      reverse = false;
      closed = true;
      rotated = false;
    }
  }

  Widget live(String value, String key) => Semantics(
    liveRegion: true,
    child: Text(
      value,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );

  Widget slider(
    String key,
    int value,
    int min,
    int max,
    String label,
    ValueChanged<int> change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label: $value'),
      Slider(
        key: ValueKey(key),
        value: value.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: max - min,
        semanticFormatterCallback: (v) => '$label ${v.round()}',
        onChanged: (v) => setState(() => change(v.round())),
      ),
    ],
  );

  Widget diagram(String label, CustomPainter painter, {double height = 140}) =>
      Semantics(
        label: label,
        child: ExcludeSemantics(
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(painter: painter),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final mode = widget.mode;
    if (mode == 'geometry_ruler_interval' ||
        mode == 'geometry_construct_segment') {
      final construct = mode == 'geometry_construct_segment';
      final end = construct ? endpoint : origin + length;
      children.addAll([
        const Text(
          'Yorliqli chizg‘ich modeli: har kichik oraliq 1 cm. Raqamlar har 2 oraliqda yozilgan. Telefonni haqiqiy chizg‘ich deb o‘lchamang.',
        ),
        slider('geometry-origin', origin, 0, 4, 'A belgisining cm soni', (v) {
          origin = v;
          if (endpoint < origin) endpoint = origin;
        }),
        if (construct) ...[
          slider(
            'geometry-target',
            length,
            1,
            8,
            'Kerakli uzunlik cm',
            (v) => length = v,
          ),
          slider(
            'geometry-endpoint',
            endpoint,
            origin,
            12,
            'B belgisining cm soni',
            (v) => endpoint = v,
          ),
          const Text(
            'Avval A, keyin 0 ni moslash, keyin kerakli uzunlikda B, so‘ng to‘g‘ri tutashtirish. Bu raqamli mashq fizik chizish mahoratini tasdiqlamaydi.',
          ),
        ] else
          slider(
            'geometry-length',
            length,
            1,
            8,
            'AB uzunligi cm',
            (v) => length = v,
          ),
        diagram(
          'A $origin cm; B $end cm; uzunlik ${end - origin} cm',
          _MathIntervalPainter(
            origin,
            end,
            null,
            MediaQuery.textScalerOf(context).scale(10),
          ),
        ),
        live(
          'A: $origin cm; B: $end cm; AB: ${end - origin} cm',
          'geometry-interval',
        ),
        Text(
          '$end − $origin = ${end - origin} cm. Oxirgi belgi uzunlikning o‘zi emas.',
        ),
        if (construct)
          live(
            end - origin == length
                ? 'Berilgan $length cm uzunlik hosil bo‘ldi.'
                : 'Hozir ${end - origin} cm; kerakli $length cm. B belgisini tekshiring.',
            'geometry-construction-feedback',
          ),
      ]);
    } else if (mode == 'geometry_segment_partition') {
      children.addAll([
        const Text(
          'A, C, B bir to‘g‘ri chiziqda; C aynan A bilan B orasida. AB 12 cm.',
        ),
        slider('geometry-cut', cut, 1, 11, 'AC uzunligi cm', (v) => cut = v),
        diagram(
          'AC $cut cm; CB ${12 - cut} cm; AB 12 cm; C oradagi nuqta',
          _MathIntervalPainter(
            0,
            12,
            cut,
            MediaQuery.textScalerOf(context).scale(10),
          ),
        ),
        live('AC: $cut cm; CB: ${12 - cut} cm; AB: 12 cm', 'geometry-parts'),
        Text('$cut + ${12 - cut} = 12 cm; 12 − $cut = ${12 - cut} cm.'),
        const Text(
          'Bu tenglik C orada bo‘lgan holat uchun. AB va BA ayni kesmadir.',
        ),
      ]);
    } else if (mode == 'geometry_polyline_length') {
      children.addAll([
        const Text(
          'A–B–C–D ochiq siniq yo‘l. 3 bo‘g‘in, 4 uch; AB o‘zgaradi, BC 4 cm, CD 2 cm.',
        ),
        slider(
          'geometry-first-link',
          first,
          1,
          6,
          'AB uzunligi cm',
          (v) => first = v,
        ),
        OutlinedButton(
          key: const ValueKey('geometry-bend'),
          onPressed: () => setState(() => reverse = !reverse),
          child: const Text('Burilish yo‘nalishini o‘zgartir'),
        ),
        diagram(
          'Bo‘g‘inlar $first, 4, 2 cm; jami ${first + 6} cm',
          _MathPolylinePainter(first, reverse),
          height: 230,
        ),
        live('$first + 4 + 2 = ${first + 6} cm', 'geometry-polyline-total'),
        const Text(
          'Burilish o‘zgarganda ham bo‘g‘in uzunliklari saqlanadi. Bu jami siniq yo‘l; A bilan D orasidagi to‘g‘ri kesma uzunligi so‘ralmagan.',
        ),
      ]);
    } else {
      final edges = closed ? vertices : vertices - 1;
      final names = {
        3: 'uchburchak',
        4: 'to‘rtburchak',
        5: 'beshburchak',
        6: 'oltiburchak',
      };
      children.addAll([
        const Text(
          'Original oddiy shakl modeli. Chegara to‘g‘ri bo‘g‘inlardan tuzilgan; egri chiziq yoki o‘zini kesish holati kiritilmagan.',
        ),
        slider(
          'geometry-vertices',
          vertices,
          3,
          6,
          'Uchlar soni',
          (v) => vertices = v,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('geometry-close'),
              onPressed: () => setState(() => closed = !closed),
              child: Text(
                closed ? 'Yopiq chegarani ochish' : 'Chegarani yopish',
              ),
            ),
            OutlinedButton(
              key: const ValueKey('geometry-rotate'),
              onPressed: () => setState(() => rotated = !rotated),
              child: const Text('Shaklni burish'),
            ),
          ],
        ),
        diagram(
          '$vertices uch, $edges ${closed ? 'tomon' : 'bo‘g‘in'}; ${closed ? 'yopiq' : 'ochiq'}',
          _MathPolygonPainter(vertices, closed, rotated),
          height: 210,
        ),
        live(
          '$vertices uch; $edges ${closed ? 'tomon' : 'bo‘g‘in'}; ${closed ? 'yopiq' : 'ochiq'}',
          'geometry-polygon-state',
        ),
        Text(
          closed
              ? 'Yopiq model — ${names[vertices]}. Burish uchlar yoki tomonlar sonini o‘zgartirmaydi.'
              : 'Chegara ochiq; bu holat oddiy ko‘pburchakni to‘liq chegaralamaydi.',
        ),
      ]);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _MathIntervalPainter extends CustomPainter {
  final int start, end;
  final int? split;
  final double labelSize;
  _MathIntervalPainter(this.start, this.end, this.split, this.labelSize);
  @override
  void paint(Canvas canvas, Size size) {
    final step = (size.width - 36) / 12;
    final p = Paint()
      ..color = mathIndigo
      ..strokeWidth = 2;
    double x(int n) => 18 + n * step;
    canvas.drawLine(Offset(x(0), 82), Offset(x(12), 82), p);
    for (var i = 0; i <= 12; i++) {
      canvas.drawLine(Offset(x(i), 75), Offset(x(i), 89), p);
      if (i.isEven) {
        final text = TextPainter(
          text: TextSpan(
            text: '$i',
            style: TextStyle(fontSize: labelSize, color: mathIndigo),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, Offset(x(i) - text.width / 2, 94));
      }
    }
    p.strokeWidth = 5;
    canvas.drawLine(Offset(x(start), 38), Offset(x(end), 38), p);
    for (final n in [start, end]) {
      canvas.drawCircle(Offset(x(n), 38), 5, Paint()..color = mathYellow);
    }
    if (split != null) {
      canvas.drawCircle(
        Offset(x(split!), 38),
        6,
        Paint()..color = mathTurquoise,
      );
    }
  }

  @override
  bool shouldRepaint(_MathIntervalPainter old) =>
      old.start != start ||
      old.end != end ||
      old.split != split ||
      old.labelSize != labelSize;
}

class _MathPolylinePainter extends CustomPainter {
  final int first;
  final bool reverse;
  _MathPolylinePainter(this.first, this.reverse);
  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min((size.width - 32) / 8, (size.height - 80) / 4);
    final y = reverse ? size.height - 40 : 40.0;
    final other = y + (reverse ? -4 : 4) * unit;
    final points = [
      Offset(16, y),
      Offset(16 + first * unit, y),
      Offset(16 + first * unit, other),
      Offset(16 + (first + 2) * unit, other),
    ];
    final pen = Paint()
      ..color = mathIndigo
      ..strokeWidth = 4;
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(points[i], points[i + 1], pen);
    }
    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = mathYellow);
    }
  }

  @override
  bool shouldRepaint(_MathPolylinePainter old) =>
      old.first != first || old.reverse != reverse;
}

class _MathPolygonPainter extends CustomPainter {
  final int vertices;
  final bool closed, rotated;
  _MathPolygonPainter(this.vertices, this.closed, this.rotated);
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - 15;
    final points = List.generate(vertices, (i) {
      final angle =
          -math.pi / 2 +
          i * 2 * math.pi / vertices +
          (rotated ? math.pi / 6 : 0);
      return Offset(
        size.width / 2 + r * math.cos(angle),
        size.height / 2 + r * math.sin(angle),
      );
    });
    final pen = Paint()
      ..color = mathIndigo
      ..strokeWidth = 4;
    for (var i = 0; i < (closed ? vertices : vertices - 1); i++) {
      canvas.drawLine(points[i], points[(i + 1) % vertices], pen);
    }
    for (final p in points) {
      canvas.drawCircle(p, 6, Paint()..color = mathYellow);
    }
  }

  @override
  bool shouldRepaint(_MathPolygonPainter old) =>
      old.vertices != vertices ||
      old.closed != closed ||
      old.rotated != rotated;
}
