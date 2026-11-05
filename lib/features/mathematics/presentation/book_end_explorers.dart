part of 'math_models.dart';

class _NumberRemoveSumExplorer extends StatefulWidget {
  const _NumberRemoveSumExplorer();
  @override
  State<_NumberRemoveSumExplorer> createState() =>
      _NumberRemoveSumExplorerState();
}

class _NumberRemoveSumExplorerState extends State<_NumberRemoveSumExplorer> {
  int sample = 0, route = 0, step = 0;
  static const samples = [(72, 18, 27), (83, 24, 29), (68, 17, 26)];
  @override
  Widget build(BuildContext context) {
    final (a, b, c) = samples[sample];
    final result = a - b - c;
    final paths = [
      ['$a − ($b + $c)', '$a − ${b + c}', '$result'],
      ['$a − $b − $c', '${a - b} − $c', '$result'],
      ['$a − $c − $b', '${a - c} − $b', '$result'],
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Butundan ikkala qismni olamiz'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < samples.length; i++)
                  ChoiceChip(
                    label: Text(
                      '${samples[i].$1} − (${samples[i].$2} + ${samples[i].$3})',
                    ),
                    selected: sample == i,
                    onSelected: (_) => setState(() {
                      sample = i;
                      route = step = 0;
                    }),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    key: ValueKey('remove-sum-route-$i'),
                    label: Text(['Jamini ol', 'Avval $b', 'Avval $c'][i]),
                    selected: route == i,
                    onSelected: (_) => setState(() {
                      route = i;
                      step = 0;
                    }),
                  ),
              ],
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                paths[route][step],
                key: const ValueKey('remove-sum-expression'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Qadam: ${step + 1} / 3',
              key: const ValueKey('remove-sum-step'),
            ),
            Text(
              step == 0
                  ? 'Olinadigan qismlar $b va $c. Ular birgalikda $a dan oshmaydi.'
                  : step == 1
                  ? 'Har ikkala qism aynan bir martadan ayriladi; yo‘lni o‘zgartirish qo‘shishni anglatmaydi.'
                  : 'Qoldiq $result. Tekshiruv: $result + $b + $c = $a.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('remove-sum-back'),
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  key: const ValueKey('remove-sum-next'),
                  onPressed: step == 2 ? null : () => setState(() => step++),
                  child: const Text('Keyingi qadam'),
                ),
              ],
            ),
            const Text(
              'Bu o‘quv modeli. Mustaqil savol serverda tekshiriladi.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowPartitionExplorer extends StatefulWidget {
  const _ArrowPartitionExplorer();
  @override
  State<_ArrowPartitionExplorer> createState() =>
      _ArrowPartitionExplorerState();
}

class _ArrowPartitionExplorerState extends State<_ArrowPartitionExplorer> {
  bool vertical = false, horizontal = false;
  @override
  Widget build(BuildContext context) {
    final count = vertical ? (horizontal ? 3 : 1) : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ikki chiziq bilan shakllarni ajrat'),
            const Text(
              'Kichik shakllar bilan birga ularni birlashtirgan butun shakllar ham sanaladi.',
            ),
            SwitchListTile(
              key: const ValueKey('arrow-vertical'),
              title: const Text('Tik chiziq'),
              value: vertical,
              onChanged: (v) => setState(() => vertical = v),
            ),
            SwitchListTile(
              key: const ValueKey('arrow-horizontal'),
              title: const Text('Yotiq chiziq'),
              value: horizontal,
              onChanged: (v) => setState(() => horizontal = v),
            ),
            Semantics(
              label:
                  'Original chapga qaragan strelka; tik chiziq ${vertical ? 'yoqilgan' : 'o‘chiq'}, yotiq chiziq ${horizontal ? 'yoqilgan' : 'o‘chiq'}.',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: _ArrowPartitionPainter(vertical, horizontal),
                  ),
                ),
              ),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                'Uchburchaklar: $count; to‘g‘ri to‘rtburchaklar: $count',
                key: const ValueKey('arrow-counts'),
              ),
            ),
            if (vertical && horizontal)
              const Text(
                'Ikki kichik uchburchak + bitta katta = 3. Ikki kichik to‘rtburchak + bitta katta = 3.',
              ),
            const Text(
              'Bu aniq berilgan original model. Boshqa chiziqlarni qo‘lda chizish alohida ko‘rikni talab qiladi.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowPartitionPainter extends CustomPainter {
  final bool vertical, horizontal;
  _ArrowPartitionPainter(this.vertical, this.horizontal);
  @override
  void paint(Canvas c, Size s) {
    Offset p(double x, double y) => Offset(x * s.width, y * s.height);
    final path = Path()
      ..moveTo(.06 * s.width, .5 * s.height)
      ..lineTo(.4 * s.width, .08 * s.height)
      ..lineTo(.4 * s.width, .3 * s.height)
      ..lineTo(.95 * s.width, .3 * s.height)
      ..lineTo(.95 * s.width, .7 * s.height)
      ..lineTo(.4 * s.width, .7 * s.height)
      ..lineTo(.4 * s.width, .92 * s.height)
      ..close();
    c.drawPath(path, Paint()..color = mathTurquoise.withValues(alpha: .25));
    final border = Paint()
      ..color = mathIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawPath(path, border);
    if (vertical) c.drawLine(p(.4, .08), p(.4, .92), border);
    if (horizontal) c.drawLine(p(.06, .5), p(.95, .5), border);
  }

  @override
  bool shouldRepaint(_ArrowPartitionPainter old) =>
      old.vertical != vertical || old.horizontal != horizontal;
}

class _RegionColourExplorer extends StatefulWidget {
  const _RegionColourExplorer();
  @override
  State<_RegionColourExplorer> createState() => _RegionColourExplorerState();
}

class _RegionColourExplorerState extends State<_RegionColourExplorer> {
  int selected = 0;
  List<int?> colours = [null, null, null, null];
  static const labels = ['A', 'B', 'C', 'D'];
  static const edges = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)];
  @override
  Widget build(BuildContext context) {
    final conflicts = edges
        .where((e) => colours[e.$1] != null && colours[e.$1] == colours[e.$2])
        .map((e) => '${labels[e.$1]}–${labels[e.$2]}')
        .toList();
    final names = ['indigo', 'sariq', 'firuza'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Qo‘shni hududlarni turli rangla'),
            const Text(
              'Qo‘shni juftlar: A–B, A–C, B–C, B–D, C–D. Bir nechta to‘g‘ri ranglash bor.',
            ),
            Semantics(
              label: [
                for (var i = 0; i < 4; i++)
                  '${labels[i]}: ${colours[i] == null ? 'ranglanmagan' : names[colours[i]!]}',
              ].join('; '),
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 160,
                  child: CustomPaint(
                    painter: _RegionColourPainter(List.of(colours)),
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 4; i++)
                  ChoiceChip(
                    key: ValueKey('region-$i'),
                    label: Text(labels[i]),
                    selected: selected == i,
                    onSelected: (_) => setState(() => selected = i),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    key: ValueKey('region-colour-$i'),
                    label: Text(names[i]),
                    selected: colours[selected] == i,
                    onSelected: (_) => setState(() => colours[selected] = i),
                  ),
              ],
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                conflicts.isNotEmpty
                    ? 'Bir xil rangli qo‘shnilar: ${conflicts.join(', ')}'
                    : colours.any((v) => v == null)
                    ? 'Barcha hududlar hali ranglanmagan.'
                    : 'Barcha qo‘shni juftlar turli rangda.',
                key: const ValueKey('region-feedback'),
              ),
            ),
            TextButton(
              key: const ValueKey('region-reset'),
              onPressed: () => setState(() {
                colours = [null, null, null, null];
                selected = 0;
              }),
              child: const Text('Ranglarni tozalash'),
            ),
            const Text(
              'Bu o‘quv modeli; undagi ranglash XP yoki mustaqil topshiriq bahosi emas.',
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionColourPainter extends CustomPainter {
  final List<int?> values;
  _RegionColourPainter(this.values);
  @override
  void paint(Canvas c, Size s) {
    final rects = [
      Rect.fromLTWH(0, 0, s.width * .5, s.height * .5),
      Rect.fromLTWH(s.width * .5, 0, s.width * .5, s.height * .75),
      Rect.fromLTWH(0, s.height * .5, s.width * .5, s.height * .5),
      Rect.fromLTWH(s.width * .5, s.height * .75, s.width * .5, s.height * .25),
    ];
    final palette = [mathIndigo, mathYellow, mathTurquoise];
    for (var i = 0; i < 4; i++) {
      c.drawRect(
        rects[i],
        Paint()
          ..color = values[i] == null
              ? const Color(0xFFF1F3F5)
              : palette[values[i]!],
      );
      c.drawRect(
        rects[i],
        Paint()
          ..color = mathIndigo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final text = TextPainter(
        text: TextSpan(
          text: ['A', 'B', 'C', 'D'][i],
          style: TextStyle(
            color: values[i] == 0 ? Colors.white : mathIndigo,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(c, rects[i].center - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RegionColourPainter old) =>
      List.generate(4, (i) => old.values[i] != values[i]).any((v) => v);
}

class _VennSectorExplorer extends StatefulWidget {
  const _VennSectorExplorer();
  @override
  State<_VennSectorExplorer> createState() => _VennSectorExplorerState();
}

class _VennSectorExplorerState extends State<_VennSectorExplorer> {
  List<int> counts = [3, 4, 2];
  @override
  Widget build(BuildContext context) {
    final a = counts[0], both = counts[1], b = counts[2];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Uch alohida sektorni bir martadan sana'),
            for (var i = 0; i < 3; i++) ...[
              Text('${['Faqat A', 'Ikkalasi', 'Faqat B'][i]}: ${counts[i]}'),
              Slider(
                key: ValueKey('venn-sector-$i'),
                value: counts[i].toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                semanticFormatterCallback: (v) =>
                    '${['Faqat A', 'Ikkalasi', 'Faqat B'][i]} ${v.round()}',
                onChanged: (v) => setState(() => counts[i] = v.round()),
              ),
            ],
            Semantics(
              label: 'Faqat A $a, ikkala doirada $both, faqat B $b',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 150,
                  child: CustomPaint(
                    painter: _VennSectorPainter(List.of(counts)),
                  ),
                ),
              ),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                'A jami: ${a + both}; B jami: ${b + both}; kamida bittasida: ${a + both + b}',
                key: const ValueKey('venn-totals'),
              ),
            ),
            Text(
              'Doiralar jami ${a + both + both + b}. Unda umumiy $both sektor ikki marta qatnashadi. Birlashmada esa bir marta.',
            ),
          ],
        ),
      ),
    );
  }
}

class _VennSectorPainter extends CustomPainter {
  final List<int> counts;
  _VennSectorPainter(this.counts);
  @override
  void paint(Canvas c, Size s) {
    final left = Rect.fromLTWH(.03 * s.width, 5, .62 * s.width, s.height - 10),
        right = Rect.fromLTWH(.35 * s.width, 5, .62 * s.width, s.height - 10);
    c.drawOval(left, Paint()..color = mathTurquoise.withValues(alpha: .25));
    c.drawOval(right, Paint()..color = mathYellow.withValues(alpha: .25));
    final border = Paint()
      ..color = mathIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawOval(left, border);
    c.drawOval(right, border);
    for (var i = 0; i < 3; i++) {
      final t = TextPainter(
        text: TextSpan(
          text: '${counts[i]}',
          style: const TextStyle(
            color: mathIndigo,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(
        c,
        Offset(
          ([.22, .5, .78][i]) * s.width - t.width / 2,
          s.height * .5 - t.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_VennSectorPainter old) =>
      List.generate(3, (i) => old.counts[i] != counts[i]).any((v) => v);
}
