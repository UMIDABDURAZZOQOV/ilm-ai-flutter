part of 'math_models.dart';

class _MetricPathExplorer extends StatefulWidget {
  const _MetricPathExplorer();
  @override
  State<_MetricPathExplorer> createState() => _MetricPathState();
}

class _MetricPathState extends State<_MetricPathExplorer> {
  int width = 30, height = 20;
  bool closed = false;
  @override
  Widget build(BuildContext context) {
    final total = width * 2 + height * (closed ? 2 : 1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Original siniq yo‘l va yopiq chegara'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('path-open'),
                  label: const Text('Ochiq'),
                  selected: !closed,
                  onSelected: (_) => setState(() => closed = false),
                ),
                ChoiceChip(
                  key: const ValueKey('path-closed'),
                  label: const Text('Yopiq'),
                  selected: closed,
                  onSelected: (_) => setState(() => closed = true),
                ),
              ],
            ),
            Semantics(
              label:
                  'A B C D ${closed ? 'Aga qaytadi' : 'ochiq'};AB$width,BC$height,CD$width${closed ? ',DA$height' : ''}millimetr',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: _MetricPathPainter(width, height, closed),
                  ),
                ),
              ),
            ),
            Text(
              closed ? '4 tomon, 4 uch.' : '3 bo‘g‘in, 4 belgilangan uch.',
              key: const ValueKey('metric-path-count'),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                '$width + $height + $width${closed ? ' + $height' : ''} = $total mm',
                key: const ValueKey('metric-path-total'),
              ),
            ),
            if (!closed)
              Text(
                'A–D to‘g‘ri kesma $height mm; belgilangan siniq yo‘l $total mm. Ular boshqa uzunliklar.',
              ),
            Text('AB va CD: $width mm'),
            Slider(
              key: const ValueKey('path-width'),
              value: width.toDouble(),
              min: 20,
              max: 50,
              divisions: 30,
              semanticFormatterCallback: (v) => '${v.round()} millimetr',
              onChanged: (v) => setState(() => width = v.round()),
            ),
            Text('BC${closed ? ' va DA' : ''}: $height mm'),
            Slider(
              key: const ValueKey('path-height'),
              value: height.toDouble(),
              min: 10,
              max: 30,
              divisions: 20,
              semanticFormatterCallback: (v) => '${v.round()} millimetr',
              onChanged: (v) => setState(() => height = v.round()),
            ),
            const Text(
              'Barcha kesmalar bitta matematik masshtabda chiziladi. Ekran fizik millimetr chizg‘ichi emas. Mustaqil javob va XP serverga tegishli.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPathPainter extends CustomPainter {
  final int width, height;
  final bool closed;
  _MetricPathPainter(this.width, this.height, this.closed);
  @override
  void paint(Canvas c, Size s) {
    final scale = math.min((s.width - 48) / width, (s.height - 48) / height);
    final x = (s.width - width * scale) / 2,
        y = (s.height - height * scale) / 2;
    final points = [
      Offset(x, y),
      Offset(x + width * scale, y),
      Offset(x + width * scale, y + height * scale),
      Offset(x, y + height * scale),
    ];
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (closed) path.close();
    c.drawPath(
      path,
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (int i = 0; i < 4; i++) {
      c.drawCircle(points[i], 4, Paint()..color = mathTurquoise);
      final t = TextPainter(
        text: TextSpan(
          text: ['A', 'B', 'C', 'D'][i],
          style: const TextStyle(fontSize: 14, color: mathIndigo),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(
        c,
        points[i] + Offset(i == 1 || i == 2 ? 7 : -18, i < 2 ? -18 : 4),
      );
    }
  }

  @override
  bool shouldRepaint(_MetricPathPainter old) =>
      old.width != width || old.height != height || old.closed != closed;
}

class _ThreeDigitOperationExplorer extends StatefulWidget {
  const _ThreeDigitOperationExplorer();
  @override
  State<_ThreeDigitOperationExplorer> createState() =>
      _ThreeDigitOperationState();
}

class _ThreeDigitOperationState extends State<_ThreeDigitOperationExplorer> {
  int value = 624, operation = 0;
  bool changedColour = false;
  @override
  Widget build(BuildContext context) {
    final h = value ~/ 100, t = value ~/ 10 % 10, u = value % 10;
    final reversed = value.toString().split('').reversed.join();
    final result = switch (operation) {
      0 => value + 100,
      1 => value - 80,
      2 => t * 100 + h * 10 + u,
      _ => int.parse(reversed),
    };
    final titles = [
      '100 ta oshirish',
      '80 ta kamaytirish',
      'Yuzlik va o‘nlikni almashtirish',
      'Raqamlarni teskari yozish',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('O‘zgarish qoidasini aniq tanlang'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < 4; i++)
                  ChoiceChip(
                    key: ValueKey('operation-$i'),
                    label: Text(titles[i]),
                    selected: operation == i,
                    onSelected: (_) => setState(() => operation = i),
                  ),
              ],
            ),
            Text('Kirish: $value'),
            Slider(
              key: const ValueKey('operation-input'),
              value: value.toDouble(),
              min: 100,
              max: 799,
              divisions: 699,
              semanticFormatterCallback: (v) => '${v.round()}',
              onChanged: (v) => setState(() => value = v.round()),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                '$value → $result',
                key: const ValueKey('operation-output'),
              ),
            ),
            if (operation == 3)
              Text(
                'Teskari raqam yozuvi: $reversed; oddiy son yozuvi: $result. Yetakchi nollar qiymatni oshirmaydi.',
              ),
            const Text('Rang o‘zgarishi sonli oshirish emas:'),
            Semantics(
              label: '1 doira; rangi${changedColour ? 'indigo' : 'turkuaz'}',
              child: ExcludeSemantics(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: changedColour ? mathIndigo : mathTurquoise,
                    ),
                  ),
                ),
              ),
            ),
            OutlinedButton(
              key: const ValueKey('operation-colour'),
              onPressed: () => setState(() => changedColour = !changedColour),
              child: const Text('Rangni almashtirish'),
            ),
            const Text(
              'Doiralar soni 1 bo‘lib qoladi. Faqat aytilgan qoida qo‘llanadi; mustaqil topshiriq serverda tekshiriladi.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketBranchExplorer extends StatefulWidget {
  const _BracketBranchExplorer();
  @override
  State<_BracketBranchExplorer> createState() => _BracketBranchState();
}

class _BracketBranchState extends State<_BracketBranchExplorer> {
  int sample = 0, step = 0;
  @override
  Widget build(BuildContext context) {
    final expressions = [
      '240 + 167 − (500 − 238)',
      '285 + 326 − 247',
      '850 − (436 + 218)',
    ];
    final left = [407, 611, 850][sample],
        right = [262, 247, 654][sample],
        result = left - right;
    final leftText = [
      '240 + 167 = 407',
      '285 + 326 = 611',
      'Butun son: 850',
    ][sample];
    final rightText = [
      '500 − 238 = 262',
      'Ayriladigan son: 247',
      '436 + 218 = 654',
    ][sample];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ifodaning ikki tarmog‘i'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < 3; i++)
                  ChoiceChip(
                    key: ValueKey('branch-sample-$i'),
                    label: Text(expressions[i]),
                    selected: sample == i,
                    onSelected: (_) => setState(() {
                      sample = i;
                      step = 0;
                    }),
                  ),
              ],
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                [leftText, rightText, '$left − $right = $result'][step],
                key: const ValueKey('branch-step'),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                InputChip(label: Text('Chap: ${step >= 0 ? left : '?'}')),
                InputChip(label: Text('O‘ng: ${step >= 1 ? right : '?'}')),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('branch-back'),
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  key: const ValueKey('branch-next'),
                  onPressed: step == 2 ? null : () => setState(() => step++),
                  child: const Text('Keyingi qadam'),
                ),
              ],
            ),
            if (step == 2)
              Text(
                '${expressions[sample]} = $result',
                key: const ValueKey('branch-result'),
              ),
            const Text(
              'Har tarmoq o‘z amalini saqlaydi. Qavsdagi ayirishni ikki sonni ketma-ket ayirish bilan almashtirmang. Bu tushuntirish modeli; mustaqil javob va XP serverda.',
            ),
          ],
        ),
      ),
    );
  }
}
