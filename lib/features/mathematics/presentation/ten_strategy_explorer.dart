part of 'math_models.dart';

class _TenStrategyExplorer extends StatefulWidget {
  final String mode;
  const _TenStrategyExplorer({required this.mode});
  @override
  State<_TenStrategyExplorer> createState() => _TenStrategyExplorerState();
}

class _TenStrategyExplorerState extends State<_TenStrategyExplorer> {
  int step = 0, sample = 0;
  @override
  void didUpdateWidget(_TenStrategyExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      step = 0;
      sample = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairs = const {
      'bridge_ten_intro': [(9, 4), (8, 5)],
      'bridge_ten_apply': [(7, 6), (8, 7)],
      'bridge_ten_line': [(9, 8), (6, 7)],
      'subtract_units_20': [(18, 3), (17, 5), (19, 6)],
      'subtract_bridge_ten': [(14, 8), (16, 9), (12, 5)],
    }[widget.mode]!;
    final (a, b) = pairs[sample];
    final subtract = widget.mode.startsWith('subtract');
    final unitsOnly = widget.mode == 'subtract_units_20';
    final symbol = subtract ? '−' : '+';
    final first = unitsOnly
        ? a % 10
        : subtract
        ? a - 10
        : 10 - a;
    final rest = unitsOnly ? first - b : b - first;
    final result = subtract ? a - b : a + b;
    final expressions = unitsOnly
        ? [
            '$a − $b',
            '$a = 10 + $first',
            '$first − $b = $rest',
            '10 + $rest = $result',
          ]
        : [
            '$a $symbol $b',
            '$b = $first + $rest',
            '$a $symbol $first = 10',
            '10 $symbol $rest = $result',
          ];
    final explanations = unitsOnly
        ? [
            'Ayriluvchi $b mavjud $first birlikdan oshmaydi.',
            'Bitta o‘nlikni ajratdik, $first alohida birlik qoldi.',
            '$b ni faqat birliklar qismidan oldik. O‘nlik saqlandi.',
            'O‘nlik va qolgan birliklar yakuniy miqdorni beradi.',
          ]
        : [
            subtract
                ? 'Avval $a dan 10 ga tushish uchun $first ni ayiramiz.'
                : 'Avval $a ni 10 gacha to‘ldirish uchun $first qo‘shamiz.',
            'Ikkinchi son $b ikki qismga ajratildi. $first va $rest birga aynan $b.',
            'Birinchi qism ishlatildi, tayanch natija 10. Hali $rest qism bor.',
            'Qolgan $rest qism ham bir marta ${subtract ? 'ayirildi' : 'qo‘shildi'}. Yakun $result.',
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(unitsOnly ? 'O‘nlik saqlanadi' : 'O‘nlik tayanch bo‘ladi'),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < pairs.length; i++)
                  ChoiceChip(
                    label: Text('${pairs[i].$1} $symbol ${pairs[i].$2}'),
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
                expressions[step],
                key: const ValueKey('ten-strategy-expression'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text('Qadam ${step + 1} / 4'),
            Text(explanations[step]),
            if (step >= 1)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      unitsOnly ? 'O‘nlik: 10' : 'Birinchi qism: $first',
                    ),
                  ),
                  if (!unitsOnly || step >= 2)
                    Chip(
                      label: Text(
                        unitsOnly
                            ? 'Qolgan birlik: $rest'
                            : 'Qolgan qism: $rest',
                      ),
                    ),
                ],
              ),
            if (!subtract)
              for (final (index, count)
                  in (step < 2 ? [a, b] : [10, rest]).indexed)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: mathIndigo),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        step < 2
                            ? '${index + 1}-qo‘shiluvchi: $count'
                            : index == 0
                            ? 'To‘liq o‘nlik: 10'
                            : 'Qolgan birliklar: $count',
                      ),
                      Semantics(
                        label: '$count ta birlik',
                        child: ExcludeSemantics(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (var i = 0; i < count; i++)
                                SizedBox.square(
                                  dimension: 20,
                                  child: CustomPaint(
                                    painter: MathShapePainter(
                                      'circle',
                                      index == 0 ? mathTurquoise : mathYellow,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            if (widget.mode == 'bridge_ten_line') ...[
              const Text('Yo‘lda boshlangan joy qadam emas'),
              Wrap(
                spacing: 6,
                children: [
                  for (var v = a; v <= result; v++)
                    Semantics(
                      label: v == a
                          ? 'Boshlanish $v; hali 0 qadam'
                          : '${v - a}-qadamdan keyingi son $v',
                      excludeSemantics: true,
                      child: Chip(
                        backgroundColor: v == 10 ? mathYellow : null,
                        label: Text('$v'),
                      ),
                    ),
                ],
              ),
              Text('$first qadam va $rest qadam: jami $b qadam'),
            ],
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  onPressed: step == 3 ? null : () => setState(() => step++),
                  child: const Text('Keyingi qadam'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
