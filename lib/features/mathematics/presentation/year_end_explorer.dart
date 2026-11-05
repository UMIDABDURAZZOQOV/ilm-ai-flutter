part of 'math_models.dart';

class _YearEndExplorer extends StatefulWidget {
  final String mode;
  const _YearEndExplorer({required this.mode});
  @override
  State<_YearEndExplorer> createState() => _YearEndExplorerState();
}

class _YearEndExplorerState extends State<_YearEndExplorer> {
  int candidate = 17,
      equation = 0,
      a = 8,
      b = 13,
      initial = 24,
      removed = 7,
      hidden = 0,
      phrase = 0,
      selected = 0,
      ac = 3,
      cd = 4,
      db = 5;
  bool allPairs = false;
  final ordered = <int>[];
  @override
  void didUpdateWidget(_YearEndExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      candidate = 17;
      equation = 0;
      a = 8;
      b = 13;
      initial = 24;
      removed = 7;
      hidden = 0;
      phrase = 0;
      selected = 0;
      ac = 3;
      cd = 4;
      db = 5;
      allPairs = false;
      ordered.clear();
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
  Widget chips(List<String> labels, int value, ValueChanged<int> change) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < labels.length; i++)
            ChoiceChip(
              label: Text(labels[i]),
              selected: value == i,
              onSelected: (_) => setState(() => change(i)),
            ),
        ],
      );
  Widget bar(List<int> parts, List<String> labels) => Semantics(
    label: [
      for (var i = 0; i < parts.length; i++) '${labels[i]} ${parts[i]}',
    ].join('; '),
    child: ExcludeSemantics(
      child: SizedBox(
        height: 90,
        width: double.infinity,
        child: CustomPaint(painter: _YearEndPartsPainter(parts, labels)),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    switch (widget.mode) {
      case 'equation_root_check':
        final left = equation == 0 ? candidate + 9 : 36 - candidate,
            right = equation == 0 ? 26 : 17;
        rows.addAll([
          const Text(
            'Tenglamaning ildizi — asl tenglikni rost qiladigan son. Avval nomzodni tanlang, keyin ikkala tomonning qiymatini solishtiring.',
          ),
          chips(['x + 9 = 26', '36 − x = 17'], equation, (v) => equation = v),
          slider(
            'root-candidate',
            candidate,
            0,
            36,
            'x nomzodi',
            (v) => candidate = v,
          ),
          bar([left, right], ['Chap', 'O‘ng']),
          live('Chap: $left; o‘ng: $right', 'root-sides'),
          live(
            left == right
                ? 'Bu son shu tenglamaning ildizi.'
                : 'Nomzod tenglikni rost qilmadi.',
            'root-result',
          ),
          const Text(
            'Nomzodni sinash matematik tekshiruv; haqiqiy buyum massasini o‘zgartirish emas.',
          ),
        ]);
      case 'inverse_story_family':
        final total = a + b;
        rows.addAll([
          const Text(
            'Faqat ikki alohida guruh; har bir belgi bir guruhda va barcha belgilar shu ikki guruhga kiradi. Slayderlar original modelning shartini o‘zgartiradi.',
          ),
          slider('family-a', a, 0, 20, 'Birinchi qism', (v) => a = v),
          slider('family-b', b, 0, 20, 'Ikkinchi qism', (v) => b = v),
          bar([a, b], ['I', 'II']),
          live('Butun: $total', 'family-total'),
          chips(
            [
              'Butun noma’lum',
              'Birinchi qism noma’lum',
              'Ikkinchi qism noma’lum',
            ],
            hidden,
            (v) => hidden = v,
          ),
          live(
            hidden == 0
                ? '$a + $b = x; x = $total'
                : hidden == 1
                ? 'x + $b = $total; x = $a'
                : '$a + x = $total; x = $b',
            'family-equation',
          ),
          Text(
            '$a + $b = $total\n$b + $a = $total\n$total − $a = $b\n$total − $b = $a',
          ),
          const Text(
            'Bu yo‘l-yo‘riqli modelda barcha qiymatlar ko‘rinadi. Darsning mustaqil savollari alohida tekshiriladi.',
          ),
        ]);
      case 'equation_initial_remaining':
        final remaining = initial - removed;
        rows.addAll([
          const Text(
            'Dastlabki belgilardan bir qismi olindi, boshqa o‘zgarish yo‘q. Olingan bilan qolgan qismlar birgalikda dastlabki butunni beradi.',
          ),
          slider('initial-count', initial, 0, 30, 'Dastlab', (v) {
            initial = v;
            removed = removed.clamp(0, v);
          }),
          if (initial > 0)
            slider(
              'removed-count',
              removed,
              0,
              initial,
              'Olindi',
              (v) => removed = v,
            ),
          bar([removed, remaining], ['Olindi', 'Qoldi']),
          live(
            'Dastlab: $initial; olindi: $removed; qoldi: $remaining',
            'remaining-counts',
          ),
          chips(
            ['Qoldiq noma’lum', 'Olingan noma’lum', 'Dastlabki noma’lum'],
            hidden,
            (v) => hidden = v,
          ),
          live(
            hidden == 0
                ? '$initial − $removed = x; x = $remaining'
                : hidden == 1
                ? '$initial − x = $remaining; x = $removed'
                : 'x − $removed = $remaining; x = $initial',
            'remaining-equation',
          ),
          Text('Tekshiruv: $removed + $remaining = $initial'),
          const Text(
            'Nol butunda faqat 0 olinishi mumkin; manfiy qoldiq chiqarilmaydi.',
          ),
        ]);
      case 'review_sort_quantity':
        const expressions = ['35 − 18', '8 + 15', '42 − 13', '16 + 20'],
            values = [17, 23, 29, 36];
        rows.addAll([
          const Text(
            'Avval har bir ifodani hisoblang. Keyin natijalar o‘sishi bo‘yicha tugmalarni bosing. Bosilgan ifoda qayta tanlanmaydi.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in [2, 0, 3, 1])
                ActionChip(
                  key: ValueKey('review-sort-$i'),
                  label: Text(expressions[i]),
                  onPressed: ordered.contains(i)
                      ? null
                      : () => setState(() => ordered.add(i)),
                ),
            ],
          ),
          live(
            ordered.isEmpty
                ? 'Hali tartib tanlanmadi.'
                : ordered
                      .map((i) => '${expressions[i]} = ${values[i]}')
                      .join(' → '),
            'review-order',
          ),
          if (ordered.length == 4)
            Text(
              List.generate(
                    3,
                    (i) => values[ordered[i]] < values[ordered[i + 1]],
                  ).every((v) => v)
                  ? 'Natijalar o‘sish tartibida.'
                  : 'Natijalar hali o‘sish tartibida emas.',
            ),
          OutlinedButton(
            key: const ValueKey('review-sort-reset'),
            onPressed: () => setState(() => ordered.clear()),
            child: const Text('Qayta tartiblash'),
          ),
          const Divider(),
          const Text(
            'Bir xil uzunlik: 1 dm = 10 cm. Massa: tarozi va kg. Suyuqlik hajmi: l. Turli kattaliklarni bir birlik deb qo‘shmang.',
          ),
        ]);
      case 'review_word_expression':
        const phrases = [
              'Sondan yig‘indini ayirish',
              'Sondan ayirmani ayirish',
              'Yig‘indidan sonni ayirish',
              'Ayirmaga son qo‘shish',
            ],
            expressions = [
              'k − (v + w)',
              'k − (v − w)',
              '(k + v) − w',
              '(k − v) + w',
            ],
            values = [15, 29, 31, 29];
        rows.addAll([
          const Text(
            'Berilgan qiymatlar: k = 30, v = 8, w = 7. Avval gapning ma’nosiga mos ifodani tanlang. Bir xil natija chiqishi ikki xil ifoda doim bir xil degani emas.',
          ),
          chips(phrases, phrase, (v) => phrase = v),
          chips(expressions, selected, (v) => selected = v),
          live(
            selected == phrase
                ? 'Yozuv gapga mos.'
                : 'Ichki va tashqi amalni qayta tekshiring.',
            'phrase-match',
          ),
          Text('Tanlangan ifoda: ${expressions[selected]}'),
          live('Ushbu qiymatlarda natija: ${values[selected]}', 'phrase-value'),
          const Text(
            'Qavs ichidagi amal avval bajariladi. Savolda yig‘indimi yoki ayirmami so‘ralganini ajrating.',
          ),
        ]);
      case 'review_segment_parts':
        final whole = ac + cd + db, ad = ac + cd, cb = cd + db;
        rows.addAll([
          const Text(
            'To‘g‘ri kesmada to‘rtta turli nuqta aynan A–C–D–B tartibida. Har bir bo‘lak musbat. Yorliqlar sonli model; ekran santimetr sifatida o‘lchanmaydi.',
          ),
          slider('segment-ac', ac, 1, 10, 'AC, cm', (v) => ac = v),
          slider('segment-cd', cd, 1, 10, 'CD, cm', (v) => cd = v),
          slider('segment-db', db, 1, 10, 'DB, cm', (v) => db = v),
          bar([ac, cd, db], ['AC', 'CD', 'DB']),
          live('AB = $ac + $cd + $db = $whole cm', 'segment-whole'),
          Text(
            'AD = $ad cm; CB = $cb cm.\nAC + CB = ${ac + cb} cm; AD + DB = ${ad + db} cm.',
          ),
          Text('AD + CB = ${ad + cb} cm; bunda CD $cd cm ikki marta sanaladi.'),
          SwitchListTile(
            key: const ValueKey('segment-all-pairs'),
            title: const Text('Har bir juft uchdan barcha kesmalar'),
            value: allPairs,
            onChanged: (v) => setState(() => allPairs = v),
          ),
          live(
            allPairs
                ? 'Barcha kesmalar: AC, AD, AB, CD, CB, DB — 6 ta.'
                : 'Faqat qo‘shni bo‘laklar: AC, CD, DB — 3 ta.',
            'segment-count',
          ),
          const Text(
            'Yo‘nalishni almashtirish yangi kesma bermaydi: AB va BA ayni kesma.',
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

class _YearEndPartsPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  _YearEndPartsPainter(this.values, this.labels);
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()
          ..color = mathIndigo
          ..strokeWidth = 2,
      );
      return;
    }
    var x = 0.0;
    for (var i = 0; i < values.length; i++) {
      final width = size.width * values[i] / total;
      if (width <= 0) continue;
      canvas.drawRect(
        Rect.fromLTWH(x, 20, width, 35),
        Paint()..color = [mathYellow, mathTurquoise, mathIndigo][i % 3],
      );
      canvas.drawRect(
        Rect.fromLTWH(x, 20, width, 35),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      if (width >= 30) {
        final p = TextPainter(
          text: TextSpan(
            text: '${values[i]}',
            style: TextStyle(
              color: i % 3 == 2 ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width);
        p.paint(canvas, Offset(x + (width - p.width) / 2, 28));
        p.dispose();
      }
      x += width;
    }
  }

  @override
  bool shouldRepaint(_YearEndPartsPainter old) =>
      old.values.toString() != values.toString() ||
      old.labels.toString() != labels.toString();
}
