part of 'math_models.dart';

/// Original, bounded elementary models; no model grants assessment credit.
class _ReasoningLengthExplorer extends StatefulWidget {
  final String mode;
  const _ReasoningLengthExplorer({required this.mode});
  @override
  State<_ReasoningLengthExplorer> createState() =>
      _ReasoningLengthExplorerState();
}

class _ReasoningLengthExplorerState extends State<_ReasoningLengthExplorer> {
  int? missing;
  int left = 0, right = 1, change = 4, step = 0, tomorrow = 5, length = 5;
  bool more = true;
  final pairs = <String>{};
  String? note;
  @override
  void didUpdateWidget(_ReasoningLengthExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      missing = null;
      left = 0;
      right = 1;
      change = 4;
      step = 0;
      tomorrow = 5;
      length = 5;
      more = true;
      pairs.clear();
      note = null;
    }
  }

  Widget result(String text, String key) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (widget.mode == 'problem_missing_information') {
      children.addAll([
        const Text(
          'Birinchi qutida 9 ta; ikkinchi qutining soni berilmagan. Jami?',
        ),
        result(
          missing == null
              ? 'Ma’lumot yetarli emas.'
              : 'Qo‘shilgan shart: ikkinchi qutida$missing ta.',
          'reasoning-missing-condition',
        ),
        DropdownButton<int>(
          key: const ValueKey('reasoning-missing-choice'),
          value: missing,
          isExpanded: true,
          hint: const Text('Shartga son tanla'),
          items: [
            for (final n in [4, 12, 20])
              DropdownMenuItem(
                value: n,
                child: Text('Ikkinchi qutida$n ta deb belgilaymiz'),
              ),
          ],
          onChanged: (n) => setState(() => missing = n),
        ),
        if (missing != null)
          result('9 + $missing = ${9 + missing!}', 'reasoning-completed-total'),
        const Text(
          'Bu yangi tanlangan shartning javobi; eski noma’lum sonni taxmin qilmadik.',
        ),
        ExpansionTile(
          title: const Text('Yuqoridan ko‘rinish va kub soni'),
          children: [
            const Text(
              'Original model: to‘rtta joyning balandligi 2,1,1,0 kub. Yuqoridan 3 ta band joy, hammasi 4 kub.',
            ),
            Table(
              border: TableBorder.all(color: mathIndigo),
              children: [
                for (final row in [
                  [2, 1],
                  [1, 0],
                ])
                  TableRow(
                    children: [
                      for (final n in row)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('$n kub', textAlign: TextAlign.center),
                        ),
                    ],
                  ),
              ],
            ),
            const Text(
              'Bitta joyda 2 kub ustma-ust turadi. Uchta ko‘ringan joy har doim uchta kub emas.',
            ),
          ],
        ),
      ]);
    } else if (widget.mode == 'problem_unordered_pairs') {
      const names = ['A', 'B', 'C', 'D'];
      children.add(
        const Text(
          'Ikkita turli karta; tartib ahamiyatsiz. AB va BA bir tanlov.',
        ),
      );
      for (var i = 0; i < 2; i++) {
        children.add(Text(i == 0 ? 'Birinchi karta' : 'Ikkinchi karta'));
        children.add(
          DropdownButton<int>(
            key: ValueKey('reasoning-pair-$i'),
            value: i == 0 ? left : right,
            isExpanded: true,
            items: [
              for (var j = 0; j < 4; j++)
                DropdownMenuItem(value: j, child: Text(names[j])),
            ],
            onChanged: (n) {
              if (n != null) {
                setState(() {
                  if (i == 0) {
                    left = n;
                  } else {
                    right = n;
                  }
                  note = null;
                });
              }
            },
          ),
        );
      }
      children.addAll([
        FilledButton(
          onPressed: () => setState(() {
            if (left == right) {
              note = 'Ikki karta turli bo‘lsin.';
              return;
            }
            final key =
                names[math.min(left, right)] + names[math.max(left, right)];
            note = pairs.add(key)
                ? 'Yangi tanlov: $key.'
                : '$key avval bor; qayta sanalmadi.';
          }),
          child: const Text('Tanlovni qo‘shish'),
        ),
        if (note != null) Text(note!),
        result('Turli juftliklar: ${pairs.length}', 'reasoning-pair-count'),
        Wrap(
          spacing: 8,
          children: [
            for (final p in pairs.toList()..sort()) Chip(label: Text(p)),
          ],
        ),
        if (pairs.length == 6)
          const Text('AB, AC, AD, BC, BD, CD — barcha 6 tanlov.'),
      ]);
    } else if (widget.mode == 'problem_related_total') {
      final second = more ? 13 + change : 13 - change, total = 13 + second;
      final path = [
        'Birinchi 13; ikkinchi undan$change ta ${more ? 'ko‘p' : 'kam'}.',
        'Ikkinchi: 13 ${more ? '+' : '−'} $change = $second',
        'Jami: 13 + $second = $total',
      ];
      children.addAll([
        const Text('Bog‘liq qismni top, keyin ikkala qutini jamla'),
        Slider(
          key: const ValueKey('reasoning-related-change'),
          value: change.toDouble(),
          min: 0,
          max: 8,
          divisions: 8,
          semanticFormatterCallback: (n) => 'Farq ${n.round()} ta',
          onChanged: (n) => setState(() {
            change = n.round();
            step = 0;
          }),
        ),
        SwitchListTile(
          title: Text(more ? 'Ikkinchisida ko‘p' : 'Ikkinchisida kam'),
          value: more,
          onChanged: (v) => setState(() {
            more = v;
            step = 0;
          }),
        ),
        result(path[step], 'reasoning-related-step'),
        FilledButton(
          onPressed: step < 2 ? () => setState(() => step++) : null,
          child: const Text('Keyingi qadam'),
        ),
        if (step == 2) Text('Tekshir: $total − 13 = $second.'),
      ]);
    } else if (widget.mode == 'problem_weekday_reasoning') {
      const days = [
        'Dushanba',
        'Seshanba',
        'Chorshanba',
        'Payshanba',
        'Juma',
        'Shanba',
        'Yakshanba',
      ];
      children.addAll([
        const Text('Shart ertagani beradi. Avval bugun, keyin kechani top.'),
        DropdownButton<int>(
          key: const ValueKey('reasoning-tomorrow'),
          value: tomorrow,
          isExpanded: true,
          items: [
            for (var i = 0; i < 7; i++)
              DropdownMenuItem(value: i, child: Text('Ertaga ${days[i]}')),
          ],
          onChanged: (n) {
            if (n != null) {
              setState(() {
                tomorrow = n;
                step = 0;
              });
            }
          },
        ),
        result(
          step == 0
              ? 'Ertaga ${days[tomorrow]}'
              : step == 1
              ? 'Bugun ${days[(tomorrow + 6) % 7]}'
              : 'Kecha ${days[(tomorrow + 5) % 7]}',
          'reasoning-day-step',
        ),
        FilledButton(
          onPressed: step < 2 ? () => setState(() => step++) : null,
          child: const Text('Bir kun orqaga'),
        ),
        if (step == 2)
          Text(
            '${days[(tomorrow + 5) % 7]} → ${days[(tomorrow + 6) % 7]} → ${days[tomorrow]}',
          ),
        const Text(
          'Yakshanbadan keyin dushanba keladi; hafta aylanib davom etadi.',
        ),
      ]);
    } else {
      children.addAll([
        const Text('Sonli santimetr modeli: boshini 0 belgiga mosla'),
        Slider(
          key: const ValueKey('reasoning-cm-length'),
          value: length.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          semanticFormatterCallback: (n) => 'Uzunlik ${n.round()} santimetr',
          onChanged: (n) => setState(() => length = n.round()),
        ),
        Semantics(
          label:
              'Boshlanish 0 cm, oxiri$length cm; $length ta bir santimetrli oraliq',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 95,
              child: CustomPaint(
                painter: _ElementaryRulerPainter(
                  length,
                  MediaQuery.textScalerOf(context).scale(10),
                ),
              ),
            ),
          ),
        ),
        result('0 → $length cm: $length ta 1 cm oraliq', 'reasoning-cm-result'),
        Text(
          '0 dan$length gacha ${length + 1}raqamli belgi, lekin uzunlik$length cm.',
        ),
        const Text(
          'Chizma sonli model. Haqiqiy buyumni fizik chizg‘ich bilan o‘lcha.',
        ),
      ]);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in children)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
          ],
        ),
      ),
    );
  }
}

class _ElementaryRulerPainter extends CustomPainter {
  final int length;
  final double fontSize;
  const _ElementaryRulerPainter(this.length, this.fontSize);
  @override
  void paint(Canvas canvas, Size size) {
    const margin = 16.0;
    final unit = (size.width - 2 * margin) / 10;
    final ink = Paint()
      ..color = mathIndigo
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(margin, 32),
      Offset(size.width - margin, 32),
      ink,
    );
    for (var n = 0; n <= 10; n++) {
      final x = margin + unit * n;
      canvas.drawLine(Offset(x, 24), Offset(x, 44), ink);
      final text = TextPainter(
        text: TextSpan(
          text: '$n',
          style: TextStyle(color: mathIndigo, fontSize: fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset((x - text.width / 2).clamp(0, size.width - text.width), 48),
      );
    }
    canvas.drawLine(
      const Offset(margin, 12),
      Offset(margin + length * unit, 12),
      Paint()
        ..color = mathTurquoise
        ..strokeWidth = 8,
    );
    canvas.drawCircle(
      Offset(margin + length * unit, 12),
      5,
      Paint()..color = mathIndigo,
    );
  }

  @override
  bool shouldRepaint(_ElementaryRulerPainter old) =>
      old.length != length || old.fontSize != fontSize;
}
