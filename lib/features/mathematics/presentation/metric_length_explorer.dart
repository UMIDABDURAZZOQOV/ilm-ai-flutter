part of 'math_models.dart';

String _metricLabel(int cm, {bool small = false}) =>
    '${cm ~/ 100} ${small ? 'dm' : 'm'} ${cm % 100 ~/ 10} ${small ? 'cm' : 'dm'} ${cm % 10} ${small ? 'mm' : 'cm'}';

class _MetricLengthExplorer extends StatefulWidget {
  final String mode;
  const _MetricLengthExplorer({required this.mode});
  @override
  State<_MetricLengthExplorer> createState() => _MetricLengthState();
}

class _MetricLengthState extends State<_MetricLengthExplorer> {
  int cm = 100, index = 0, step = 0;
  bool get small => widget.mode.startsWith('millimetre_');
  String get big => small ? 'dm' : 'm';
  String get middle => small ? 'cm' : 'dm';
  String get unit => small ? 'mm' : 'cm';
  String get bigName => small ? 'detsimetr' : 'metr';
  String get middleName => small ? 'santimetr' : 'detsimetr';
  String get unitName => small ? 'millimetr' : 'santimetr';
  String lengthLabel(int value) => _metricLabel(value, small: small);
  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset() {
    cm = {'metre_conversion', 'millimetre_conversion'}.contains(widget.mode)
        ? 100
        : 208;
    index = 0;
    step = 0;
  }

  @override
  void didUpdateWidget(_MetricLengthExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) reset();
  }

  @override
  Widget build(BuildContext context) {
    final operations = {
      'metre_length_operations',
      'millimetre_operations',
    }.contains(widget.mode);
    final samples = small
        ? [100, 341, 705, 901]
        : widget.mode == 'metre_conversion'
        ? [100, 300, 460, 700]
        : [127, 208, 280, 450, 608];
    final pair = [(276, 348, true), (632, 278, false), (346, 213, true)][index];
    final a = pair.$1,
        b = pair.$2,
        plus = pair.$3,
        total = plus ? a + b : a - b;
    int h = a ~/ 100, t = a ~/ 10 % 10, u = a % 10;
    final bh = b ~/ 100, bt = b ~/ 10 % 10, bu = b % 10;
    final notes = <String>[];
    if (plus) {
      final units = u + bu,
          carryT = units ~/ 10,
          tens = t + bt + carryT,
          carryH = tens ~/ 10;
      notes.add(
        '${small ? 'Millimetr' : 'Santimetr'}: $u + $bu = $units; ${units % 10} $unit qoladi, $carryT $middle o‘tadi.',
      );
      notes.add(
        '${small ? 'Santimetr' : 'Detsimetr'}: $t + $bt + $carryT = $tens; ${tens % 10} $middle qoladi, $carryH $big o‘tadi.',
      );
      notes.add(
        '${small ? 'Detsimetr' : 'Metr'}: $h + $bh + $carryH = ${h + bh + carryH}. Jami ${lengthLabel(total)}.',
      );
    } else {
      if (u < bu) {
        if (t == 0) {
          h--;
          t += 10;
        }
        t--;
        u += 10;
      }
      notes.add(
        '${small ? 'Millimetr' : 'Santimetr'}: $u − $bu = ${u - bu}; donor $middleName $t bo‘lib qoldi.',
      );
      if (t < bt) {
        h--;
        t += 10;
      }
      notes.add(
        '${small ? 'Santimetr' : 'Detsimetr'}: $t − $bt = ${t - bt}; donor $bigName $h bo‘lib qoldi.',
      );
      notes.add(
        '${small ? 'Detsimetr' : 'Metr'}: $h − $bh = ${h - bh}. Qolgan ${lengthLabel(total)}.',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              operations
                  ? 'Aralash uzunliklar bilan amallar'
                  : small
                  ? 'Detsimetr, santimetr, millimetr'
                  : 'Metr, detsimetr, santimetr',
            ),
            Text(
              '1 $big = 10 $middle = 100 $unit. Har $middle 10 $unit. Model ekran o‘lchovining fizik kalibrovkasi emas.',
            ),
            if (operations) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < 3; i++)
                    ChoiceChip(
                      key: ValueKey('metric-operation-$i'),
                      label: Text(
                        [
                          '276 $unit + 348 $unit',
                          '632 $unit − 278 $unit',
                          '346 $unit + 213 $unit',
                        ][i],
                      ),
                      selected: index == i,
                      onSelected: (_) => setState(() {
                        index = i;
                        step = 0;
                      }),
                    ),
                ],
              ),
              Text('Birinchi: ${lengthLabel(a)}; ikkinchi: ${lengthLabel(b)}.'),
              Semantics(
                liveRegion: true,
                child: Text(
                  notes[step],
                  key: const ValueKey('metric-operation-step'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: const ValueKey('metric-back'),
                    onPressed: step == 0 ? null : () => setState(() => step--),
                    child: const Text('Oldingi qadam'),
                  ),
                  FilledButton(
                    key: const ValueKey('metric-next'),
                    onPressed: step == 2 ? null : () => setState(() => step++),
                    child: const Text('Keyingi qadam'),
                  ),
                ],
              ),
              if (step == 2)
                Text(
                  '$a $unit ${plus ? '+' : '−'} $b $unit = $total $unit = ${lengthLabel(total)}',
                  key: const ValueKey('metric-operation-result'),
                ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in samples)
                    ChoiceChip(
                      key: ValueKey('metric-sample-$n'),
                      label: Text('$n $unit'),
                      selected: cm == n,
                      onSelected: (_) => setState(() => cm = n),
                    ),
                ],
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  '$cm $unit = ${lengthLabel(cm)}',
                  key: const ValueKey('metric-conversion'),
                ),
              ),
              Text(
                'To‘liq $bigName: ${cm ~/ 100}; to‘liq $middleName: ${cm ~/ 10}; $middleName xonasi: ${cm % 100 ~/ 10}.',
                key: const ValueKey('metric-groups'),
              ),
              Text(
                'Butun ${cm ~/ 100} $bigName alohida. Quyidagi chiziq faqat qolgan ${cm % 100} $unit ni 0–100 $unit ichida ko‘rsatadi.',
              ),
              Semantics(
                label:
                    'Qoldiq ${cm % 100} $unitName; modelning yuzta teng katagi, har o‘ntasi bir $middleName',
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 64,
                    child: CustomPaint(painter: _MetricStripPainter(cm % 100)),
                  ),
                ),
              ),
              Slider(
                key: const ValueKey('metric-cm-slider'),
                value: cm.toDouble(),
                min: 0,
                max: small ? 999 : 900,
                divisions: small ? 999 : 900,
                semanticFormatterCallback: (v) => '${v.round()} $unitName',
                onChanged: (v) => setState(() => cm = v.round()),
              ),
            ],
            const Text(
              'Birlikni yozmasdan sonlarni qo‘shmang: metr, santimetr va kilogramm boshqa-boshqa birlik. Mustaqil topshiriqni server tekshiradi; model XP bermaydi.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricStripPainter extends CustomPainter {
  final int cm;
  _MetricStripPainter(this.cm);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 100;
    for (int n = 0; n < 100; n++) {
      final rect = Rect.fromLTWH(n * w, 8, w, 40);
      canvas.drawRect(
        rect,
        Paint()..color = n < cm ? mathTurquoise : const Color(0xFFF3F1FA),
      );
      canvas.drawLine(
        Offset(n * w, 8),
        Offset(n * w, n % 10 == 0 ? 48 : 28),
        Paint()
          ..color = mathIndigo
          ..strokeWidth = n % 10 == 0 ? 1.5 : .4,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 8, size.width, 40),
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_MetricStripPainter old) => old.cm != cm;
}

class _MetricHeightChart extends StatefulWidget {
  const _MetricHeightChart();
  @override
  State<_MetricHeightChart> createState() => _MetricHeightState();
}

class _MetricHeightState extends State<_MetricHeightChart> {
  int selected = 0;
  static const values = [150, 135, 168, 122];
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Original sun’iy jadval: haqiqiy odamlar statistikasi emas',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < 4; i++)
                ChoiceChip(
                  key: ValueKey('metric-height-$i'),
                  label: Text('${['A', 'B', 'C', 'D'][i]}: ${values[i]} cm'),
                  selected: selected == i,
                  onSelected: (_) => setState(() => selected = i),
                ),
            ],
          ),
          Semantics(
            label:
                'Ustunlar noldan200cmgacha bir xil masshtabda. A150,B135,C168,D122santimetr',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 240,
                child: CustomPaint(painter: _MetricChartPainter(selected)),
              ),
            ),
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              'Tanlangan ${['A', 'B', 'C', 'D'][selected]}: ${values[selected]} cm',
              key: const ValueKey('metric-height-selected'),
            ),
          ),
          const Text(
            'Eng katta C:168 cm; eng kichik D:122 cm. C − A = 18 cm; B − D = 13 cm. Rangning o‘zi javob belgisi emas; nom va sonlarni o‘qing.',
          ),
        ],
      ),
    ),
  );
}

class _MetricChartPainter extends CustomPainter {
  final int selected;
  _MetricChartPainter(this.selected);
  @override
  void paint(Canvas c, Size s) {
    final h = s.height - 40, w = (s.width - 40) / 4;
    void label(String text, Offset at) {
      final p = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 12, color: mathIndigo),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(c, at);
    }

    for (int v = 0; v <= 200; v += 50) {
      final y = 12 + h - v / 200 * h;
      c.drawLine(
        Offset(32, y),
        Offset(s.width, y),
        Paint()..color = const Color(0xFFCBC7DC),
      );
      label('$v', Offset(0, y - 7));
    }
    for (int i = 0; i < 4; i++) {
      final value = _MetricHeightState.values[i], x = 38 + i * w;
      final top = 12 + h - value / 200 * h;
      c.drawRect(
        Rect.fromLTWH(x, top, w * .65, value / 200 * h),
        Paint()..color = i == selected ? mathIndigo : mathTurquoise,
      );
      label(['A', 'B', 'C', 'D'][i], Offset(x, 16 + h));
    }
  }

  @override
  bool shouldRepaint(_MetricChartPainter old) => old.selected != selected;
}
