part of 'math_models.dart';

/// Original worked paths. No private assessment keys or client-side XP grading.
class _BracketExplorer extends StatefulWidget {
  final String mode;
  const _BracketExplorer({required this.mode});
  @override
  State<_BracketExplorer> createState() => _BracketExplorerState();
}

class _BracketExplorerState extends State<_BracketExplorer> {
  int step = 0;
  bool grouped = true;
  @override
  void didUpdateWidget(_BracketExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      step = 0;
      grouped = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doubleBracket = widget.mode == 'brackets_double';
    final composite = widget.mode == 'brackets_composite';
    final expressions = composite
        ? grouped
              ? const ['54 − (12 + 21)', '54 − 33', '21']
              : const ['54 − 12 + 21', '42 + 21', '63']
        : doubleBracket
        ? const ['(7 + 2) − (6 − 3)', '9 − (6 − 3)', '9 − 3', '6']
        : grouped
        ? const ['15 − (3 + 4)', '15 − 7', '8']
        : const ['15 − 3 + 4', '12 + 4', '16'];
    final explanations = composite
        ? grouped
              ? const [
                  'Avval qavsdagi 12+21 hisoblanadi.',
                  'Qavsdagi butun yig‘indi 33 bilan almashtirildi.',
                  '54−33=21. Butun yig‘indi ayirildi.',
                ]
              : const [
                  'Faqat+va−bor; qavs yo‘q: chapdan o‘ngga.',
                  'Avval 54−12=42. Endi 21 qo‘shiladi.',
                  '42+21=63. Bu qavsli yo‘lning 21 javobidan farq qiladi.',
                ]
        : doubleBracket
        ? const [
            'Tashqi ayirish ikkala qavs natijasini kutadi. Bu yo‘lda chap qavsdan boshlaymiz.',
            'Chap qavs: 7 + 2 = 9. O‘ng qavs hali tayyor emas.',
            'O‘ng qavs: 6 − 3 = 3. Endi ikkala oraliq natija tayyor.',
            'Tashqi ayirish: 9 − 3 = 6. Mustaqil qavslarni boshqa navbatda tekshirish ham mumkin.',
          ]
        : grouped
        ? const [
            'Qavs birinchi amalni ajratadi: avval 3 + 4.',
            'Ichki yig‘indi 7 bo‘ldi; uni qavs o‘rniga yozamiz.',
            'Keyin 15 − 7 = 8. Butun yig‘indi ayirildi.',
          ]
        : const [
            'Bu yerda faqat + va − bor, qavs yo‘q: chapdan o‘ngga yuramiz.',
            'Avval 15 − 3 = 12. Endi 4 qo‘shiladi.',
            '12 + 4 = 16. Qavsli yo‘lning 8 javobidan farq qiladi.',
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Amalni bir qadamdan kuzat'),
            if (!doubleBracket)
              SwitchListTile(
                title: const Text('Qavs bilan guruhla'),
                value: grouped,
                onChanged: (v) => setState(() {
                  grouped = v;
                  step = 0;
                }),
              ),
            Semantics(
              liveRegion: true,
              child: Text(
                expressions[step],
                key: const ValueKey('bracket-current-expression'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text('Qadam ${step + 1} / ${expressions.length}'),
            Text(explanations[step]),
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
            const Text(
              'Namuna qadamlarini sinab ko‘r, keyin mustaqil mashqqa o‘t.',
            ),
          ],
        ),
      ),
    );
  }
}
