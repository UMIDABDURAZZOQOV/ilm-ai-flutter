part of 'math_models.dart';

/// The supplied book's canonical1–100 teaching table, not an answer grader.
String mathRoman1to100(int value) {
  if (value < 1 || value > 100) {
    throw RangeError.range(value, 1, 100, 'value');
  }
  var remaining = value;
  final result = StringBuffer();
  for (final pair in [
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ]) {
    while (remaining >= pair.$1) {
      result.write(pair.$2);
      remaining -= pair.$1;
    }
  }
  return result.toString();
}

class _EquationNotationExplorer extends StatefulWidget {
  final String mode;
  const _EquationNotationExplorer({required this.mode});
  @override
  State<_EquationNotationExplorer> createState() =>
      _EquationNotationExplorerState();
}

class _EquationNotationExplorerState extends State<_EquationNotationExplorer> {
  int roman = 43, equation = 0, guess = 12, stepEquation = 0, step = 0;
  @override
  void didUpdateWidget(_EquationNotationExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      roman = 43;
      equation = 0;
      guess = 12;
      stepEquation = 0;
      step = 0;
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
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (widget.mode == 'notation_roman_100') {
      final tens = roman ~/ 10 * 10, ones = roman % 10;
      rows.addAll([
        const Text(
          'Manba jadvalidagi I, V, X, L, C belgilari va IV/IX/XL/XC tartibi. Sonni 1–100 orasida tanlang.',
        ),
        slider('roman-number', roman, 1, 100, 'Arab soni', (v) => roman = v),
        Semantics(
          liveRegion: true,
          label: '$roman sonining rim yozuvi ${mathRoman1to100(roman)}',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              mathRoman1to100(roman),
              key: const ValueKey('roman-result'),
              style: const TextStyle(
                fontSize: 32,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Text('$roman = $tens + $ones'),
        Text(
          'O‘nlik yozuvi: ${tens == 0 ? 'alohida o‘nlik yo‘q' : mathRoman1to100(tens)}; birlik yozuvi: ${ones == 0 ? 'qoldiq 0, belgi qo‘shilmaydi' : mathRoman1to100(ones)}',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            Chip(label: Text('I = 1')),
            Chip(label: Text('V = 5')),
            Chip(label: Text('X = 10')),
            Chip(label: Text('L = 50')),
            Chip(label: Text('C = 100')),
          ],
        ),
        const Text(
          'Bu mashq jadvaldagi tartibli yozuvni o‘rgatadi. Sonli qiymat so‘ralganmi yoki rim yozuvimi — savolni o‘qing.',
        ),
      ]);
    } else if (widget.mode == 'equation_unknown_component') {
      const labels = ['x + 7 = 19', '26 − x = 10', 'x − 8 = 13', '9 + x = 24'];
      final min = equation == 2 ? 8 : 0, max = equation == 1 ? 26 : 40;
      final left = switch (equation) {
        0 => guess + 7,
        1 => 26 - guess,
        2 => guess - 8,
        _ => 9 + guess,
      };
      final right = [19, 10, 13, 24][equation];
      final role = [
        'qo‘shiluvchi',
        'ayriluvchi',
        'kamayuvchi',
        'qo‘shiluvchi',
      ][equation];
      rows.addAll([
        const Text(
          'Tenglamani tanlang. Noma’lum butunmi yoki qismmi aniqlab, x uchun sonni sinang. Bu matematik taxmin; jismning haqiqiy massasini o‘zgartirish emas.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < labels.length; i++)
              ChoiceChip(
                label: Text(labels[i]),
                selected: equation == i,
                onSelected: (_) => setState(() {
                  equation = i;
                  guess = guess.clamp(i == 2 ? 8 : 0, i == 1 ? 26 : 40).toInt();
                }),
              ),
          ],
        ),
        Text('Noma’lum — $role. Bu mashqda x $min–$max oralig‘ida.'),
        slider(
          'equation-guess',
          guess,
          min,
          max,
          'x taxmini',
          (v) => guess = v,
        ),
        Text(switch (equation) {
          0 => '$guess + 7 = $left',
          1 => '26 − $guess = $left',
          2 => '$guess − 8 = $left',
          _ => '9 + $guess = $left',
        }),
        live('Chap: $left; o‘ng: $right', 'equation-sides'),
        Text(
          left == right
              ? 'Nomzod asl tenglikka mos.'
              : 'Ikki qiymat teng emas; noma’lumning rolini qayta tekshiring.',
        ),
        const Text(
          'Topilgan son asl tenglamaga qayta qo‘yiladi. Qism bilan qoldiqni yoki noma’lum butunni aralashtirmang.',
        ),
      ]);
    } else {
      const labels = ['x + 8 = 23', '31 − x = 12', 'x − 6 = 14'];
      final solution = [15, 19, 20][stepEquation];
      final method = [
        [
          'Tenglama: x + 8 = 23',
          'Noma’lum x — qism, butun 23',
          'Mos amal: 23 − 8',
          'Hisob: 23 − 8 = 15',
          'Qiymat: x = 15',
          'Tekshiruv: 15 + 8 = 23',
        ],
        [
          'Tenglama: 31 − x = 12',
          'Noma’lum x — olingan qism',
          'Mos amal: 31 − 12',
          'Hisob: 31 − 12 = 19',
          'Qiymat: x = 19',
          'Tekshiruv: 31 − 19 = 12',
        ],
        [
          'Tenglama: x − 6 = 14',
          'Noma’lum x — butun',
          'Mos amal: 14 + 6',
          'Hisob: 14 + 6 = 20',
          'Qiymat: x = 20',
          'Tekshiruv: 20 − 6 = 14',
        ],
      ][stepEquation];
      rows.addAll([
        const Text(
          'Darsdagi olti qadamni ketma-ket ko‘ramiz. Asosli boshqa yo‘llar ham bo‘lishi mumkin; bu yerda aynan shu qo‘llanma tartibi o‘rganiladi.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < labels.length; i++)
              ChoiceChip(
                label: Text(labels[i]),
                selected: stepEquation == i,
                onSelected: (_) => setState(() {
                  stepEquation = i;
                  step = 0;
                }),
              ),
          ],
        ),
        live('Qadam: ${step + 1} / 6', 'equation-step'),
        for (var i = 0; i <= step; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('${i + 1}. ${method[i]}'),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const ValueKey('equation-next-step'),
              onPressed: step < 5 ? () => setState(() => step++) : null,
              child: const Text('Keyingi qadam'),
            ),
            OutlinedButton(
              onPressed: () => setState(() => step = 0),
              child: const Text('Boshidan ko‘rish'),
            ),
          ],
        ),
        if (step == 5)
          Text(
            'x = $solution asl tenglamada tekshirildi. Bu yo‘l-yo‘riqli mashq; dars savollariga javob alohida yuboriladi.',
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
