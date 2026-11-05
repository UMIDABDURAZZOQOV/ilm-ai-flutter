part of 'math_models.dart';

class _ThreeDigitSubtractExplorer extends StatefulWidget {
  final String mode;
  const _ThreeDigitSubtractExplorer({required this.mode});
  @override
  State<_ThreeDigitSubtractExplorer> createState() =>
      _ThreeDigitSubtractState();
}

class _ThreeDigitSubtractState extends State<_ThreeDigitSubtractExplorer> {
  late int a, b;
  int step = 0;
  bool showAddition = false;
  List<(int, int)> get cases => switch (widget.mode) {
    'subtract_three_regroup' => [(463, 158), (574, 236), (572, 240)],
    'subtract_three_double' => [(634, 278), (745, 386), (820, 290)],
    'subtract_round_hundred' => [(700, 286), (800, 357), (900, 460)],
    _ => [(800, 372), (200, 176), (900, 368)],
  };
  void reset() {
    a = cases.first.$1;
    b = cases.first.$2;
    step = 0;
    showAddition = false;
  }

  @override
  void initState() {
    super.initState();
    reset();
  }

  @override
  void didUpdateWidget(_ThreeDigitSubtractExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) reset();
  }

  @override
  Widget build(BuildContext context) {
    int h = a ~/ 100, t = a ~/ 10 % 10, u = a % 10;
    final bh = b ~/ 100, bt = b ~/ 10 % 10, bu = b % 10;
    final needU = u < bu;
    bool throughZero = false;
    if (needU) {
      if (t == 0) {
        h--;
        t += 10;
        throughZero = true;
      }
      t--;
      u += 10;
    }
    final unitH = h, unitT = t;
    final needT = t < bt;
    if (needT) {
      h--;
      t += 10;
    }
    final resultH = h - bh, resultT = t - bt, resultU = u - bu;
    final mixed = widget.mode == 'mixed_three_operations';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ayirishda miqdorni saqlab qayta guruhlash'),
            if (mixed)
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const ValueKey('mixed-subtraction'),
                    label: const Text('Ayirish'),
                    selected: !showAddition,
                    onSelected: (_) => setState(() => showAddition = false),
                  ),
                  ChoiceChip(
                    key: const ValueKey('mixed-addition'),
                    label: const Text('Qo‘shish'),
                    selected: showAddition,
                    onSelected: (_) => setState(() => showAddition = true),
                  ),
                ],
              ),
            if (showAddition)
              const _ThreeDigitAddExplorer(carry: true)
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cases)
                    ChoiceChip(
                      key: ValueKey('sub-${c.$1}-${c.$2}'),
                      label: Text('${c.$1} − ${c.$2}'),
                      selected: a == c.$1 && b == c.$2,
                      onSelected: (_) => setState(() {
                        a = c.$1;
                        b = c.$2;
                        step = 0;
                      }),
                    ),
                ],
              ),
              _digitTiles(a),
              _digitTiles(b),
              if (throughZero)
                Text(
                  'Nolli o‘nlik orqali: $a = $unitH yuzlik + $unitT o‘nlik + $u birlik.',
                  key: const ValueKey('subtract-through-zero'),
                ),
              Semantics(
                liveRegion: true,
                child: Text(switch (step) {
                  0 =>
                    'Birlik: $u − $bu = $resultU. ${needU ? '1 o‘nlik 10 birlikka almashtirildi; o‘nlik $unitT bo‘lib qoldi.' : 'Birlik yetarli; almashtirish kerak emas.'}',
                  1 =>
                    'O‘nlik: $t − $bt = $resultT. ${needT ? '1 yuzlik 10 o‘nlikka almashtirildi; yuzlik $h bo‘lib qoldi.' : 'Yangi o‘nlik miqdori yetarli.'}',
                  _ => 'Yuzlik: $h − $bh = $resultH. Natija: ${a - b}.',
                }, key: const ValueKey('three-digit-sub-step')),
              ),
              Text(
                'Qolgan natija: ${step >= 2 ? resultH : '?'} | ${step >= 1 ? resultT : '?'} | $resultU',
                key: const ValueKey('three-digit-sub-partial'),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: const ValueKey('three-digit-sub-back'),
                    onPressed: step == 0 ? null : () => setState(() => step--),
                    child: const Text('Oldingi qadam'),
                  ),
                  FilledButton(
                    key: const ValueKey('three-digit-sub-next'),
                    onPressed: step == 2 ? null : () => setState(() => step++),
                    child: const Text('Keyingi qadam'),
                  ),
                ],
              ),
              if (step == 2) ...[
                Text(
                  '$a − $b = ${a - b}',
                  key: const ValueKey('three-digit-sub-result'),
                ),
                Text('Tekshiruv: ${a - b} + $b = $a.'),
              ],
              const Text(
                'Donor xona kamayadi. 1 yuzlik = 10 o‘nlik; 1 o‘nlik = 10 birlik. Bir miqdor ikki marta sanalmaydi.',
              ),
            ],
            const Text(
              'Tushuntirish modeli; mustaqil javoblar serverda tekshiriladi, bu yerda XP berilmaydi.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreeAddendExplorer extends StatefulWidget {
  const _ThreeAddendExplorer();
  @override
  State<_ThreeAddendExplorer> createState() => _ThreeAddendState();
}

class _ThreeAddendState extends State<_ThreeAddendExplorer> {
  List<int> numbers = [126, 238, 147];
  int step = 0;
  @override
  Widget build(BuildContext context) {
    final units = numbers.fold(0, (int s, n) => s + n % 10),
        carryT = units ~/ 10;
    final tens = numbers.fold(0, (int s, n) => s + n ~/ 10 % 10) + carryT,
        carryH = tens ~/ 10;
    final hundreds = numbers.fold(0, (int s, n) => s + n ~/ 100) + carryH;
    final total = numbers.fold(0, (int s, n) => s + n);
    final explanations = [
      'Birliklar: ${numbers.map((n) => n % 10).join(' + ')} = $units; ${units % 10} birlik qoladi, $carryT o‘nlik o‘tadi.',
      'O‘nliklar: ${numbers.map((n) => n ~/ 10 % 10).join(' + ')} + $carryT = $tens; ${tens % 10} o‘nlik qoladi, $carryH yuzlik o‘tadi.',
      'Yuzliklar: ${numbers.map((n) => n ~/ 100).join(' + ')} + $carryH = $hundreds. Jami $total.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Uch sonni xonalar bo‘yicha qo‘shing'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final row in [
                  [126, 238, 147],
                  [215, 167, 128],
                  [260, 270, 350],
                ])
                  ChoiceChip(
                    key: ValueKey('multi-${row.join('-')}'),
                    label: Text(row.join(' + ')),
                    selected: numbers.join(',') == row.join(','),
                    onSelected: (_) => setState(() {
                      numbers = row;
                      step = 0;
                    }),
                  ),
              ],
            ),
            for (final n in numbers) _digitTiles(n),
            Semantics(
              liveRegion: true,
              child: Text(
                explanations[step],
                key: const ValueKey('multi-step'),
              ),
            ),
            Text(
              'Natija xonalari: ${step >= 2 ? hundreds : '?'} | ${step >= 1 ? tens % 10 : '?'} | ${units % 10}',
              key: const ValueKey('multi-partial'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('multi-back'),
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  key: const ValueKey('multi-next'),
                  onPressed: step == 2 ? null : () => setState(() => step++),
                  child: const Text('Keyingi qadam'),
                ),
              ],
            ),
            if (step == 2)
              Text(
                '${numbers.join(' + ')} = $total',
                key: const ValueKey('multi-result'),
              ),
            const Text(
              '21 birlik = 2 o‘nlik + 1 birlik. O‘tkaziladigan o‘nliklar soni har doim 1 bo‘lmaydi. Har son bir martadan qatnashadi.',
            ),
            const Text(
              'Mustaqil topshiriq serverda tekshiriladi. Bu model XP bermaydi.',
            ),
          ],
        ),
      ),
    );
  }
}

class _EqualCellGridExplorer extends StatefulWidget {
  const _EqualCellGridExplorer();
  @override
  State<_EqualCellGridExplorer> createState() => _EqualCellGridState();
}

class _EqualCellGridState extends State<_EqualCellGridExplorer> {
  int rows = 2, columns = 3;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Teng kataklarni sanang'),
          Wrap(
            spacing: 8,
            children: [
              for (final shape in [(2, 3), (3, 2), (2, 4)])
                ChoiceChip(
                  key: ValueKey('grid-${shape.$1}-${shape.$2}'),
                  label: Text(
                    '${shape.$1} qator, har birida ${shape.$2} katak',
                  ),
                  selected: rows == shape.$1 && columns == shape.$2,
                  onSelected: (_) => setState(() {
                    rows = shape.$1;
                    columns = shape.$2;
                  }),
                ),
            ],
          ),
          Semantics(
            label:
                '$rows qator, har birida $columns ta teng katak; jami ${rows * columns}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int r = 0; r < rows; r++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int c = 0; c < columns; c++)
                          Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: mathTurquoise.withValues(alpha: .25),
                              border: Border.all(color: mathIndigo),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              '${List.filled(rows, columns).join(' + ')} = ${rows * columns} katak',
              key: const ValueKey('equal-grid-count'),
            ),
          ),
          const Text(
            'Kataklarning o‘lchami bir xil. Bu modeldagi kataklar haqiqiy santimetr yoki yer maydoni o‘lchovi emas. Sonlarning tengligi har doim shakllarning ayni joylashishini anglatmaydi.',
          ),
        ],
      ),
    ),
  );
}
