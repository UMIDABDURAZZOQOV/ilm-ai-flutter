part of 'math_models.dart';

class _AlgebraPracticeExplorer extends StatefulWidget {
  final String mode;
  const _AlgebraPracticeExplorer({required this.mode});
  @override
  State<_AlgebraPracticeExplorer> createState() =>
      _AlgebraPracticeExplorerState();
}

class _AlgebraPracticeExplorerState extends State<_AlgebraPracticeExplorer> {
  int expression = 0,
      parameter = 7,
      a = 4,
      b = 6,
      c = 5,
      band = 0,
      candidate = 26;
  bool given = true, swapped = false, lastGroup = false;
  @override
  void didUpdateWidget(_AlgebraPracticeExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      expression = 0;
      parameter = 7;
      a = 4;
      b = 6;
      c = 5;
      band = 0;
      candidate = 26;
      given = true;
      swapped = false;
      lastGroup = false;
    }
  }

  Widget live(String s, String key) => Semantics(
    liveRegion: true,
    child: Text(
      s,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  Widget slider(
    String key,
    int value,
    int min,
    int max,
    String label,
    ValueChanged<int> change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label: $value'),
      Slider(
        key: ValueKey(key),
        value: value.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: max - min,
        semanticFormatterCallback: (v) => '$label ${v.round()}',
        onChanged: (v) => setState(() => change(v.round())),
      ),
    ],
  );
  bool inequality(int x) => switch (band) {
    0 => 25 < x && x < 30,
    1 => x < 15,
    2 => x > 95,
    _ => 40 < x && x < 45,
  };
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (widget.mode == 'algebra_value_table') {
      const names = ['x + 9', '18 + (a − 5)', '37 + 13 + (20 − 10)'];
      final numeric = expression == 2,
          value = expression == 0
              ? parameter + 9
              : expression == 1
              ? 18 + (parameter - 5)
              : 60;
      rows.addAll([
        const Text(
          'Ifodani tanlang. Harfning qiymati berilganida uni son bilan almashtirib hisoblaymiz; qavs ichidagi amal avval bajariladi.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 3; i++)
              ChoiceChip(
                label: Text(names[i]),
                selected: expression == i,
                onSelected: (_) => setState(() {
                  expression = i;
                  if (i == 1 && parameter < 5) {
                    parameter = 5;
                  }
                }),
              ),
          ],
        ),
        if (!numeric)
          SwitchListTile(
            key: const ValueKey('evaluation-given'),
            value: given,
            onChanged: (v) => setState(() => given = v),
            title: const Text('Harfning qiymati berilgan'),
          ),
        if (!numeric && given)
          slider(
            'evaluation-parameter',
            parameter,
            expression == 1 ? 5 : 0,
            20,
            expression == 1 ? 'a qiymati' : 'x qiymati',
            (v) => parameter = v,
          ),
        if (numeric || given) ...[
          Text(
            expression == 0
                ? 'x + 9 = $parameter + 9'
                : expression == 1
                ? 'Qavs: $parameter − 5 = ${parameter - 5}; keyin 18 + ${parameter - 5}'
                : 'Qavs: 20 − 10 = 10; keyin 37 + 13 + 10',
          ),
          live('Qiymat: $value', 'evaluation-result'),
        ] else
          const Text(
            'Aynan shu ifodaning bitta sonli qiymati uchun harfning qiymati yetishmayapti.',
          ),
        const Text(
          'Qaysi son berilganini, amal tartibini va qavsni birga tekshiring.',
        ),
      ]);
    } else if (widget.mode == 'algebra_addition_properties') {
      final first = swapped ? b : a,
          second = swapped ? a : b,
          total = a + b + c;
      rows.addAll([
        const Text(
          'Bir xil uchta qo‘shiluvchi. Har biri bir marta saqlanadi; faqat tartibi yoki avval hisoblanadigan juftlik o‘zgaradi.',
        ),
        slider('properties-a', a, 0, 20, 'a', (v) => a = v),
        slider('properties-b', b, 0, 20, 'b', (v) => b = v),
        slider('properties-c', c, 0, 20, 'c', (v) => c = v),
        SwitchListTile(
          key: const ValueKey('properties-swap'),
          value: swapped,
          onChanged: (v) => setState(() => swapped = v),
          title: const Text(
            'Birinchi ikkita qo‘shiluvchi o‘rnini almashtirish',
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Avval birinchi juftlik'),
              selected: !lastGroup,
              onSelected: (_) => setState(() => lastGroup = false),
            ),
            ChoiceChip(
              label: const Text('Avval oxirgi juftlik'),
              selected: lastGroup,
              onSelected: (_) => setState(() => lastGroup = true),
            ),
          ],
        ),
        Semantics(
          label: 'Qismlar $first, $second, $c; jami $total',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 85,
              width: double.infinity,
              child: CustomPaint(
                painter: _AdditionGroupsPainter(first, second, c, lastGroup),
              ),
            ),
          ),
        ),
        live(
          lastGroup
              ? '$first + ($second + $c) = $total'
              : '($first + $second) + $c = $total',
          'properties-result',
        ),
        Text('$a + $b = ${a + b}; $b + $a = ${b + a}'),
        const Text(
          'Qo‘shish xossalari qavsli ayirishni shartsiz almashtirishga ruxsat bermaydi. Ayni qismlarning to‘liqligini saqlang.',
        ),
      ]);
    } else {
      const bands = ['25 < x < 30', 'x < 15', 'x > 95', '40 < x < 45'];
      final twoDigit = candidate >= 10 && candidate <= 99,
          relation = inequality(candidate),
          solutions = [
            for (var i = 10; i <= 99; i++)
              if (inequality(i)) i,
          ];
      rows.addAll([
        const Text(
          'Barcha javoblar butun va ikki xonali: 10–99. < va > belgilarida chegaraning o‘zi kirmaydi.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 4; i++)
              ChoiceChip(
                label: Text(bands[i]),
                selected: band == i,
                onSelected: (_) => setState(() => band = i),
              ),
          ],
        ),
        slider(
          'inequality-candidate',
          candidate,
          0,
          100,
          'x nomzodi',
          (v) => candidate = v,
        ),
        Text(
          'Ikki xonali: ${twoDigit ? 'ha' : 'yo‘q'}; tengsizlik rost: ${relation ? 'ha' : 'yo‘q'}.',
        ),
        live(
          twoDigit && relation
              ? 'Ikkala shartga mos.'
              : 'Ikkala shart birga bajarilmadi.',
          'inequality-membership',
        ),
        Text('Barcha mos sonlar: ${solutions.join(', ')}'),
        live('Mos sonlar soni: ${solutions.length}', 'inequality-count'),
        const Text(
          '9 tengsizlikka mos kelishi mumkin, ammo ikki xonali emas. 100 ham ikki xonali emas. Qo‘shimcha shartni tashlab ketmang.',
        ),
      ]);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

class _AdditionGroupsPainter extends CustomPainter {
  final int a, b, c;
  final bool last;
  _AdditionGroupsPainter(this.a, this.b, this.c, this.last);
  @override
  void paint(Canvas canvas, Size size) {
    final unit = (size.width - 24) / 60;
    var start = 12.0;
    final values = [a, b, c], colors = [mathIndigo, mathTurquoise, mathYellow];
    for (var i = 0; i < 3; i++) {
      if (values[i] > 0) {
        canvas.drawRect(
          Rect.fromLTWH(start, 10, values[i] * unit, 28),
          Paint()..color = colors[i],
        );
      }
      start += values[i] * unit;
    }
    final from = 12 + (last ? a : 0) * unit,
        to = 12 + (last ? a + b + c : a + b) * unit;
    canvas.drawLine(
      Offset(from, 50),
      Offset(to, 50),
      Paint()
        ..color = mathIndigo
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_AdditionGroupsPainter old) =>
      old.a != a || old.b != b || old.c != c || old.last != last;
}
