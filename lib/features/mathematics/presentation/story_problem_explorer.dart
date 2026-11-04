part of 'math_models.dart';

/// Original examples: reading meaning comes before calculation.
/// This explorer teaches a worked example; assessment and XP stay on the server.
class _StoryProblemExplorer extends StatefulWidget {
  final String mode;
  const _StoryProblemExplorer({required this.mode});
  @override
  State<_StoryProblemExplorer> createState() => _StoryProblemExplorerState();
}

class _StoryProblemExplorerState extends State<_StoryProblemExplorer> {
  int selected = 0, number = 27, step = 0, known = 20;
  bool reveal = false;
  int secondPart = 14, minimumHours = 2, maximumHeight = 7;
  final Set<int> totalsSeen = {};
  @override
  void initState() {
    super.initState();
    if (widget.mode == 'problem_missing_part') known = 21;
  }

  @override
  void didUpdateWidget(_StoryProblemExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      selected = 0;
      number = 27;
      step = 0;
      known = widget.mode == 'problem_missing_part' ? 21 : 20;
      reveal = false;
      totalsSeen.clear();
      secondPart = 14;
      minimumHours = 2;
      maximumHeight = 7;
    }
  }

  Widget choice(List<String> names) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < names.length; i++)
        ChoiceChip(
          label: Text(names[i]),
          selected: selected == i,
          onSelected: (_) => setState(() => selected = i),
        ),
    ],
  );
  Widget labelledGroups(int amount) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('$amount ta karta'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < amount ~/ 10; i++)
            Chip(label: Text('${i + 1}-o‘nlik:10')),
          for (var i = 0; i < amount % 10; i++)
            Semantics(
              label: 'Alohida birlik ${i + 1}',
              child: SizedBox.square(
                dimension: 24,
                child: CustomPaint(
                  painter: MathShapePainter('circle', mathTurquoise),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (widget.mode == 'problem_parts') {
      children.addAll([
        const Text('Bitta masalaning qismlarini tanla'),
        choice(['Shart', 'Savol', 'Yechim', 'Javob']),
        Semantics(
          liveRegion: true,
          child: Text(
            const [
              '11 ta rangli va 6 ta oq-qora rasm bor.',
              'Jami nechta rasm bor?',
              '11 + 6 = 17',
              '17 ta rasm',
            ][selected],
            key: const ValueKey('story-current-role'),
          ),
        ),
        Text(
          const [
            'Bu nimani bilishimizni aytadi.',
            'Bu nimani topishimiz kerakligini aytadi.',
            'Bu savolga mos hisob.',
            'Son bilan sanalgan predmet birga yozilgan.',
          ][selected],
        ),
      ]);
    } else if (widget.mode == 'problem_algorithm') {
      final larger = number > 45;
      final result = larger ? number - 11 : number + 20;
      children.addAll([
        const Text('Shart bo‘yicha bitta yo‘lni tanla'),
        Text('Boshlang‘ich son:$number'),
        Slider(
          key: const ValueKey('story-algorithm-number'),
          value: number.toDouble(),
          min: 15,
          max: 88,
          divisions: 73,
          semanticFormatterCallback: (v) => 'Boshlang‘ich son ${v.round()}',
          onChanged: (v) => setState(() {
            number = v.round();
            step = 0;
          }),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            step == 0
                ? '$number sonini tekshiramiz'
                : step == 1
                ? '$number > 45 — ${larger ? 'ha' : 'yo‘q'}'
                : '$number ${larger ? '−' : '+'} ${larger ? 11 : 20} = $result',
            key: const ValueKey('story-algorithm-step'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const Text(
          'Ha:11 ayir. Yo‘q:20 qo‘sh. Ikkalasini emas, aynan bitta yo‘lni bajar.',
        ),
        if (number == 45)
          const Text('45 ning o‘zi 45 dan katta emas:«yo‘q» yo‘li.'),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: step == 0 ? null : () => setState(() => step--),
              child: const Text('Oldingi qadam'),
            ),
            FilledButton(
              onPressed: step == 2 ? null : () => setState(() => step++),
              child: const Text('Keyingi qadam'),
            ),
          ],
        ),
      ]);
    } else if (widget.mode == 'problem_part_whole' ||
        widget.mode == 'problem_missing_part') {
      final whole = widget.mode == 'problem_part_whole' ? 76 : 53;
      final remaining = whole - known;
      children.addAll([
        Text('Butun $whole, ma’lum qismni o‘zgartir'),
        Text('Ma’lum qism:$known'),
        Slider(
          key: const ValueKey('story-known-part'),
          value: known.toDouble(),
          min: 0,
          max: whole.toDouble(),
          divisions: whole,
          semanticFormatterCallback: (v) =>
              'Ma’lum qism ${v.round()}, butun $whole',
          onChanged: (v) => setState(() {
            known = v.round();
            reveal = false;
          }),
        ),
        Semantics(
          label: 'Butun $whole; ma’lum qism $known; noma’lum qolgan qism',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 32,
              child: CustomPaint(painter: _ProblemBarPainter(known / whole)),
            ),
          ),
        ),
        const Text(
          'Chizma mantiqiy miqdorni ko‘rsatadi; ekran santimetri emas.',
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            reveal ? '$whole − $known = $remaining' : '$whole = $known + ?',
            key: const ValueKey('story-part-result'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        FilledButton(
          onPressed: reveal ? null : () => setState(() => reveal = true),
          child: const Text('Hisobni ochish'),
        ),
        if (reveal) Text('Tekshir: $known + $remaining = $whole'),
      ]);
    } else if (widget.mode == 'problem_whole_sum') {
      final total = 23 + secondPart;
      children.addAll([
        const Text('Ko‘k qism 23 ta; sariq qismni o‘zgartir'),
        Text('Sariq: $secondPart ta'),
        Slider(
          key: const ValueKey('story-second-part'),
          min: 0,
          max: 30,
          divisions: 30,
          value: secondPart.toDouble(),
          semanticFormatterCallback: (v) => '${v.round()} ta sariq belgi',
          onChanged: (v) => setState(() {
            secondPart = v.round();
            reveal = false;
          }),
        ),
        Text(
          'Ko‘k 23 ta + sariq $secondPart ta = butun ?',
          key: const ValueKey('story-whole-equation'),
        ),
        FilledButton(
          onPressed: reveal ? null : () => setState(() => reveal = true),
          child: const Text('Butunni ochish'),
        ),
        if (reveal) ...[
          Text(
            '23 + $secondPart = $total',
            key: const ValueKey('story-whole-result'),
          ),
          Text('Tekshir: $total − 23 = $secondPart'),
          Semantics(
            label: 'Butun $total; ko‘k 23 va sariq $secondPart ta',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 32,
                child: CustomPaint(painter: _ProblemBarPainter(23 / total)),
              ),
            ),
          ),
        ],
        const Text(
          'Har belgi bitta guruhda sanaladi. Ikki qism ham belgi soni.',
        ),
      ]);
    } else if (widget.mode == 'problem_criteria') {
      final a = minimumHours <= 2 && maximumHeight >= 6;
      final b = minimumHours <= 3 && maximumHeight >= 8;
      children.addAll([
        const Text('O‘yin modeli: barcha talabga mosini top'),
        const Text('A: 2 soat, balandlik 6 cm\nB: 3 soat, balandlik 8 cm'),
        SwitchListTile(
          title: Text('Kamida $minimumHours soat ishlasin'),
          value: minimumHours == 3,
          onChanged: (v) => setState(() => minimumHours = v ? 3 : 2),
        ),
        SwitchListTile(
          title: Text('Balandlik ko‘pi bilan $maximumHeight cm'),
          value: maximumHeight == 9,
          onChanged: (v) => setState(() => maximumHeight = v ? 9 : 7),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            'A: ${a ? 'mos' : 'mos emas'}; B: ${b ? 'mos' : 'mos emas'}',
            key: const ValueKey('story-criteria-result'),
          ),
        ),
        const Text(
          'Vaqt vaqt bilan, balandlik balandlik bilan taqqoslanadi. Ikkala talab ham bajarilsin.',
        ),
        if (!a && !b)
          const Text('Hozir ikkala talabni birga bajaradigan model yo‘q.'),
        if (a && b)
          const Text(
            'Ikkalasi ham mos. Yagona g‘olibni ajratadigan qo‘shimcha qoida berilmagan.',
          ),
      ]);
    } else if (widget.mode == 'problem_arrow_chain') {
      const values = [8, 12, 18, 28];
      const additions = [4, 6, 10];
      children.addAll([
        const Text('Har strelka hozirgi natijani o‘zgartiradi'),
        const Text('Boshlanish 8; strelkalar +4, +6, +10'),
        Text(
          '${values[step]}',
          key: const ValueKey('story-chain-current'),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        for (var i = 0; i < step; i++)
          Text('${values[i]} + ${additions[i]} = ${values[i + 1]}'),
        FilledButton(
          onPressed: step < 3 ? () => setState(() => step++) : null,
          child: Text(step < 3 ? 'Keyingi +${additions[step]}' : 'Yo‘l tugadi'),
        ),
        OutlinedButton(
          onPressed: step == 0 ? null : () => setState(() => step = 0),
          child: const Text('Boshidan ko‘rish'),
        ),
        if (step > 1)
          const Text('Yana 8 ga qaytmadik; oldingi natijadan davom etdik.'),
      ]);
    } else if (widget.mode == 'problem_inverse_table') {
      const totals = [35, 48, 27], knowns = [12, 18, 27], answers = [23, 30, 0];
      final total = totals[selected],
          part = knowns[selected],
          answer = answers[selected];
      children.addAll([
        const Text('Bitta ustun — bitta butun va uning qismlari'),
        choice(['1-ustun', '2-ustun', '3-ustun']),
        Text(
          selected == 1 ? '18 + ? = 48' : '? + $part = $total',
          key: const ValueKey('story-table-missing'),
        ),
        FilledButton(
          onPressed: () => setState(() => totalsSeen.add(selected)),
          child: const Text('Noma’lumni ochish'),
        ),
        if (totalsSeen.contains(selected)) ...[
          Text(
            '$total − $part = $answer',
            key: const ValueKey('story-table-inverse'),
          ),
          Text(selected == 1 ? '18 + 30 = 48' : '$answer + $part = $total'),
          if (answer == 0)
            const Text(
              'Nol ham tekshiruvdan o‘tadi: ma’lum qism butunning o‘ziga teng.',
            ),
        ],
        const Text('Boshqa ustunning soni bu shartga qo‘shilmaydi.'),
      ]);
    } else if (widget.mode == 'problem_representations') {
      children.addAll([
        const Text('Ayni shartni boshqa ko‘rinishda o‘qi'),
        choice(['Matn', 'Qisqa yozuv', 'Sxema', 'Belgili rasm']),
        if (selected == 0)
          const Text(
            'Ilmo 13 ta kartani ko‘rdi, yana 24 ta qoldi. Jami nechta karta bor?',
          ),
        if (selected == 1) const Text('Ko‘rdi —13 ta\nQoldi —24 ta\nJami —?'),
        if (selected == 2) ...[
          const Text('Butun?; qismlar 13 va 24'),
          Semantics(
            label: 'Butun noma’lum, qismlar 13 va 24',
            child: const ExcludeSemantics(
              child: SizedBox(
                height: 32,
                child: CustomPaint(painter: _ProblemBarPainter(13 / 37)),
              ),
            ),
          ),
          const Text('13 + 24 = 37'),
        ],
        if (selected == 3) ...[
          const Text(
            'Kalit:har bir o‘nlik yorlig‘i 10 ta, har nuqta 1 ta karta.',
          ),
          labelledGroups(13),
          labelledGroups(24),
        ],
        const Text(
          'Ko‘rinish o‘zgardi, lekin guruhlar yana ko‘paymadi. Jami 37 ta karta.',
        ),
      ]);
    } else {
      const a = [4, 5, 3], b = [3, 4, 4];
      final labels = ['Bosqich', 'A', 'B'];
      Widget cell(String text) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, textAlign: TextAlign.center),
      );
      children.addAll([
        const Text('Har ustun — bitta ishtirokchi'),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
          },
          border: TableBorder.all(color: mathIndigo),
          children: [
            TableRow(children: [for (final label in labels) cell(label)]),
            for (var i = 0; i < 3; i++)
              TableRow(
                children: [cell('${i + 1}'), cell('${a[i]}'), cell('${b[i]}')],
              ),
            TableRow(
              children: [
                cell('Jami'),
                cell(totalsSeen.contains(0) ? '12' : '?'),
                cell(totalsSeen.contains(1) ? '11' : '?'),
              ],
            ),
          ],
        ),
        choice(['A ustuni', 'B ustuni']),
        FilledButton(
          onPressed: () => setState(() => totalsSeen.add(selected)),
          child: const Text('Ustun jamini ochish'),
        ),
        if (totalsSeen.contains(selected))
          Semantics(
            liveRegion: true,
            child: Text(
              selected == 0 ? 'A:4 + 5 + 3 = 12' : 'B:3 + 4 + 4 = 11',
              key: const ValueKey('story-table-total'),
            ),
          ),
        if (totalsSeen.length == 2)
          const Text('12 > 11. Eng katta jami qoidasiga ko‘ra A oldinda.'),
        const Text('Har bir ustunda uch bosqichning natijasini jamla.'),
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

class _ProblemBarPainter extends CustomPainter {
  final double proportion;
  const _ProblemBarPainter(this.proportion);
  @override
  void paint(Canvas canvas, Size size) {
    final split = size.width * proportion;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, split, size.height),
      Paint()..color = mathTurquoise,
    );
    canvas.drawRect(
      Rect.fromLTWH(split, 0, size.width - split, size.height),
      Paint()..color = mathYellow,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(split, 0),
      Offset(split, size.height),
      Paint()
        ..color = mathIndigo
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ProblemBarPainter old) => old.proportion != proportion;
}
