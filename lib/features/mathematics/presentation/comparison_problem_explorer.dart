part of 'math_models.dart';

/// Original source-specific worked models. All assessment remains server-side.
class _ComparisonProblemExplorer extends StatefulWidget {
  final String mode;
  const _ComparisonProblemExplorer({required this.mode});
  @override
  State<_ComparisonProblemExplorer> createState() =>
      _ComparisonProblemExplorerState();
}

class _ComparisonProblemExplorerState
    extends State<_ComparisonProblemExplorer> {
  int selected = 0, difference = 14, first = 9, change = 3, step = 0;
  bool more = true;
  final seen = <int>{};
  @override
  void didUpdateWidget(_ComparisonProblemExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      selected = 0;
      difference = 14;
      first = 9;
      change = 3;
      step = 0;
      more = true;
      seen.clear();
    }
  }

  Widget choices(List<String> labels) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < labels.length; i++)
        ChoiceChip(
          label: Text(labels[i]),
          selected: selected == i,
          onSelected: (_) => setState(() => selected = i),
        ),
    ],
  );
  Widget announce(String text, String key) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (widget.mode == 'problem_route_times') {
      const left = [6, 4, 5], right = [8, 7, 9], names = ['A', 'B', 'C'];
      children.addAll([
        const Text('Bir boshlanish va bir manzil; barcha bo‘laklar minutda'),
        choices(['A yo‘l', 'B yo‘l', 'C yo‘l']),
        Text(
          '${names[selected]}: boshidan oraliq joygacha ${left[selected]} minut, oraliq joydan manzilgacha ${right[selected]} minut.',
        ),
        FilledButton(
          onPressed: () => setState(() => seen.add(selected)),
          child: const Text('Yo‘l vaqtini ochish'),
        ),
        if (seen.contains(selected))
          announce(
            '${left[selected]} + ${right[selected]} = ${left[selected] + right[selected]} minut',
            'comparison-route-time',
          ),
        Text('Tekshirilgan yo‘llar: ${seen.length} / 3'),
        if (seen.length == 3)
          const Text(
            'A —14, B —11, C —14 minut. Berilgan vaqtlarda B tezroq; A va C teng.',
          ),
        const Text(
          'Bu vaqtlarni taqqoslash. Ekrandagi chiziqdan kilometr o‘lchanmaydi.',
        ),
      ]);
    } else if (widget.mode == 'comparison_more_less') {
      final result = more ? 24 + change : 24 - change;
      children.addAll([
        const Text('Asos 24 ta belgi. Qancha ko‘p yoki kam?'),
        Text('Farq: $change ta'),
        Slider(
          key: const ValueKey('comparison-change'),
          min: 0,
          max: 9,
          divisions: 9,
          value: change.toDouble(),
          semanticFormatterCallback: (v) => 'Farq ${v.round()} ta',
          onChanged: (v) => setState(() => change = v.round()),
        ),
        SwitchListTile(
          title: Text(more ? 'Asosdan ko‘p' : 'Asosdan kam'),
          value: more,
          onChanged: (v) => setState(() => more = v),
        ),
        announce(
          '24 ${more ? '+' : '−'} $change = $result',
          'comparison-more-less-result',
        ),
        Text(
          'So‘ralgan guruh $result ta. Ikkala guruhning jami ${24 + result} ta —bu boshqa savol.',
        ),
        Semantics(
          label: 'Asos 24, taqqoslanayotgan guruh$result',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 60,
              child: CustomPaint(painter: _ComparisonBarsPainter(24, result)),
            ),
          ),
        ),
      ]);
    } else if (widget.mode == 'comparison_partitions') {
      final second = 16 - first,
          sign = first > second
              ? '>'
              : first < second
              ? '<'
              : '=';
      children.addAll([
        const Text('Jami 16. Birinchi quti ikkinchidan ko‘proq bo‘lsin.'),
        Slider(
          key: const ValueKey('comparison-first-part'),
          value: first.toDouble(),
          min: 1,
          max: 15,
          divisions: 14,
          semanticFormatterCallback: (v) =>
              'Birinchi ${v.round()}, ikkinchi ${16 - v.round()}',
          onChanged: (v) => setState(() => first = v.round()),
        ),
        announce(
          '$first + $second = 16; $first $sign $second',
          'comparison-partition-result',
        ),
        Text(
          first > second
              ? 'Ikkala shartga mos juftlik.'
              : 'Jami mos, lekin birinchi quti ko‘proq degan shart bajarilmadi.',
        ),
        Semantics(
          label: 'Jami 16; birinchi$first, ikkinchi$second',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 32,
              child: CustomPaint(painter: _ProblemBarPainter(first / 16)),
            ),
          ),
        ),
        const Text(
          'Boshqa mos juftlikni ham top. Bu shartning bitta yagona sonli yechimi yo‘q.',
        ),
      ]);
    } else if (widget.mode == 'comparison_independent_branches') {
      const changes = [10, 20, -40, 30, -10, 40];
      final value = changes[selected];
      children.addAll([
        const Text('Har tarmoqning boshlanishi 50; tarmoqlar mustaqil'),
        choices([
          for (final c in changes) '${c > 0 ? '+' : '−'}${c.abs()} tarmoq',
        ]),
        announce(
          '50 ${value > 0 ? '+' : '−'} ${value.abs()} = ${50 + value}',
          'comparison-branch-result',
        ),
        const Text(
          'Boshqa tarmoqqa o‘tishda yana 50 dan boshlaymiz. Oldingi natijani davom ettirmaymiz.',
        ),
      ]);
    } else {
      const small = 23;
      final large = small + difference;
      final equations = [
        '$small + $difference = $large',
        '$difference + $small = $large',
        '$large − $small = $difference',
        '$large − $difference = $small',
      ];
      children.addAll([
        Text('Kichik$small ta, katta$large ta, farq$difference ta'),
        Slider(
          key: const ValueKey('comparison-difference'),
          min: 0,
          max: 25,
          divisions: 25,
          value: difference.toDouble(),
          semanticFormatterCallback: (v) => 'Farq ${v.round()} ta',
          onChanged: (v) => setState(() {
            difference = v.round();
            step = 0;
          }),
        ),
        Semantics(
          label: 'Kichik$small; katta$large; farq$difference',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 60,
              child: CustomPaint(painter: _ComparisonBarsPainter(small, large)),
            ),
          ),
        ),
        announce(equations[step], 'comparison-difference-equation'),
        Text(
          const [
            'Kichik va farqdan katta.',
            'Qo‘shiluvchilar o‘rni almashdi.',
            'Kattadan kichikni olsak, farq qoladi.',
            'Kattadan farqni olsak, kichik qoladi.',
          ][step],
        ),
        FilledButton(
          onPressed: step < 3 ? () => setState(() => step++) : null,
          child: const Text('Keyingi bog‘lanish'),
        ),
        OutlinedButton(
          onPressed: step == 0 ? null : () => setState(() => step = 0),
          child: const Text('Boshidan ko‘rish'),
        ),
      ]);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
          ],
        ),
      ),
    );
  }
}

class _ComparisonBarsPainter extends CustomPainter {
  final int first, second;
  const _ComparisonBarsPainter(this.first, this.second);
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / math.max(first, second);
    for (var i = 0; i < 2; i++) {
      final n = i == 0 ? first : second;
      final rect = Rect.fromLTWH(0, i * 32, scale * n, 24);
      canvas.drawRect(
        rect,
        Paint()..color = i == 0 ? mathTurquoise : mathYellow,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = mathIndigo
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_ComparisonBarsPainter old) =>
      old.first != first || old.second != second;
}
