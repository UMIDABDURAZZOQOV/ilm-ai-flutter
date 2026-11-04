part of 'math_models.dart';

class _TwoDigitExplorer extends StatefulWidget {
  final String mode;
  const _TwoDigitExplorer({required this.mode});
  @override
  State<_TwoDigitExplorer> createState() => _TwoDigitExplorerState();
}

class _TwoDigitExplorerState extends State<_TwoDigitExplorer> {
  int sample = 0, step = 0;
  @override
  void didUpdateWidget(_TwoDigitExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      sample = 0;
      step = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final missing = widget.mode == 'two_digit_missing_addend';
    final inverse = widget.mode == 'two_digit_inverse';
    final subtract = widget.mode == 'two_digit_subtraction';
    final pairs = subtract
        ? const [(86, 34), (87, 25), (95, 43)]
        : const [(34, 25), (53, 24), (13, 24)];
    final (a, b) = pairs[sample];
    final symbol = subtract ? '−' : '+';
    final units = subtract ? a % 10 - b % 10 : a % 10 + b % 10;
    final tens = subtract ? a ~/ 10 - b ~/ 10 : a ~/ 10 + b ~/ 10;
    final result = subtract ? a - b : a + b;
    final expressions = missing
        ? const ['23 + ? = 56', '23 + 30 = 53', '53 + 3 = 56', '30 + 3 = 33']
        : inverse
        ? const ['23 + 45 = 68', '45 + 23 = 68', '68 − 23 = 45', '68 − 45 = 23']
        : [
            '$a $symbol $b',
            '${a % 10} $symbol ${b % 10} = $units',
            '${a ~/ 10 * 10} $symbol ${b ~/ 10 * 10} = ${tens * 10}',
            '${tens * 10} + $units = $result',
          ];
    final explanations = missing
        ? const [
            'Qancha qo‘shilsa butun 56 hosil bo‘ladi?',
            'O‘nlik qismi uchun 30 qo‘shildi.',
            'Qolgan 3 birlik ham qo‘shildi.',
            'Qo‘shilgan ikki qismning jami 33. Tekshir:23+33=56.',
          ]
        : inverse
        ? const [
            'Ikki qism bir butun 68 ni tiklaydi.',
            'Qo‘shiluvchilar o‘rni almashdi, yig‘indi saqlandi.',
            'Butundan 23 qismi olinsa 45 qoladi.',
            'Butundan 45 qismi olinsa 23 qoladi.',
          ]
        : [
            subtract
                ? 'Bu misolda birliklar ayirishga yetadi; o‘nlikni maydalash kerak emas.'
                : 'Bu misolda birliklar yig‘indisi 10 dan kichik. Yangi o‘nlik hosil bo‘lmaydi.',
            'Avval birliklarni o‘zaro hisobladik.',
            'Endi o‘nliklar qiymatini o‘zaro hisobladik.',
            'Qolgan xona qiymatlarini bitta son qilib yig‘dik.',
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              missing
                  ? 'Qo‘shilgan qismlarni kuzat'
                  : inverse
                  ? 'Bir butun — ikki qism'
                  : 'Bir xil xonalarni hisobla',
            ),
            if (!missing && !inverse)
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
                key: const ValueKey('two-digit-expression'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text('Qadam ${step + 1} / 4'),
            Text(explanations[step]),
            if (!missing && !inverse)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('$a: ${a ~/ 10} o‘nlik, ${a % 10} birlik')),
                  Chip(label: Text('$b: ${b ~/ 10} o‘nlik, ${b % 10} birlik')),
                  if (step == 3)
                    Chip(label: Text('$result: $tens o‘nlik, $units birlik')),
                ],
              ),
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
