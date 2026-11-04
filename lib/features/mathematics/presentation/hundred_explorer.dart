part of 'math_models.dart';

class _HundredExplorer extends StatefulWidget {
  final String mode;
  const _HundredExplorer({required this.mode});
  @override
  State<_HundredExplorer> createState() => _HundredExplorerState();
}

class _HundredExplorerState extends State<_HundredExplorer> {
  int number = 42, step = 1;
  bool get round => widget.mode == 'round_tens_100';
  bool get chart => widget.mode == 'hundred_chart';
  @override
  void initState() {
    super.initState();
    if (round) number = 40;
  }

  @override
  void didUpdateWidget(_HundredExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      number = round ? 40 : 42;
      step = 1;
    }
  }

  Widget rod(String name, int count, int value) => Semantics(
    container: true,
    label: '$name yo‘li: $count faol tosh, qiymati ${count * value}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$name: $count faol tosh'),
        ExcludeSemantics(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 9; i++)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < count ? mathTurquoise : Colors.transparent,
                    border: Border.all(color: mathIndigo, width: 2),
                  ),
                  child: i < count
                      ? const Icon(Icons.check, size: 16, color: mathIndigo)
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    const names = [
      'nol',
      'o‘n',
      'yigirma',
      'o‘ttiz',
      'qirq',
      'ellik',
      'oltmish',
      'yetmish',
      'sakson',
      'to‘qson',
      'yuz',
    ];
    final tens = number ~/ 10, units = number % 10;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              round
                  ? 'O‘ntalab sanaymiz'
                  : chart
                  ? 'Sonlar jadvalini o‘rgan'
                  : widget.mode == 'abacus_100'
                  ? 'Faol toshni xonasi bilan o‘qi'
                  : 'O‘nlik va birlikdan son tuz',
            ),
            Text(
              round
                  ? '$number — ${names[tens]}'
                  : '$number = ${tens * 10} + $units',
              key: const ValueKey('hundred-current-number'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text('$tens ta to‘liq o‘nlik va $units ta alohida birlik'),
            if (number == 100)
              const Text(
                '10 ta o‘nlik = 100 birlik = 1 yuzlik. Yozuvda uchta raqam bor.',
              ),
            if (round) ...[
              Slider(
                key: const ValueKey('round-tens-slider'),
                value: tens.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                semanticFormatterCallback: (v) =>
                    '${v.round()} o‘nlik, ${v.round() * 10} birlik',
                onChanged: (v) => setState(() => number = v.round() * 10),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < tens; i++)
                    Chip(label: Text('${i + 1}-o‘nlik: 10')),
                ],
              ),
              const Text(
                'Guruhlar soni bilan jami birliklar miqdori boshqa-boshqa.',
              ),
            ] else if (chart) ...[
              const Text(
                'Jadvalni yon tomonga surish mumkin. Yonma-yon sonlar1ga, bir ustundagi keyingi qator10ga farq qiladi.',
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 720,
                  child: Table(
                    border: TableBorder.all(color: mathIndigo),
                    children: [
                      for (var row = 0; row < 10; row++)
                        TableRow(
                          children: [
                            for (var col = 0; col < 10; col++)
                              SizedBox(
                                height: 72,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: number == row * 10 + col
                                        ? mathYellow
                                        : null,
                                    foregroundColor: mathIndigo,
                                  ),
                                  onPressed: () =>
                                      setState(() => number = row * 10 + col),
                                  child: Text('${row * 10 + col}'),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => setState(() => number = 100),
                child: const Text('100 — yuz'),
              ),
              Text(
                number == 0
                    ? 'Keyingi qo‘shni: 1'
                    : number == 100
                    ? 'Oldingi qo‘shni: 99. Bu jadval100da tugaydi.'
                    : 'Qo‘shnilar: ${number - 1} va ${number + 1}',
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final amount in [1, 2, 3, 5, 10])
                    ChoiceChip(
                      label: Text('Qadam: $amount'),
                      selected: step == amount,
                      onSelected: (_) => setState(() => step = amount),
                    ),
                ],
              ),
              FilledButton(
                onPressed: number + step > 100
                    ? null
                    : () => setState(() => number += step),
                child: Text('Yana $step qo‘sh'),
              ),
            ] else ...[
              Text('O‘nliklar soni: $tens'),
              Slider(
                key: const ValueKey('hundred-tens-slider'),
                value: tens.toDouble(),
                min: 1,
                max: 9,
                divisions: 8,
                semanticFormatterCallback: (v) => '${v.round()} ta o‘nlik',
                onChanged: (v) =>
                    setState(() => number = v.round() * 10 + units),
              ),
              Text('Birliklar soni: $units'),
              Slider(
                key: const ValueKey('hundred-units-slider'),
                value: units.toDouble(),
                min: 0,
                max: 9,
                divisions: 9,
                semanticFormatterCallback: (v) => '${v.round()} ta birlik',
                onChanged: (v) =>
                    setState(() => number = tens * 10 + v.round()),
              ),
              if (widget.mode == 'abacus_100') ...[
                rod('O‘nlik', tens, 10),
                rod('Birlik', units, 1),
                const Text(
                  'Faol toshlar ✓ bilan belgilangan. O‘nlik toshi10, birlik toshi1ni bildiradi.',
                ),
              ] else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < tens; i++)
                      Chip(label: Text('${i + 1}-o‘nlik: 10')),
                    Chip(label: Text('Alohida: $units')),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
