part of 'math_models.dart';

class _PlaceValueExplorer extends StatefulWidget {
  final String mode;
  const _PlaceValueExplorer({required this.mode});
  @override
  State<_PlaceValueExplorer> createState() => _PlaceValueExplorerState();
}

class _PlaceValueExplorerState extends State<_PlaceValueExplorer> {
  int number = 13, first = 1;
  bool upper = true;
  @override
  void didUpdateWidget(_PlaceValueExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      number = 13;
      first = 1;
      upper = true;
    }
  }

  Widget tokens(int count, String name, Color color) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < count; i++)
        Semantics(
          container: true,
          label: '$name, ${i + 1}-birlik',
          child: SizedBox.square(
            dimension: 24,
            child: CustomPaint(painter: MathShapePainter('circle', color)),
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final pairs = widget.mode != 'tens_units_20';
    final limit =
        const {
          'number_pairs_12': 12,
          'number_pairs_14': 14,
          'number_pairs_16': 16,
        }[widget.mode] ??
        20;
    final n = pairs ? (upper ? limit : limit - 1) : number;
    final tens = n ~/ 10, units = n % 10;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'O‘nliklar va birliklar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$n = ${tens * 10} + $units',
              style: const TextStyle(fontSize: 24),
              semanticsLabel: '$n: $tens ta o‘nlik va $units ta birlik',
            ),
            if (pairs)
              SwitchListTile(
                title: Text('$limit sonini ko‘rsat'),
                subtitle: Text(upper ? 'Hozir $limit' : 'Hozir ${limit - 1}'),
                value: upper,
                onChanged: (v) => setState(() {
                  upper = v;
                  first = 1;
                }),
              )
            else
              Slider(
                value: number.toDouble(),
                min: 11,
                max: 20,
                divisions: 9,
                semanticFormatterCallback: (v) => 'Tanlangan son ${v.round()}',
                onChanged: (v) => setState(() => number = v.round()),
              ),
            for (var group = 0; group < tens; group++)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: mathIndigo),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${group + 1}-o‘nlik: 10 birlik'),
                    tokens(10, '${group + 1}-o‘nlik', mathTurquoise),
                  ],
                ),
              ),
            Text('Alohida birliklar: $units'),
            if (units == 0)
              const Text('To‘liq o‘nliklardan tashqarida birlik qolmadi.')
            else
              tokens(units, 'Alohida', mathYellow),
            if (pairs) ...[
              const Divider(),
              const Text('Shu sonni ikki qismga ajrat'),
              Text(
                '$first + ${n - first} = $n',
                style: const TextStyle(fontSize: 24),
              ),
              Slider(
                value: first.toDouble(),
                min: 1,
                max: (n - 1).toDouble(),
                divisions: n - 2,
                semanticFormatterCallback: (v) =>
                    'Birinchi qism ${v.round()}, ikkinchi qism ${n - v.round()}',
                onChanged: (v) => setState(() => first = v.round()),
              ),
              Text('$n − $first = ${n - first}. Butunning miqdori o‘zgarmadi.'),
            ],
          ],
        ),
      ),
    );
  }
}
