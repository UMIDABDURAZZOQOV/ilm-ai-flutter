part of 'math_models.dart';

class _SumExplorer extends StatefulWidget {
  final String mode;
  const _SumExplorer({required this.mode});
  @override
  State<_SumExplorer> createState() => _SumExplorerState();
}

class _SumExplorerState extends State<_SumExplorer> {
  int step = 0, sample = 0;
  bool right = false;
  @override
  void didUpdateWidget(_SumExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      step = 0;
      sample = 0;
      right = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouping = widget.mode == 'addition_grouping';
    final table = widget.mode == 'multi_addition_table';
    final terms = sample == 0 ? const [12, 23, 14] : const [15, 12, 21];
    final first = terms[0] + terms[1], total = terms[0] + terms[1] + terms[2];
    final expressions = table
        ? const [
            '12 + ? + 14 = 58',
            '12 + 14 = 26',
            '58 − 26 = 32',
            '12 + 32 + 14 = 58',
          ]
        : grouping
        ? right
              ? const ['12 + (5 + 3)', '12 + 8', '20']
              : const ['(12 + 5) + 3', '17 + 3', '20']
        : [terms.join(' + '), '$first + ${terms[2]}', '$total'];
    final notes = table
        ? const [
            'Bir ustunning jami va ikkita qismi berilgan.',
            'Ma’lum ikkala qismni birlashtiramiz.',
            'Butungacha yetishmagan qismni topamiz.',
            'Qiymatni o‘rniga qo‘yib, butun ustunni tekshiramiz.',
          ]
        : grouping
        ? [
            right
                ? 'Avval 5 va 3 birlashtiriladi.'
                : 'Avval 12 va 5 birlashtiriladi.',
            'Oraliq natija o‘zgardi, lekin qo‘shiluvchilarning o‘zi saqlandi.',
            'Ikkala guruhlashning yakuni 20. Bu qo‘shish xossasi.',
          ]
        : [
            'Uchta qo‘shiluvchi, ikkita qo‘shish amali.',
            'Dastlabki ikkita miqdor oraliq $first natijaga birlashdi.',
            'Uchinchi qism ham qo‘shildi. Har biri bir marta sanaldi.',
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              table
                  ? 'Jadvalning shu ustunini to‘ldir'
                  : grouping
                  ? 'Qavsni o‘zgartir, miqdorni saqla'
                  : 'Har bir qo‘shiluvchini bir marta qo‘sh',
            ),
            if (grouping)
              SwitchListTile(
                title: const Text('O‘ngdagi ikki sonni birinchi guruhla'),
                value: right,
                onChanged: (v) => setState(() {
                  right = v;
                  step = 0;
                }),
              ),
            if (!grouping && !table)
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < 2; i++)
                    ChoiceChip(
                      label: Text(i == 0 ? '12 + 23 + 14' : '15 + 12 + 21'),
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
                key: const ValueKey('sum-current-expression'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text('Qadam ${step + 1} / ${expressions.length}'),
            Text(notes[step]),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  onPressed: step == expressions.length - 1
                      ? null
                      : () => setState(() => step++),
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
