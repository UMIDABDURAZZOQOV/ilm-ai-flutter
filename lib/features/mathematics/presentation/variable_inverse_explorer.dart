part of 'math_models.dart';

class _ThreeDigitVariableExplorer extends StatefulWidget {
  const _ThreeDigitVariableExplorer();
  @override
  State<_ThreeDigitVariableExplorer> createState() =>
      _ThreeDigitVariableState();
}

class _ThreeDigitVariableState extends State<_ThreeDigitVariableExplorer> {
  int x = 240, t = 50, y = 30;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Harf o‘rniga qiymat qo‘ying'),
          const Text(
            'Ifoda: x − t + y. Bir mashqda har bir harfning qiymati bir xil qoladi.',
          ),
          for (final name in ['x', 't', 'y']) ...[
            Text('$name = ${{'x': x, 't': t, 'y': y}[name]}'),
            Slider(
              key: ValueKey('variable-$name'),
              value: ({'x': x, 't': t, 'y': y}[name]!).toDouble(),
              min: name == 'x' ? 200 : 0,
              max: name == 'x'
                  ? 600
                  : name == 't'
                  ? 200
                  : 100,
              divisions: name == 'x'
                  ? 400
                  : name == 't'
                  ? 200
                  : 100,
              semanticFormatterCallback: (v) => '$name ${v.round()}',
              onChanged: (v) => setState(() {
                if (name == 'x') {
                  x = v.round();
                } else if (name == 't') {
                  t = v.round();
                } else {
                  y = v.round();
                }
              }),
            ),
          ],
          Semantics(
            liveRegion: true,
            child: Text(
              '$x − $t + $y = ${x - t + y}',
              key: const ValueKey('variable-result'),
            ),
          ),
          Text('Avval $x − $t = ${x - t}; so‘ng ${x - t} + $y = ${x - t + y}.'),
          const Text(
            'x + x da bitta turli o‘zgaruvchi ikki marta yozilgan. Namunani tekshirib, keyin mustaqil mashqqa o‘ting.',
          ),
        ],
      ),
    ),
  );
}

class _ThreeDigitEquationExplorer extends StatefulWidget {
  const _ThreeDigitEquationExplorer();
  @override
  State<_ThreeDigitEquationExplorer> createState() =>
      _ThreeDigitEquationState();
}

class _ThreeDigitEquationState extends State<_ThreeDigitEquationExplorer> {
  int example = 0, guess = 0;
  bool shown = false;
  @override
  Widget build(BuildContext context) {
    final equations = [
      'x + 145 = 700',
      '600 − x = 275',
      '430 − x = 430',
      '180 + (x + 145) = 700',
    ];
    final left = [
          guess + 145,
          600 - guess,
          430 - guess,
          180 + guess + 145,
        ][example],
        right = [700, 275, 430, 700][example];
    final roots = [700 - 145, 600 - 275, 0, 700 - 180 - 145];
    final steps = [
      'x = 700 − 145 = 555',
      'x = 600 − 275 = 325',
      'x = 0: 430 − 0 = 430',
      'x + 145 = 520; x = 520 − 145 = 375',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ildiz tenglikni to‘g‘ri qiladi'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < 4; i++)
                  ChoiceChip(
                    key: ValueKey('equation-example-$i'),
                    label: Text(equations[i]),
                    selected: example == i,
                    onSelected: (_) => setState(() {
                      example = i;
                      guess = 0;
                      shown = false;
                    }),
                  ),
              ],
            ),
            Text('Sinab ko‘ring: x = $guess'),
            Slider(
              key: const ValueKey('equation-guess'),
              value: guess.toDouble(),
              min: 0,
              max: 600,
              divisions: 600,
              semanticFormatterCallback: (v) => 'x ${v.round()}',
              onChanged: (v) => setState(() => guess = v.round()),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                'Chap: $left; o‘ng: $right. ${left == right ? 'Tenglik to‘g‘ri.' : 'Hozir teng emas.'}',
                key: const ValueKey('equation-check'),
              ),
            ),
            OutlinedButton(
              key: const ValueKey('equation-show'),
              onPressed: () => setState(() => shown = true),
              child: const Text('Yechish yo‘lini ochish'),
            ),
            if (shown) ...[
              Text(steps[example], key: const ValueKey('equation-root')),
              Text(
                'Ildiz ${roots[example]}. Uni o‘rniga qo‘yib ikkala tomonni tekshiring.',
              ),
            ],
            const Text(
              'Noma’lumning qiymati 0 ham bo‘lishi mumkin. Bu o‘rganish namunasi.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InverseOperationsExplorer extends StatefulWidget {
  const _InverseOperationsExplorer();
  @override
  State<_InverseOperationsExplorer> createState() => _InverseOperationsState();
}

class _InverseOperationsState extends State<_InverseOperationsExplorer> {
  int mode = 0, a = 240, delta = 57;
  bool back = false, reversed = false, shapeReversed = false;
  String original = '400';
  @override
  Widget build(BuildContext context) {
    final representation = reversed
        ? original.split('').reversed.join()
        : original;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Boshlanishga qaytadigan amal'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < 3; i++)
                  ChoiceChip(
                    key: ValueKey('inverse-mode-$i'),
                    label: Text(
                      [
                        'Qo‘shish va ayirish',
                        'Uch o‘rinli yozuv',
                        'Shakllar tartibi',
                      ][i],
                    ),
                    selected: mode == i,
                    onSelected: (_) => setState(() => mode = i),
                  ),
              ],
            ),
            if (mode == 0) ...[
              Text('Boshlanish: $a; qo‘shiladigan son: $delta'),
              Slider(
                key: const ValueKey('inverse-start'),
                value: a.toDouble(),
                min: 200,
                max: 500,
                divisions: 300,
                onChanged: (v) => setState(() => a = v.round()),
              ),
              Slider(
                key: const ValueKey('inverse-delta'),
                value: delta.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (v) => setState(() => delta = v.round()),
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  back
                      ? '$a + $delta − $delta = $a'
                      : '$a + $delta = ${a + delta}',
                  key: const ValueKey('inverse-number'),
                ),
              ),
              FilledButton(
                key: const ValueKey('inverse-return'),
                onPressed: () => setState(() => back = !back),
                child: Text(
                  back ? 'Oldinga ko‘rish' : 'Teskari amalni bajarish',
                ),
              ),
            ] else if (mode == 1) ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final n in ['276', '400', '120'])
                    ChoiceChip(
                      key: ValueKey('inverse-digits-$n'),
                      label: Text(n),
                      selected: original == n,
                      onSelected: (_) => setState(() {
                        original = n;
                        reversed = false;
                      }),
                    ),
                ],
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Uch o‘rinli yozuv: $representation',
                  key: const ValueKey('inverse-digits'),
                ),
              ),
              Text(
                'Sonli qiymat: ${int.parse(representation)}. Bu yerda barcha 3 katak saqlanadi.',
              ),
              FilledButton(
                key: const ValueKey('inverse-reverse'),
                onPressed: () => setState(() => reversed = !reversed),
                child: const Text('Uch katakni teskari yozish'),
              ),
              const Text(
                '004 ni shunchaki 4 deb qisqartirib, kataklar sonini unutsak, oldingi 400 ni yagona tarzda tiklay olmaymiz.',
              ),
            ] else ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  shapeReversed
                      ? 'Kvadrat → Uchburchak → Doira'
                      : 'Doira → Uchburchak → Kvadrat',
                  key: const ValueKey('inverse-shapes'),
                ),
              ),
              Wrap(
                spacing: 16,
                children: [
                  for (final i in (shapeReversed ? [2, 1, 0] : [0, 1, 2]))
                    Icon(
                      [Icons.circle, Icons.change_history, Icons.square][i],
                      color: [mathIndigo, mathYellow, mathTurquoise][i],
                      size: 32,
                    ),
                ],
              ),
              FilledButton(
                key: const ValueKey('inverse-shape-reverse'),
                onPressed: () => setState(() => shapeReversed = !shapeReversed),
                child: const Text('Tartibni teskari qilish'),
              ),
            ],
            const Text(
              'Faqat aniq berilgan o‘zgarishni bajaring. Ma’lumot yo‘qolsa, uni o‘zidan-o‘zi qayta topib bo‘lmaydi.',
            ),
          ],
        ),
      ),
    );
  }
}
