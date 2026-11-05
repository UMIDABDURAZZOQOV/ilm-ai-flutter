part of 'math_models.dart';

/// Original place-value teaching models. Independent answers remain server graded.
class _ThreeDigitCompareExplorer extends StatefulWidget {
  final String mode;
  const _ThreeDigitCompareExplorer({required this.mode});
  @override
  State<_ThreeDigitCompareExplorer> createState() => _ThreeDigitCompareState();
}

class _ThreeDigitCompareState extends State<_ThreeDigitCompareExplorer> {
  int a = 583, b = 547;
  bool descending = false;
  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset() {
    a = widget.mode == 'compare_digit_lengths' ? 103 : 583;
    b = widget.mode == 'compare_digit_lengths' ? 98 : 547;
    descending = false;
  }

  @override
  void didUpdateWidget(_ThreeDigitCompareExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) reset();
  }

  @override
  Widget build(BuildContext context) {
    final ordering = widget.mode == 'order_three_places';
    final symbol = a == b
        ? '='
        : a < b
        ? '<'
        : '>';
    final place = a ~/ 100 != b ~/ 100
        ? 'Yuzlik'
        : a ~/ 10 % 10 != b ~/ 10 % 10
        ? 'O‘nlik'
        : a % 10 != b % 10
        ? 'Birlik'
        : 'Teng';
    final values = [308, 73, 415, 106]..sort();
    final ordered = descending ? values.reversed.toList() : values;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ordering
                  ? 'Sonlarni tartiblang'
                  : 'Birinchi farqli xonani toping',
            ),
            if (ordering) ...[
              const Text(
                'Original sonlar: 308, 73, 415, 106. Har biri aynan bir marta qatnashadi.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const ValueKey('order-ascending'),
                    label: const Text('O‘sish'),
                    selected: !descending,
                    onSelected: (_) => setState(() => descending = false),
                  ),
                  ChoiceChip(
                    key: const ValueKey('order-descending'),
                    label: const Text('Kamayish'),
                    selected: descending,
                    onSelected: (_) => setState(() => descending = true),
                  ),
                ],
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  ordered.join(descending ? ' > ' : ' < '),
                  key: const ValueKey('three-digit-order'),
                ),
              ),
              for (final n in ordered) _digitTiles(n),
              const Text(
                'Yo‘nalishni o‘zgartiring; qo‘shni sonlarning yuzlik, o‘nlik va birliklarini tekshiring.',
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final pair in [
                    [583, 547],
                    [672, 679],
                    [103, 98],
                    [704, 740],
                    [21, 210],
                    [405, 405],
                  ])
                    ActionChip(
                      key: ValueKey('compare-${pair[0]}-${pair[1]}'),
                      label: Text('${pair[0]} va ${pair[1]}'),
                      onPressed: () => setState(() {
                        a = pair[0];
                        b = pair[1];
                      }),
                    ),
                ],
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  '$a $symbol $b',
                  key: const ValueKey('three-digit-comparison'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Birinchi farq: $place',
                key: const ValueKey('comparison-place'),
              ),
              _digitTiles(a),
              _digitTiles(b),
              Text(
                place == 'Teng'
                    ? 'Uchala xona teng: sonlar teng.'
                    : '$place xonasidan oldingi xonalar teng. Shu birinchi farq sonlarning tartibini belgilaydi.',
              ),
              if (widget.mode == 'compare_digit_lengths')
                Text(
                  '$a: ${a.toString().length} xonali; $b: ${b.toString().length} xonali. Yetakchi nol miqdorni o‘zgartirmaydi.',
                ),
              for (final left in [true, false]) ...[
                Text(left ? 'Chap son: $a' : 'O‘ng son: $b'),
                Slider(
                  key: ValueKey(left ? 'compare-left' : 'compare-right'),
                  value: (left ? a : b).toDouble(),
                  min: 0,
                  max: 999,
                  divisions: 999,
                  semanticFormatterCallback: (v) => '${v.round()}',
                  onChanged: (v) => setState(() {
                    if (left) {
                      a = v.round();
                    } else {
                      b = v.round();
                    }
                  }),
                ),
              ],
              OutlinedButton(
                key: const ValueKey('compare-swap'),
                onPressed: () => setState(() {
                  final old = a;
                  a = b;
                  b = old;
                }),
                child: const Text('Sonlar o‘rnini almashtirish'),
              ),
            ],
            const Text(
              'Bu tushuntirish modeli. Mustaqil topshiriqni server tekshiradi; bu yerda XP berilmaydi.',
            ),
          ],
        ),
      ),
    );
  }
}

Widget _digitTiles(int n) => Semantics(
  label: '$n: ${n ~/ 100} yuzlik, ${n ~/ 10 % 10} o‘nlik, ${n % 10} birlik',
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final pair in [
          ('Yuzlik', n ~/ 100),
          ('O‘nlik', n ~/ 10 % 10),
          ('Birlik', n % 10),
        ])
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: mathIndigo),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${pair.$1}: ${pair.$2}'),
          ),
      ],
    ),
  ),
);

class _ThreeDigitAddExplorer extends StatefulWidget {
  final bool carry;
  const _ThreeDigitAddExplorer({required this.carry});
  @override
  State<_ThreeDigitAddExplorer> createState() => _ThreeDigitAddState();
}

class _ThreeDigitAddState extends State<_ThreeDigitAddExplorer> {
  late int a, b;
  int step = 0;
  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset() {
    a = widget.carry ? 268 : 432;
    b = widget.carry ? 157 : 245;
    step = 0;
  }

  @override
  void didUpdateWidget(_ThreeDigitAddExplorer old) {
    super.didUpdateWidget(old);
    if (old.carry != widget.carry) reset();
  }

  @override
  Widget build(BuildContext context) {
    final units = a % 10 + b % 10, carryT = units ~/ 10;
    final tens = a ~/ 10 % 10 + b ~/ 10 % 10 + carryT, carryH = tens ~/ 10;
    final hundreds = a ~/ 100 + b ~/ 100 + carryH;
    final title = widget.carry
        ? 'O‘tkazish bilan qo‘shish'
        : 'Xonalarni tekislab qo‘shish';
    final notes = [
      'Birlik: ${a % 10} + ${b % 10} = $units. ${units % 10} birlik qoladi; $carryT o‘nlik o‘tadi.',
      'O‘nlik: ${a ~/ 10 % 10} + ${b ~/ 10 % 10} + $carryT = $tens. ${tens % 10} o‘nlik qoladi; $carryH yuzlik o‘tadi.',
      'Yuzlik: ${a ~/ 100} + ${b ~/ 100} + $carryH = $hundreds. Natija: ${a + b}.',
    ];
    final pairs = widget.carry
        ? [
            [268, 157],
            [245, 326],
            [185, 127],
            [150, 170],
          ]
        : [
            [432, 245],
            [621, 58],
            [304, 210],
            [110, 123],
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title),
            const Text(
              'Namuna juftini tanlang va hisobni o‘ngdan boshlab qadam bilan oching.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pair in pairs)
                  ChoiceChip(
                    key: ValueKey('add-${pair[0]}-${pair[1]}'),
                    label: Text('${pair[0]} + ${pair[1]}'),
                    selected: a == pair[0] && b == pair[1],
                    onSelected: (_) => setState(() {
                      a = pair[0];
                      b = pair[1];
                      step = 0;
                    }),
                  ),
              ],
            ),
            _digitTiles(a),
            _digitTiles(b),
            const Text(
              'Ustunlar: yuzlik | o‘nlik | birlik. Birlik faqat birlik ostida turadi.',
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                notes[step],
                key: const ValueKey('three-digit-add-step'),
              ),
            ),
            Text(
              'Yozilgan natija: ${step >= 2 ? hundreds : '?'} | ${step >= 1 ? tens % 10 : '?'} | ${units % 10}',
              key: const ValueKey('three-digit-partial'),
            ),
            Text(
              'Birlikdan: $carryT o‘nlik; o‘nlikdan: ${step >= 1 ? carryH : '?'} yuzlik',
              key: const ValueKey('three-digit-carries'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('three-digit-back'),
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  key: const ValueKey('three-digit-next'),
                  onPressed: step == 2 ? null : () => setState(() => step++),
                  child: const Text('Keyingi qadam'),
                ),
              ],
            ),
            if (step == 2)
              Text(
                '$a + $b = ${a + b}',
                key: const ValueKey('three-digit-add-result'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const Text(
              '10 birlik = 1 o‘nlik; 10 o‘nlik = 1 yuzlik. O‘tkazilgan qiymat aynan bir marta qo‘shiladi.',
            ),
            const Text(
              'Faqat original misollar. Mustaqil javob kaliti yoki XP bu modelda hisoblanmaydi.',
            ),
          ],
        ),
      ),
    );
  }
}
