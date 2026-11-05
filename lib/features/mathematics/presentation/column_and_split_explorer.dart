part of 'math_models.dart';

/// Teaching examples only. Assessment answers and rewards stay on the server.
class _ColumnAndSplitExplorer extends StatefulWidget {
  final String mode;
  const _ColumnAndSplitExplorer({required this.mode});
  @override
  State<_ColumnAndSplitExplorer> createState() =>
      _ColumnAndSplitExplorerState();
}

class _ColumnAndSplitExplorerState extends State<_ColumnAndSplitExplorer> {
  int sample = 0, step = 0;
  @override
  void didUpdateWidget(_ColumnAndSplitExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      sample = 0;
      step = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final split = widget.mode == 'split_two_digit_subtraction';
    final pairs = split
        ? const [(54, 28), (62, 17), (85, 39)]
        : const [(47, 21), (68, 41), (53, 4)];
    final (a, b) = pairs[sample];
    final minus = split || sample == 1;
    final result = minus ? a - b : a + b;
    final sign = minus ? '−' : '+';
    final afterTens = a - (b ~/ 10) * 10;
    final toTen = afterTens % 10;
    final rest = b % 10 - toTen;
    final values = [a, afterTens, afterTens - toTen, result];
    final splitText = [
      '$a − $b',
      '$a − ${(b ~/ 10) * 10} = $afterTens',
      '$afterTens − $toTen = ${afterTens - toTen}',
      '${afterTens - toTen} − $rest = $result',
    ];
    final ones = minus ? a % 10 - b % 10 : a % 10 + b % 10;
    final tens = minus ? a ~/ 10 - b ~/ 10 : a ~/ 10 + b ~/ 10;
    final explanation = split
        ? [
            '$b = ${(b ~/ 10) * 10} + ${b % 10}. Avval o‘nliklar, keyin barcha birliklar olinadi.',
            'Ayriluvchining o‘nliklari olindi. Yana ${b % 10} birlik olinishi kerak.',
            '${b % 10} = $toTen + $rest. Pastroq o‘nlikka yetdik; yana $rest birlik qoldi.',
            'Jami ${(b ~/ 10) * 10} + $toTen + $rest = $b olindi. Tekshiruv: $result + $b = $a.',
          ]
        : [
            'Birliklar birliklar ostiga, o‘nliklar o‘nliklar ostiga yoziladi. Bir xonali son o‘ngga moslanadi.',
            '${a % 10} $sign ${b % 10} = $ones birlik. Bu namunalarda yangi o‘nlik yoki qarz olish shart emas.',
            '${a ~/ 10} $sign ${b ~/ 10} = $tens o‘nlik. Birlik natijasi o‘z xonasida saqlanadi.',
            '$tens o‘nlik va $ones birlik — $result. Tekshiruv: ${minus ? '$result + $b = $a' : '$result − $b = $a'}.',
          ];
    Widget cell(String text) => Expanded(
      child: Center(child: Text(text, textAlign: TextAlign.center)),
    );
    Widget digitRow(int value, {String operation = ''}) => Row(
      children: [
        SizedBox(width: 24, child: Text(operation)),
        cell(value >= 10 ? '${value ~/ 10}' : ''),
        cell('${value % 10}'),
      ],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              split
                  ? 'Ayriluvchining har bir qismini olamiz'
                  : 'Ustunda xona qiymatlari',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < pairs.length; i++)
                  ChoiceChip(
                    label: Text(
                      '${pairs[i].$1} ${split || i == 1 ? '−' : '+'} ${pairs[i].$2}',
                    ),
                    selected: sample == i,
                    onSelected: (_) => setState(() {
                      sample = i;
                      step = 0;
                    }),
                  ),
              ],
            ),
            if (!split)
              Semantics(
                label: 'Ustun modeli: $a $sign $b. Birliklar o‘ng ustunda.',
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 24),
                          cell('O‘nlik'),
                          cell('Birlik'),
                        ],
                      ),
                      digitRow(a),
                      digitRow(b, operation: sign),
                      const Divider(),
                      if (step > 0)
                        Row(
                          children: [
                            const SizedBox(width: 24),
                            cell(step > 1 ? '$tens' : '?'),
                            cell('$ones'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            Semantics(
              liveRegion: true,
              child: Text(
                split
                    ? splitText[step]
                    : step == 0
                    ? '$a $sign $b'
                    : step == 1
                    ? '${a % 10} $sign ${b % 10} = $ones birlik'
                    : step == 2
                    ? '${a ~/ 10} $sign ${b ~/ 10} = $tens o‘nlik'
                    : '$a $sign $b = $result',
                key: const ValueKey('column-expression'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text('Qadam: ${step + 1} / 4', key: const ValueKey('column-step')),
            Text(explanation[step]),
            if (split)
              Semantics(
                label: '${values[step]} miqdor qoldi',
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 155,
                    child: CustomPaint(
                      painter: _RegroupHundredPainter(
                        values[step] ~/ 10,
                        values[step] % 10,
                      ),
                    ),
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('column-back'),
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  key: const ValueKey('column-next'),
                  onPressed: step == 3 ? null : () => setState(() => step++),
                  child: const Text('Keyingi qadam'),
                ),
              ],
            ),
            if (step == 3)
              const Text(
                'Bu yo‘l-yo‘riqli model. Mustaqil javob alohida tekshiriladi.',
              ),
          ],
        ),
      ),
    );
  }
}
