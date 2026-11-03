part of 'math_models.dart';

class _ConcreteNumberExplorer extends StatefulWidget {
  final String mode;
  const _ConcreteNumberExplorer({required this.mode});
  @override
  State<_ConcreteNumberExplorer> createState() =>
      _ConcreteNumberExplorerState();
}

class _ConcreteNumberExplorerState extends State<_ConcreteNumberExplorer> {
  int first = 1, position = 3;
  List<int> route = [3];
  void move(int delta) => setState(() {
    position += delta;
    route = [...route, position];
    if (route.length > 20) route = route.sublist(route.length - 20);
  });
  @override
  Widget build(BuildContext context) {
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
    final total = widget.mode == 'compose_three'
        ? 3
        : widget.mode == 'compose_four'
        ? 4
        : 5;
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
            const Text(
              'Narsalar yangi paydo bo‘lmadi, faqat ikki guruhga ajratildi. Bitta doira faqat bir guruhga kiradi.',
            ),
          ],
        ),
      ),
    );
  }
}
