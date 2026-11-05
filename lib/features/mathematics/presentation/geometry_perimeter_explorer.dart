part of 'math_models.dart';

class _GeometryPerimeterExplorer extends StatefulWidget {
  final String mode;
  const _GeometryPerimeterExplorer({required this.mode});
  @override
  State<_GeometryPerimeterExplorer> createState() =>
      _GeometryPerimeterExplorerState();
}

class _GeometryPerimeterExplorerState
    extends State<_GeometryPerimeterExplorer> {
  int sides = 4,
      side = 3,
      visited = 0,
      guess = 4,
      width = 6,
      height = 4,
      paper = 5,
      angle = 1;
  bool rotated = false;
  @override
  void didUpdateWidget(_GeometryPerimeterExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      sides = 4;
      side = 3;
      visited = 0;
      guess = 4;
      width = 6;
      height = 4;
      paper = 5;
      angle = 1;
      rotated = false;
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
  Widget diagram(String label, CustomPainter painter) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: CustomPaint(painter: painter),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (widget.mode == 'geometry_perimeter_trace') {
      rows.addAll([
        const Text(
          'Original yopiq shakl: har bir tomon uzunligi shartda teng deb berilgan. Chegarani boshlang‘ich uchga qaytguncha bir marta aylaning.',
        ),
        slider('perimeter-sides', sides, 3, 6, 'Tomonlar soni', (v) {
          sides = v;
          visited = 0;
        }),
        slider('perimeter-side', side, 1, 5, 'Har tomon cm', (v) {
          side = v;
          visited = 0;
        }),
        diagram(
          '$sides tomon, har biri $side cm; $visited tomon sanaldi',
          _PerimeterTracePainter(sides, visited),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const ValueKey('perimeter-next'),
              onPressed: visited < sides
                  ? () => setState(() => visited++)
                  : null,
              child: const Text('Keyingi tomonni sanash'),
            ),
            OutlinedButton(
              onPressed: () => setState(() => visited = 0),
              child: const Text('Qayta sanash'),
            ),
          ],
        ),
        live(
          'Sanaldi: $visited / $sides; hozirgi jami: ${visited * side} cm',
          'perimeter-counted',
        ),
        Text(
          visited == sides
              ? 'Yopiq chegara to‘liq sanaldi. P = ${sides * side} cm.'
              : 'Hali barcha tomon sanalmadi; bu son to‘liq P emas.',
        ),
        Text('${List.filled(sides, side).join(' + ')} = ${sides * side} cm'),
        const Text(
          'Bu perimetr, shakl ichidagi yuza emas. Pikselni fizik cm deb o‘lchamaymiz.',
        ),
      ]);
    } else if (widget.mode == 'geometry_perimeter_missing') {
      rows.addAll([
        const Text(
          'Original uchburchak: P = 20 cm; ma’lum tomonlar 8 cm va 6 cm. Uchinchi tomon qancha? Chizma taxminingizga qarab o‘zgarmaydi.',
        ),
        diagram(
          'Uchburchak P20cm; tomonlar8cm,6cm va noma’lum',
          _FixedPerimeterTrianglePainter(),
        ),
        slider(
          'perimeter-guess',
          guess,
          0,
          12,
          'Uchinchi tomon taxmini cm',
          (v) => guess = v,
        ),
        live('8 + 6 + $guess = ${14 + guess} cm', 'perimeter-guess-sum'),
        Text(
          guess == 6
              ? 'P ga mos: 20 − (8 + 6) = 6 cm.'
              : 'Berilgan P 20 cm. Taxmin bilan yig‘indini solishtiring.',
        ),
        const Text(
          'Taxmin haqiqiy tomon uzunligini o‘zgartirmaydi. Topilgan qiymat barcha tomonlar jamiga qayta qo‘yiladi.',
        ),
      ]);
    } else if (widget.mode == 'geometry_rectangle_perimeter') {
      rows.addAll([
        const Text(
          'Original to‘g‘ri to‘rtburchak. Qarama-qarshi tomonlar juft-juft teng; perimetr to‘rtta tomonni qamraydi.',
        ),
        slider('perimeter-width', width, 2, 8, 'Eni cm', (v) => width = v),
        slider('perimeter-height', height, 2, 6, 'Bo‘yi cm', (v) => height = v),
        diagram(
          'Eni$width cm,bo‘yi$height cm;qarama-qarshi tomonlar teng',
          _PaperBoundaryPainter(width, height, null),
        ),
        live(
          '$width + $height + $width + $height = ${2 * (width + height)} cm',
          'rectangle-perimeter',
        ),
        Text(
          width == height
              ? 'Hozir kvadrat ham, to‘g‘ri to‘rtburchak ham.'
              : 'Hozir qo‘shni tomonlari turli uzunlikdagi to‘g‘ri to‘rtburchak.',
        ),
        const Text(
          'Faqat eni va bo‘yining bitta yig‘indisi butun P emas; yuza formulasi so‘ralmagan.',
        ),
      ]);
    } else if (widget.mode == 'geometry_parallel_paper_fit') {
      rows.addAll([
        const Text(
          'Faqat tekis qog‘oz modeli, tomonlar parallel. Tashqi joy 10 cm × 6 cm. Bu haqiqiy sumka/qutining qalinligi haqidagi masala emas.',
        ),
        slider(
          'perimeter-paper',
          paper,
          2,
          8,
          'Kvadrat tomoni cm',
          (v) => paper = v,
        ),
        diagram(
          'Tashqi10ga6cm;ichki kvadrat${paper}cm;paralleljoylashish',
          _PaperBoundaryPainter(10, 6, paper),
        ),
        live('Tashqi P: 32 cm; ichki P: ${paper * 4} cm', 'paper-perimeters'),
        Text(
          paper <= 6
              ? 'Shu parallel holatda kvadrat ikkala o‘lchamga ham sig‘adi.'
              : 'Shu parallel holatda $paper cm tomon 6 cm bo‘yga sig‘maydi.',
        ),
        const Text(
          'Ichki chegarani tashqi perimetrga qo‘shmaymiz. Faqat ikki o‘lchamdan fizik buyum sig‘ishini kafolatlamaymiz.',
        ),
      ]);
    } else {
      const names = ['O‘tkir', 'To‘g‘ri', 'O‘tmas'];
      rows.addAll([
        const Text(
          'Burchak: bir umumiy uchdan chiqqan ikki nur. Strelka nurning davom etishini bildiradi; rasm cheti uning oxiri emas.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 3; i++)
              ChoiceChip(
                label: Text(names[i]),
                selected: angle == i,
                onSelected: (_) => setState(() => angle = i),
              ),
          ],
        ),
        OutlinedButton(
          key: const ValueKey('angle-rotate'),
          onPressed: () => setState(() => rotated = !rotated),
          child: const Text('Butun burchakni burish'),
        ),
        diagram(
          '${names[angle]} burchak;2nur,bittaumumiyuch',
          _RayAnglePainter(angle, rotated),
        ),
        live('${names[angle]} burchak; 2 nur; 1 umumiy uch', 'angle-kind'),
        Text(
          angle == 0
              ? 'To‘g‘ri burchakdan kichik ochilish.'
              : angle == 1
              ? 'To‘g‘ri burchak tayanchiga teng ochilish.'
              : 'To‘g‘ri burchakdan katta, lekin to‘g‘ri chiziqdek ochilishdan kichik.',
        ),
        const Text(
          'Butun chizmani burish ochilishni yoki turini o‘zgartirmaydi. Sonli gradus bilimi talab qilinmaydi. Rangni taxmin qilish o‘rniga tur nomi ochiq yozilgan.',
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

class _PerimeterTracePainter extends CustomPainter {
  final int sides, visited;
  _PerimeterTracePainter(this.sides, this.visited);
  @override
  void paint(Canvas c, Size s) {
    final r = math.min(s.width, s.height) / 2 - 18;
    final points = List.generate(
      sides,
      (i) => Offset(
        s.width / 2 + r * math.cos(-math.pi / 2 + i * 2 * math.pi / sides),
        s.height / 2 + r * math.sin(-math.pi / 2 + i * 2 * math.pi / sides),
      ),
    );
    for (var i = 0; i < sides; i++) {
      c.drawLine(
        points[i],
        points[(i + 1) % sides],
        Paint()
          ..color = (i < visited ? mathTurquoise : mathIndigo)
          ..strokeWidth = 5,
      );
    }
    for (final p in points) {
      c.drawCircle(p, 5, Paint()..color = mathYellow);
    }
  }

  @override
  bool shouldRepaint(_PerimeterTracePainter old) =>
      old.sides != sides || old.visited != visited;
}

class _FixedPerimeterTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final unit = math.min((s.width - 36) / 8, (s.height - 36) / math.sqrt(20));
    final p = [
      Offset(18, s.height - 18),
      Offset(18 + 8 * unit, s.height - 18),
      Offset(18 + 4 * unit, s.height - 18 - math.sqrt(20) * unit),
    ];
    for (var i = 0; i < 3; i++) {
      c.drawLine(
        p[i],
        p[(i + 1) % 3],
        Paint()
          ..color = mathIndigo
          ..strokeWidth = 4,
      );
    }
    for (final a in p) {
      c.drawCircle(a, 5, Paint()..color = mathYellow);
    }
  }

  @override
  bool shouldRepaint(_FixedPerimeterTrianglePainter old) => false;
}

class _PaperBoundaryPainter extends CustomPainter {
  final int width, height;
  final int? inner;
  _PaperBoundaryPainter(this.width, this.height, this.inner);
  @override
  void paint(Canvas c, Size s) {
    final unit = math.min((s.width - 36) / 10, (s.height - 36) / 8);
    c.drawRect(
      Rect.fromLTWH(18, 18, width * unit, height * unit),
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (inner != null) {
      c.drawRect(
        Rect.fromLTWH(18, 18, inner! * unit, inner! * unit),
        Paint()..color = mathTurquoise.withValues(alpha: .25),
      );
      c.drawRect(
        Rect.fromLTWH(18, 18, inner! * unit, inner! * unit),
        Paint()
          ..color = mathIndigo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_PaperBoundaryPainter old) =>
      old.width != width || old.height != height || old.inner != inner;
}

class _RayAnglePainter extends CustomPainter {
  final int kind;
  final bool rotated;
  _RayAnglePainter(this.kind, this.rotated);
  @override
  void paint(Canvas c, Size s) {
    final origin = Offset(s.width * .40, s.height / 2);
    final length = math.min(s.width * .5, s.height * .4);
    final base = rotated ? math.pi / 6 : 0.0;
    final extent = [math.pi / 4, math.pi / 2, 3 * math.pi / 4][kind];
    final pen = Paint()
      ..color = mathIndigo
      ..strokeWidth = 4;
    for (final a in [base, base - extent]) {
      final end = origin + Offset(math.cos(a), math.sin(a)) * length;
      c.drawLine(origin, end, pen);
      for (final delta in [-.45, .45]) {
        c.drawLine(
          end,
          end - Offset(math.cos(a + delta), math.sin(a + delta)) * 13,
          pen,
        );
      }
    }
    c.drawArc(
      Rect.fromCircle(center: origin, radius: 28),
      base - extent,
      extent,
      false,
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawCircle(origin, 5, Paint()..color = mathYellow);
  }

  @override
  bool shouldRepaint(_RayAnglePainter old) =>
      old.kind != kind || old.rotated != rotated;
}
