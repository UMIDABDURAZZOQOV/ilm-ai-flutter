part of 'math_models.dart';

class _ConcreteNumberExplorer extends StatefulWidget {
  final String mode;
  const _ConcreteNumberExplorer({required this.mode});
  @override
  State<_ConcreteNumberExplorer> createState() =>
      _ConcreteNumberExplorerState();
}

class _ConcreteNumberExplorerState extends State<_ConcreteNumberExplorer> {
  int first = 1, position = 3, zeroCount = 3;
  List<int> route = [3];
  @override
  void didUpdateWidget(_ConcreteNumberExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      first = 1;
      position = 3;
      zeroCount = 3;
      route = [3];
    }
  }

  void move(int delta) => setState(() {
    position += delta;
    route = [...route, position];
    if (route.length > 20) route = route.sublist(route.length - 20);
  });
  @override
  Widget build(BuildContext context) {
    Widget tokens(int count, String group, Color color) => Wrap(
      spacing: 8,
      runSpacing: 12,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            container: true,
            excludeSemantics: true,
            label: '$group qism, ${i + 1}-doira',
            child: SizedBox(
              width: 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 30,
                    child: CustomPaint(
                      painter: MathShapePainter('circle', color),
                    ),
                  ),
                  Text('${i + 1}'),
                ],
              ),
            ),
          ),
      ],
    );
    if (widget.mode == 'zero') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ilmoning qutisi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Qutida: $zeroCount ta doira',
                style: const TextStyle(fontSize: 24),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: mathIndigo),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: zeroCount == 0
                    ? Semantics(
                        label: 'Bo‘sh quti. Nol doira.',
                        child: const Text('Bo‘sh: 0 ta'),
                      )
                    : tokens(zeroCount, 'Quti', mathTurquoise),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: zeroCount == 0
                        ? null
                        : () => setState(() => zeroCount--),
                    child: const Text('Bittasini ol'),
                  ),
                  OutlinedButton(
                    onPressed: zeroCount == 4
                        ? null
                        : () => setState(() => zeroCount++),
                    child: const Text('Bittasini qo‘sh'),
                  ),
                ],
              ),
              FilledButton(
                onPressed: zeroCount == 0
                    ? null
                    : () => setState(() => zeroCount = 0),
                child: const Text('Hammasini ol'),
              ),
              Text(
                zeroCount == 0
                    ? 'Hech narsa qolmadi. Nol — aniq miqdor, javobni bo‘sh qoldirish emas.'
                    : 'Hozir $zeroCount ta. Nolni qo‘shish yoki ayirish miqdorni o‘zgartirmaydi.',
              ),
            ],
          ),
        ),
      );
    }
    if (widget.mode == 'steps_five') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Qadamlar: 1 dan 5 gacha',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var n = 1; n <= 5; n++)
                    Chip(
                      label: Text('$n'),
                      backgroundColor: n == position ? mathTurquoise : null,
                      labelStyle: TextStyle(
                        color: n == position ? mathIndigo : null,
                      ),
                      avatar: n == position
                          ? const Icon(
                              Icons.location_on,
                              semanticLabel: 'Hozirgi joy',
                              size: 20,
                            )
                          : null,
                    ),
                ],
              ),
              Text(
                'Hozirgi son: $position',
                semanticsLabel: 'Hozirgi son $position',
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: position == 1 ? null : () => move(-1),
                    child: const Text('Bir qadam chapga'),
                  ),
                  OutlinedButton(
                    onPressed: position == 5 ? null : () => move(1),
                    child: const Text('Bir qadam o‘ngga'),
                  ),
                ],
              ),
              Text('Oxirgi yo‘l: ${route.join(' → ')}'),
              const Text(
                'Har qo‘shni songa o‘tish bitta qadam. Boshlanish nuqtasi qadam emas. +1 o‘ngga, −1 chapga olib boradi.',
              ),
              TextButton(
                onPressed: () => setState(() {
                  position = 3;
                  route = [3];
                }),
                child: const Text('3 dan qayta boshlash'),
              ),
            ],
          ),
        ),
      );
    }
    final total =
        const {
          'compose_three': 3,
          'compose_four': 4,
          'compose_six': 6,
          'compose_seven': 7,
          'compose_eight': 8,
          'compose_nine': 9,
          'compose_ten': 10,
          'inverse_family': 7,
        }[widget.mode] ??
        5;
    final second = total - first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Butun: $total. Ikki alohida qism',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$first + $second = $total',
              style: const TextStyle(fontSize: 24),
              semanticsLabel: '$first ga $second qo‘shsak $total',
            ),
            if (total > 5) ...[
              Text('A qism: $first ta'),
              tokens(first, 'A', mathTurquoise),
              Text('B qism: $second ta'),
              tokens(second, 'B', mathYellow),
            ] else
              MathBoard(
                scene: {
                  'type': 'shape_board',
                  'items': [
                    for (var i = 0; i < total; i++)
                      {
                        'id': '${i + 1}',
                        'shape': 'circle',
                        'color': i < first ? 'turquoise' : 'yellow',
                        'size': .6,
                        'x': .12 + i * .18,
                        'y': i < first ? .25 : .75,
                      },
                  ],
                },
              ),
            Text(
              'A qism: $first ta. B qism: $second ta. Jami doiralar har doim $total ta.',
            ),
            Slider(
              value: first.toDouble(),
              min: 1,
              max: (total - 1).toDouble(),
              divisions: total - 2,
              semanticFormatterCallback: (v) =>
                  'Birinchi qism ${v.round()}, ikkinchi qism ${total - v.round()}',
              onChanged: (v) => setState(() => first = v.round()),
            ),
            Text('$total − $first = $second. A qismini olsak B qismi qoladi.'),
            if (widget.mode == 'inverse_family')
              Text(
                '$total − $second = $first. B qismini olsak A qismi qoladi.',
              ),
            const Text(
              'Narsalar yangi paydo bo‘lmadi, faqat ikki guruhga ajratildi. Bitta doira faqat bir guruhga kiradi.',
            ),
          ],
        ),
      ),
    );
  }
}
