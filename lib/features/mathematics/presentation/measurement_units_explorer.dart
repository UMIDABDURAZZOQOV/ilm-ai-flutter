part of 'math_models.dart';

class _MeasurementUnitsExplorer extends StatefulWidget {
  final String mode;
  const _MeasurementUnitsExplorer({required this.mode});
  @override
  State<_MeasurementUnitsExplorer> createState() =>
      _MeasurementUnitsExplorerState();
}

class _MeasurementUnitsExplorerState extends State<_MeasurementUnitsExplorer> {
  int length = 7, centimetres = 14, width = 6, addedMass = 5;
  @override
  void initState() {
    super.initState();
    if (widget.mode == 'measurement_dm_cm_conversion') centimetres = 27;
  }

  @override
  void didUpdateWidget(_MeasurementUnitsExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      length = 7;
      centimetres = widget.mode == 'measurement_dm_cm_conversion' ? 27 : 14;
      width = 6;
      addedMass = 5;
    }
  }

  Widget result(String s, String key) => Semantics(
    liveRegion: true,
    child: Text(
      s,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (widget.mode == 'measurement_segments') {
      children.addAll([
        const Text('ABvaCD — ikki uchi belgilangan to‘g‘ri kesmalar'),
        Slider(
          key: const ValueKey('units-segment-length'),
          value: length.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          semanticFormatterCallback: (v) => 'AB ${v.round()}cm',
          onChanged: (v) => setState(() => length = v.round()),
        ),
        Text('A:0 cm; B:$length cm. AB:$length cm.'),
        Semantics(
          label: 'ABkesma, uzunlik$length santimetr',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 95,
              child: CustomPaint(
                painter: _ElementaryRulerPainter(
                  length,
                  MediaQuery.textScalerOf(context).scale(10),
                ),
              ),
            ),
          ),
        ),
        const Text('CD:5 cm. Bir xil birlikda solishtir.'),
        result(
          '${math.max(length, 5)} − ${math.min(length, 5)} = ${(length - 5).abs()}cm',
          'units-segment-gap',
        ),
        Text(
          length == 5
              ? 'ABvaCDteng.'
              : '${length > 5 ? 'AB' : 'CD'} kesma uzunroq.',
        ),
        const Text(
          'Nom ABdan BAga o‘zgarsa ham, ayni kesmaning uzunligi saqlanadi.',
        ),
      ]);
    } else if (widget.mode == 'measurement_decimetre_intro' ||
        widget.mode == 'measurement_dm_cm_conversion') {
      final full = centimetres ~/ 10, rest = centimetres % 10;
      final max = widget.mode == 'measurement_decimetre_intro' ? 29 : 99;
      children.addAll([
        const Text(
          '1 dm = 10 cm. Birlikni o‘zgartirsak ham uzunlik saqlanadi.',
        ),
        Slider(
          key: const ValueKey('units-centimetres'),
          value: centimetres.toDouble(),
          min: 0,
          max: max.toDouble(),
          divisions: max,
          semanticFormatterCallback: (v) => '${v.round()}cm',
          onChanged: (v) => setState(() => centimetres = v.round()),
        ),
        result('$centimetres cm = $full dm $rest cm', 'units-conversion'),
        Text('$centimetres cm = ${full * 10}cm + $rest cm'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < full; i++)
              Chip(label: Text('${i + 1}-guruh:1 dm=10 cm')),
            for (var i = 0; i < rest; i++)
              Chip(label: Text('${i + 1}-qoldiq:1 cm')),
          ],
        ),
        Text('To‘liq dm:$full; qolgan cm:$rest. Qolgan qism 0–9 cmoralig‘ida.'),
        const Text(
          'Bu sonli birlik modeli; telefon ekranini fizik chizg‘ich deb o‘lchamaymiz.',
        ),
      ]);
    } else if (widget.mode == 'measurement_rectangles') {
      children.addAll([
        const Text(
          'Original modellar: birinchining bo‘yi 3 cm, eni o‘zgaradi. Ikkinchisining eni va bo‘yi 3 cm.',
        ),
        Slider(
          key: const ValueKey('units-rectangle-width'),
          value: width.toDouble(),
          min: 2,
          max: 8,
          divisions: 6,
          semanticFormatterCallback: (v) => 'Birinchi en ${v.round()}cm',
          onChanged: (v) => setState(() => width = v.round()),
        ),
        Semantics(
          label: 'Birinchi to‘rtburchak$width ga 3 cm; ikkinchi 3 ga 3 cm',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 210,
              child: CustomPaint(painter: _LengthRectanglesPainter(width)),
            ),
          ),
        ),
        result(
          'Birinchi: eni $width cm, bo‘yi 3 cm; ikkinchi: eni 3 cm, bo‘yi 3 cm',
          'units-rectangle-result',
        ),
        Text(
          width == 3
              ? 'Hozir ikkala model ham 3 cmli kvadrat.'
              : 'Birinchi modelning ikki turli yon uzunligi bor; ikkinchining barcha tomoni 3 cm.',
        ),
      ]);
    } else {
      final left = 3 + addedMass;
      children.addAll([
        const Text(
          'Chapda 3 kgbor. Yana belgilangan massali tosh qo‘sh; o‘ngda 11 kg.',
        ),
        Slider(
          key: const ValueKey('units-added-mass'),
          value: addedMass.toDouble(),
          min: 0,
          max: 12,
          divisions: 12,
          semanticFormatterCallback: (v) => 'Qo‘shilgan tosh ${v.round()}kg',
          onChanged: (v) => setState(() => addedMass = v.round()),
        ),
        Semantics(
          label:
              'Chap$left kg, o‘ng 11 kg; ${left == 11
                  ? 'teng'
                  : left > 11
                  ? 'chap og‘irroq'
                  : 'o‘ng og‘irroq'}',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 125,
              child: CustomPaint(
                painter: _MassBalancePainter(left.compareTo(11)),
              ),
            ),
          ),
        ),
        result(
          'Chap:3 + $addedMass = $left kg; o‘ng:11 kg',
          'units-balance-result',
        ),
        Text(
          left == 11
              ? 'Massalar teng. Qo‘shilgan tosh 8 kg.'
              : left > 11
              ? 'Chap tomon og‘irroq.'
              : 'O‘ng tomon og‘irroq.',
        ),
        const Text(
          'Slayder modeldagi qo‘shiladigan tosh massasini tanlaydi. Noma’lum jism haqidagi taxmin uning massasini o‘zgartirmaydi.',
        ),
      ]);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in children)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
          ],
        ),
      ),
    );
  }
}

class _LengthRectanglesPainter extends CustomPainter {
  final int width;
  const _LengthRectanglesPainter(this.width);
  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min((size.width - 24) / 8, 30.0);
    final ink = Paint()
      ..color = mathIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final rect in [
      Rect.fromLTWH(12, 4, width * unit, 3 * unit),
      Rect.fromLTWH(12, 110, 3 * unit, 3 * unit),
    ]) {
      canvas.drawRect(rect, Paint()..color = mathYellow.withValues(alpha: .35));
      canvas.drawRect(rect, ink);
    }
  }

  @override
  bool shouldRepaint(_LengthRectanglesPainter old) => old.width != width;
}

class _MassBalancePainter extends CustomPainter {
  final int relation;
  const _MassBalancePainter(this.relation);
  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final left = Offset(size.width * .12, 45 + relation * 12.0),
        right = Offset(size.width * .88, 45 - relation * 12.0);
    final ink = Paint()
      ..color = mathIndigo
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(x, 45)
        ..lineTo(x - 18, 90)
        ..lineTo(x + 18, 90)
        ..close(),
      Paint()..color = mathTurquoise,
    );
    canvas.drawLine(left, right, ink);
    for (final p in [left, right]) {
      canvas.drawLine(p, p.translate(0, 33), ink);
      canvas.drawLine(p.translate(-20, 33), p.translate(20, 33), ink);
      canvas.drawCircle(p.translate(0, 24), 7, Paint()..color = mathYellow);
    }
  }

  @override
  bool shouldRepaint(_MassBalancePainter old) => old.relation != relation;
}
