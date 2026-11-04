part of 'math_models.dart';

class _ComparisonApplicationExplorer extends StatefulWidget {
  final String mode;
  const _ComparisonApplicationExplorer({required this.mode});
  @override
  State<_ComparisonApplicationExplorer> createState() =>
      _ComparisonApplicationExplorerState();
}

class _ComparisonApplicationExplorerState
    extends State<_ComparisonApplicationExplorer> {
  int first = 11,
      second = 15,
      left = 0,
      right = 1,
      selected = 0,
      base = 6,
      step = 0,
      circles = 3,
      squares = 4;
  final seen = <int>{};
  @override
  void didUpdateWidget(_ComparisonApplicationExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      first = 11;
      second = 15;
      left = 0;
      right = 1;
      selected = 0;
      base = 6;
      step = 0;
      circles = 3;
      squares = 4;
      seen.clear();
    }
  }

  Widget result(String text, String key) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  Widget choices(List<String> labels) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < labels.length; i++)
        ChoiceChip(
          label: Text(labels[i]),
          selected: selected == i,
          onSelected: (_) => setState(() {
            selected = i;
            step = 0;
          }),
        ),
    ],
  );
  Widget objects(String shape, int n) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < n; i++)
        Semantics(
          label: '${i + 1}-belgi, $shape',
          child: ExcludeSemantics(
            child: SizedBox.square(
              dimension: 24,
              child: CustomPaint(
                painter: MathShapePainter(shape, mathTurquoise),
              ),
            ),
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (widget.mode == 'comparison_count_gap') {
      children.add(const Text('Bir xil birlikdagi ikki guruhni solishtir'));
      for (var i = 0; i < 2; i++) {
        final n = i == 0 ? first : second;
        children.add(Text('${i == 0 ? 'A' : 'B'}: $n ta rasm'));
        children.add(
          Slider(
            key: ValueKey('application-count-$i'),
            min: 0,
            max: 20,
            divisions: 20,
            value: n.toDouble(),
            semanticFormatterCallback: (v) =>
                '${i == 0 ? 'A' : 'B'}: ${v.round()} ta',
            onChanged: (v) => setState(() {
              if (i == 0) {
                first = v.round();
              } else {
                second = v.round();
              }
            }),
          ),
        );
      }
      final large = math.max(first, second), small = math.min(first, second);
      children.addAll([
        Semantics(
          label: 'A$first ta, B$second ta',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 60,
              child: CustomPaint(
                painter: _ComparisonBarsPainter(first, second),
              ),
            ),
          ),
        ),
        result('$large − $small = ${large - small}', 'application-count-gap'),
        Text(
          first == second
              ? 'Guruhlar teng, farq 0.'
              : '${first > second ? 'A' : 'B'}da ${large - small} ta ko‘p; boshqa guruhda shuncha kam.',
        ),
      ]);
    } else if (widget.mode == 'comparison_dataset') {
      const values = [28, 15, 0, 0], names = ['A', 'B', 'C', 'D'];
      children.add(
        const Text('Original maketlar jadvali: A 28, B 15, C 0, D 0'),
      );
      for (var i = 0; i < 2; i++) {
        children.add(Text(i == 0 ? 'Birinchi ustun' : 'Ikkinchi ustun'));
        children.add(
          DropdownButton<int>(
            key: ValueKey('application-column-$i'),
            value: i == 0 ? left : right,
            isExpanded: true,
            items: [
              for (var j = 0; j < 4; j++)
                DropdownMenuItem(
                  value: j,
                  child: Text('${names[j]}: ${values[j]} ta'),
                ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  if (i == 0) {
                    left = v;
                  } else {
                    right = v;
                  }
                });
              }
            },
          ),
        );
      }
      final a = values[left], b = values[right];
      children.addAll([
        result(
          '${math.max(a, b)} − ${math.min(a, b)} = ${(a - b).abs()}',
          'application-table-gap',
        ),
        Text(
          a == b
              ? 'Tanlangan ikki ustun teng.'
              : '${a > b ? names[left] : names[right]} ustunida ${(a - b).abs()} ta ko‘p.',
        ),
        const Text(
          'C va D ikkalasi nol. Kattaroq chizilgan belgi sonni o‘zgartirmaydi.',
        ),
      ]);
    } else if (widget.mode == 'comparison_picture_counts') {
      const values = [7, 9, 7];
      children.addAll([
        const Text('Original yulduz shaklidagi sanash kartalari'),
        choices(['A karta', 'B karta', 'C karta']),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < values[selected]; i++)
              Semantics(
                label: '${i + 1}-yulduz belgisi',
                child: const ExcludeSemantics(
                  child: Icon(Icons.star, color: mathIndigo, size: 28),
                ),
              ),
          ],
        ),
        FilledButton(
          onPressed: () => setState(() => seen.add(selected)),
          child: const Text('Sanoqni tekshirish'),
        ),
        if (seen.contains(selected))
          result(
            '${const ['A', 'B', 'C'][selected]}: ${values[selected]} ta belgi',
            'application-picture-count',
          ),
        if (seen.length == 3)
          const Text('B da 9 ta, A va C da 7 tadan. B 2 ta ko‘p; A va C teng.'),
        const Text('Har belgi bir marta sanalsin.'),
      ]);
    } else if (widget.mode == 'comparison_same_symbol') {
      children.addAll([
        const Text('Ikkala katak ham aynan bir xil sonni bildiradi'),
        Text('□ = $base'),
        Slider(
          key: const ValueKey('application-shared-value'),
          min: 0,
          max: 20,
          divisions: 20,
          value: base.toDouble(),
          semanticFormatterCallback: (v) => 'Ikkala katak ${v.round()}',
          onChanged: (v) => setState(() => base = v.round()),
        ),
        choices(['Ko‘proq', 'Teng']),
        result(
          selected == 0 ? '$base + 2 < $base + 4' : '$base + 10 = 10 + $base',
          'application-symbol-expression',
        ),
        Text(
          selected == 0
              ? '${base + 2} < ${base + 4}; farq 2.'
              : '${base + 10} = ${10 + base}; qo‘shiluvchilar almashdi.',
        ),
      ]);
    } else {
      const paths = [
        ['5 + 2 + 6', '7 + 6', '13'],
        ['24 − 21 = ?', '24 − 21 = 3', '13 − 3 = 10'],
        ['(24 + 13) − 12', '37 − 12', '25'],
      ];
      children.add(choices(['Uch qism', 'Bir xil farq', 'Qavs', 'Shakllar']));
      if (selected < 3) {
        children.addAll([
          result(paths[selected][step], 'application-compound-step'),
          if (selected == 1)
            const Text(
              '21 soni 24 dan qancha kam bo‘lsa,13 dan shuncha kam son topilsin.',
            ),
          FilledButton(
            onPressed: step < 2 ? () => setState(() => step++) : null,
            child: const Text('Keyingi qadam'),
          ),
          OutlinedButton(
            onPressed: step == 0 ? null : () => setState(() => step = 0),
            child: const Text('Boshidan ko‘rish'),
          ),
        ]);
      } else {
        children.addAll([
          const Text(
            'Uchburchak 6 ta. Doira undan 1 ta kam; kvadrat doiradan 2 ta ko‘p bo‘lsin.',
          ),
          const Text('Uchburchak 6 ta'),
          objects('triangle', 6),
          Text('Doira $circles ta'),
          objects('circle', circles),
          Text('Kvadrat $squares ta'),
          objects('square', squares),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: circles < 6 ? () => setState(() => circles++) : null,
                child: const Text('Doira qo‘shish'),
              ),
              FilledButton(
                onPressed: squares < 8 ? () => setState(() => squares++) : null,
                child: const Text('Kvadrat qo‘shish'),
              ),
              OutlinedButton(
                onPressed: () => setState(() {
                  circles = 3;
                  squares = 4;
                }),
                child: const Text('Qaytadan'),
              ),
            ],
          ),
          result(
            circles == 5 && squares == 7
                ? 'Ikkala bog‘lanish bajarildi.'
                : 'Ikkala bog‘lanishni tekshir.',
            'application-shape-check',
          ),
          Text(
            'Doira + 1 = ${circles + 1}; kvadrat doira + 2 = ${circles + 2} bo‘lishi kerak.',
          ),
        ]);
      }
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
