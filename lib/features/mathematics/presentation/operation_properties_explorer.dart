part of 'math_models.dart';

class _OperationPropertiesExplorer extends StatefulWidget {
  final String mode;
  const _OperationPropertiesExplorer({required this.mode});
  @override
  State<_OperationPropertiesExplorer> createState() =>
      _OperationPropertiesExplorerState();
}

class _OperationPropertiesExplorerState
    extends State<_OperationPropertiesExplorer> {
  int base = 2, stage = 0, row = 3, column = 4;
  bool swapped = false;
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final mode = widget.mode;
    if (mode == 'addition_table') {
      children.addAll([
        const Text(
          'Qo‘shish jadvali: qator va ustunni tanla',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('$row-qator, $column-ustun: $row + $column = ${row + column}'),
        const Text(
          'Yon tomonga surib boshqa ustunlarni ko‘r. Bo‘sh kataklarda natija berilmagan; ular nol emas.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 560,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(56),
              border: TableBorder.all(color: mathIndigo),
              children: [
                TableRow(
                  children: [
                    for (var c = 0; c <= 9; c++)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          c == 0 ? '+' : '$c',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                for (var r = 1; r <= 9; r++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '$r',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (var c = 1; c <= 9; c++)
                        r + c > 10
                            ? const SizedBox(height: 56)
                            : Semantics(
                                label: '$r-qator, $c-ustun, yig‘indi ${r + c}',
                                child: TextButton(
                                  key: ValueKey('math-table-$r-$c'),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(56, 56),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: row == r && column == c
                                        ? mathTurquoise
                                        : null,
                                    foregroundColor: mathIndigo,
                                  ),
                                  onPressed: () => setState(() {
                                    row = r;
                                    column = c;
                                  }),
                                  child: Text('${r + c}'),
                                ),
                              ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ]);
    } else if (mode == 'expression_steps') {
      const steps = ['4 + 2 − 1', '6 − 1', '5'];
      children.addAll([
        const Text(
          'Ifodani qadamlab hisobla',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: Text(
            steps[stage],
            key: ValueKey(stage),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          stage == 0
              ? 'Avval chapdagi 4 + 2 ni hisoblaymiz.'
              : stage == 1
              ? 'Endi oraliq natija 6 dan 1 ni ayiramiz.'
              : 'Ifodaning qiymati 5. Har qadam oldingi natijadan davom etdi.',
        ),
        FilledButton(
          onPressed: () => setState(() => stage = stage == 2 ? 0 : stage + 1),
          child: Text(stage == 2 ? 'Boshidan hisoblash' : 'Keyingi hisob'),
        ),
      ]);
    } else if (mode == 'compare_same_addend') {
      children.addAll([
        const Text(
          'Ikkala tomonda bir xil qism',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('$base + 6 > $base + 3', style: const TextStyle(fontSize: 24)),
        Text('Birinchi miqdor: ${base + 6}'),
        LinearProgressIndicator(
          value: (base + 6) / 10,
          semanticsLabel: 'Birinchi guruh miqdori ${base + 6}',
        ),
        Text('Ikkinchi miqdor: ${base + 3}'),
        LinearProgressIndicator(
          value: (base + 3) / 10,
          color: mathIndigo,
          semanticsLabel: 'Ikkinchi guruh miqdori ${base + 3}',
        ),
        Slider(
          value: base.toDouble(),
          min: 1,
          max: 4,
          divisions: 3,
          semanticFormatterCallback: (v) =>
              'Ikkala guruhning umumiy qismi ${v.round()}',
          onChanged: (v) => setState(() => base = v.round()),
        ),
        const Text(
          'Bir xil qo‘shiluvchi ikkala tomonda birga o‘zgardi. 6 esa 3 dan katta bo‘lib qoladi.',
        ),
      ]);
    } else {
      final first = swapped ? 2 : 3, second = swapped ? 3 : 2;
      children.addAll([
        const Text(
          'Faqat guruhlarning o‘rni almashadi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('$first + $second = 5', style: const TextStyle(fontSize: 24)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var group = 0; group < 2; group++)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: mathIndigo),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < (group == 0 ? first : second); i++)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Semantics(
                          label: '${group + 1}-guruh ${i + 1}-shakl',
                          child: SizedBox.square(
                            dimension: 24,
                            child: CustomPaint(
                              painter: MathShapePainter(
                                group == (swapped ? 1 : 0)
                                    ? 'circle'
                                    : 'square',
                                group == (swapped ? 1 : 0)
                                    ? mathTurquoise
                                    : mathYellow,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        FilledButton(
          onPressed: () => setState(() => swapped = !swapped),
          child: const Text('O‘rinlarini almashtir'),
        ),
        const Text(
          'Uchta doira va ikkita kvadrat o‘z miqdori hamda turini saqladi. Jami beshta shakl.',
        ),
      ]);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
