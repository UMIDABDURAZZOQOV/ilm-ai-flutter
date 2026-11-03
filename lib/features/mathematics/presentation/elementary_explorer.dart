part of 'math_models.dart';

class _ElementaryExplorer extends StatefulWidget {
  final String mode;
  const _ElementaryExplorer({required this.mode});
  @override
  State<_ElementaryExplorer> createState() => _ElementaryExplorerState();
}

class _ElementaryExplorerState extends State<_ElementaryExplorer> {
  int stage = 1, number = 1, secondCount = 2;
  bool changed = false;
  MathJson object(String id, String shape, double x, double y) => {
    'id': id,
    'shape': shape,
    'color': 'turquoise',
    'size': .65,
    'x': x,
    'y': y,
  };
  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    if (mode == 'number_line') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '1 dan 10 gacha sonlar qatori',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var n = 1; n <= 10; n++)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: ChoiceChip(
                          label: Text('$n'),
                          selected: number == n,
                          onSelected: (_) => setState(() => number = n),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                'Tanlangan son: $number. Qo‘shni songa bittadan qadam bilan o‘t.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: number == 1
                        ? null
                        : () => setState(() => number--),
                    child: const Text('Oldingi son'),
                  ),
                  OutlinedButton(
                    onPressed: number == 10
                        ? null
                        : () => setState(() => number++),
                    child: const Text('Keyingi son'),
                  ),
                ],
              ),
              MathBoard(
                scene: {
                  'type': 'shape_board',
                  'items': [
                    for (var i = 0; i < number; i++)
                      object(
                        '${i + 1}',
                        'circle',
                        .15 + (i % 5) * .175,
                        .25 + (i ~/ 5) * .45,
                      ),
                  ],
                },
              ),
              const Text(
                'Har bir doira uchun bittadan son ayt. Bu model faqat 1–10 oralig‘ini ko‘rsatadi.',
              ),
            ],
          ),
        ),
      );
    }
    final timeline = mode == 'timeline';
    final items = timeline
        ? [
            for (var i = 0; i < stage; i++)
              object(
                '${i + 1}',
                ['square', 'circle', 'triangle'][i],
                .2 + i * .3,
                .5,
              ),
          ]
        : [
            for (var i = 0; i < 3; i++)
              object('a${i + 1}', 'circle', .15 + i * .22, .2),
            for (
              var i = 0;
              i < (mode == 'group_members' ? 3 : secondCount);
              i++
            )
              object(
                'b${i + 1}',
                mode == 'group_members' && changed && i == 2
                    ? 'square'
                    : 'circle',
                .15 + i * .22,
                .7,
              ),
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              timeline
                  ? 'Ilmoning doskasi'
                  : 'A guruh yuqorida, B guruh pastda',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            MathBoard(scene: {'type': 'shape_board', 'items': items}),
            if (timeline) ...[
              Text(
                stage == 1
                    ? 'Birinchi qadam: kvadrat qo‘yildi.'
                    : stage == 2
                    ? 'Keyin doira qo‘yildi. Kvadrat o‘z joyida qoldi.'
                    : 'Oxirgi qadam: uchburchak qo‘yildi.',
              ),
              FilledButton(
                onPressed: () =>
                    setState(() => stage = stage == 3 ? 1 : stage + 1),
                child: Text(stage == 3 ? 'Boshidan ko‘rish' : 'Keyingi qadam'),
              ),
            ] else if (mode == 'group_members') ...[
              SwitchListTile(
                title: const Text('B dagi bir doirani kvadratga almashtir'),
                value: changed,
                onChanged: (v) => setState(() => changed = v),
              ),
              Text(
                changed
                    ? 'Narsalar soni uchtaligicha qoldi. Faqat shakl turlari bo‘yicha tarkib endi boshqa.'
                    : 'Har ikkala guruhda uchta doira bor. Faqat shakl turlari bo‘yicha tarkib bir xil.',
              ),
            ] else ...[
              Slider(
                value: secondCount.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                semanticFormatterCallback: (v) =>
                    'B guruhda ${v.round()} narsa',
                onChanged: (v) => setState(() => secondCount = v.round()),
              ),
              Text(
                secondCount == 3
                    ? 'Har biriga bittadan juft topiladi. Miqdorlar teng.'
                    : secondCount < 3
                    ? 'A guruhda juftsiz narsalar qoladi: A da ko‘proq.'
                    : 'B guruhda juftsiz narsa qoladi: B da ko‘proq.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
