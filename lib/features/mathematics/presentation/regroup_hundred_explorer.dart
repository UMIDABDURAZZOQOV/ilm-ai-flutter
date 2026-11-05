part of 'math_models.dart';

class _RegroupHundredExplorer extends StatefulWidget {
  final String mode;
  const _RegroupHundredExplorer({required this.mode});
  @override
  State<_RegroupHundredExplorer> createState() =>
      _RegroupHundredExplorerState();
}

class _RegroupHundredExplorerState extends State<_RegroupHundredExplorer> {
  int sample = 0, step = 0;
  @override
  void didUpdateWidget(_RegroupHundredExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      sample = 0;
      step = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtract = widget.mode.endsWith('subtraction');
    final nonroundTwo =
        widget.mode == 'two_digit_nonround_two_digit_subtraction';
    final borrowTwo =
        widget.mode == 'two_digit_regroup_subtraction' || nonroundTwo;
    final nonround =
        widget.mode == 'two_digit_nonround_subtraction' || nonroundTwo;
    final carryRemainder = widget.mode == 'two_digit_carry_remainder_addition';
    final cross = widget.mode == 'two_digit_cross_tens_addition';
    final two = widget.mode == 'two_digit_regroup_addition';
    final pairs = subtract
        ? (nonroundTwo
              ? const [(52, 27), (64, 38), (83, 46)]
              : nonround
              ? const [(43, 7), (52, 8), (74, 9)]
              : borrowTwo
              ? const [(50, 23), (70, 26), (90, 42)]
              : const [(40, 3), (60, 8), (90, 4)])
        : carryRemainder
        ? const [(46, 28), (57, 26), (47, 28), (56, 27)]
        : cross
        ? const [(35, 7), (48, 6), (67, 8), (79, 9)]
        : two
        ? const [(28, 32), (46, 24), (74, 26)]
        : const [(24, 6), (37, 3), (56, 4), (82, 8)];
    final (a, b) = pairs[sample];
    final result = subtract ? a - b : a + b;
    final rawTens = subtract ? a ~/ 10 : a ~/ 10 + b ~/ 10;
    final rawOnes = subtract ? a % 10 : a % 10 + b % 10;
    final tens = subtract
        ? (step == 0
              ? rawTens
              : step == 1
              ? rawTens - 1
              : rawTens - 1 - b ~/ 10)
        : (step < 2 ? rawTens : rawTens + 1);
    final ones = subtract
        ? (step == 0
              ? rawOnes
              : step == 1
              ? rawOnes + 10
              : rawOnes + 10 - b % 10)
        : (step < 2 ? rawOnes : rawOnes - 10);
    final expressions = subtract
        ? [
            '$a − $b',
            '$a = ${(rawTens - 1) * 10} + ${rawOnes + 10}',
            borrowTwo
                ? '${(rawTens - 1) * 10} − ${b ~/ 10 * 10} = ${(rawTens - 1 - b ~/ 10) * 10}; ${rawOnes + 10} − ${b % 10} = ${rawOnes + 10 - b % 10}'
                : '${rawOnes + 10} − $b = ${rawOnes + 10 - b}',
            '${(rawTens - 1 - b ~/ 10) * 10} + ${rawOnes + 10 - b % 10} = $result',
          ]
        : [
            '$a + $b',
            '${a % 10} + ${b % 10} = $rawOnes birlik',
            '10 birlik = 1 o‘nlik',
            '${(rawTens + 1) * 10} + ${rawOnes - 10} = $result',
          ];
    final why = subtract
        ? [
            nonround
                ? 'Avvalgi birliklar ayirishga yetmaydi. Bitta o‘nlikni ochib, eski birliklar bilan birlashtiramiz.'
                : 'Boshlang‘ich son yaxlit o‘nlik. Ayirish uchun alohida birliklarni ochamiz.',
            'Bitta o‘nlikni 10 birlikka almashtirdik. Avvalgi $rawOnes birlik ham saqlandi. Jami miqdor $a bo‘lib qoldi.',
            borrowTwo
                ? '${b ~/ 10} o‘nlik va ${b % 10} birlik olib tashlandi. Barcha olingan qismlar bir martadan hisoblandi.'
                : '$b birlik olib tashlandi; ${rawOnes + 10 - b} birlik qoldi. Boshqa o‘nliklar saqlandi.',
            'O‘nlik va qolgan birlikni jamladik. Tekshiruv: $result + $b = $a.',
          ]
        : [
            'Bu modellarda birliklar yig‘indisi kamida 10. Qo‘shiluvchilarni xona qiymatlariga ajratamiz.',
            'O‘nliklar alohida, birliklar alohida jamlandi. Har bir qism bir marta qatnashadi.',
            'Ayni 10 birlik 1 yangi o‘nlikka aylandi. Bu jami miqdorni o‘zgartirmaydi; qolgan ${rawOnes - 10} birlik ham saqlanadi.',
            result == 100
                ? '10 o‘nlik = 100. Birliklar qoldig‘i 0.'
                : '${rawTens + 1} o‘nlik va ${rawOnes - 10} birlik = $result.',
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              subtract
                  ? 'Bir o‘nlikni birliklarga ochamiz'
                  : 'Birliklardan yangi o‘nlik',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < pairs.length; i++)
                  ChoiceChip(
                    label: Text(
                      '${pairs[i].$1} ${subtract ? '−' : '+'} ${pairs[i].$2}',
                    ),
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
                key: const ValueKey('regroup-expression'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text('Qadam: ${step + 1} / 4', key: const ValueKey('regroup-step')),
            Text(why[step]),
            Semantics(
              label:
                  '$tens o‘nlik va $ones birlik; model qiymati ${tens * 10 + ones}',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _RegroupHundredPainter(tens, ones),
                  ),
                ),
              ),
            ),
            Text(
              '$tens o‘nlik, $ones birlik',
              key: const ValueKey('regroup-counts'),
            ),
            Text(
              'Modeldagi jami: ${tens * 10 + ones}',
              key: const ValueKey('regroup-total'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('regroup-back'),
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  key: const ValueKey('regroup-next'),
                  onPressed: step == 3 ? null : () => setState(() => step++),
                  child: Text(
                    step == 1
                        ? (subtract
                              ? 'Birliklarni ayirish'
                              : 'O‘nlikka almashtirish')
                        : 'Keyingi qadam',
                  ),
                ),
              ],
            ),
            if (step == 3)
              const Text(
                'Bu yo‘l-yo‘riqli model. Mustaqil savol javobi alohida tekshiriladi.',
              ),
          ],
        ),
      ),
    );
  }
}

class _RegroupHundredPainter extends CustomPainter {
  final int tens, ones;
  _RegroupHundredPainter(this.tens, this.ones);
  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width / 11;
    for (var i = 0; i < tens; i++) {
      final rect = Rect.fromLTWH(gap * .25 + i * gap, 8, gap * .65, 80);
      canvas.drawRect(rect, Paint()..color = mathTurquoise);
      canvas.drawRect(
        rect,
        Paint()
          ..color = mathIndigo
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      for (var j = 1; j < 10; j++) {
        canvas.drawLine(
          Offset(rect.left, 8 + j * 8),
          Offset(rect.right, 8 + j * 8),
          Paint()
            ..color = mathIndigo
            ..strokeWidth = 1,
        );
      }
    }
    for (var i = 0; i < ones; i++) {
      final c = Offset(gap * .55 + (i % 10) * gap, 110 + (i ~/ 10) * 28);
      canvas.drawCircle(c, gap * .3, Paint()..color = mathYellow);
      canvas.drawCircle(
        c,
        gap * .3,
        Paint()
          ..color = mathIndigo
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_RegroupHundredPainter old) =>
      old.tens != tens || old.ones != ones;
}
