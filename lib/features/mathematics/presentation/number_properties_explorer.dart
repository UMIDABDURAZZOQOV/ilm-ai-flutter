part of 'math_models.dart';

class _NumberPropertiesExplorer extends StatefulWidget {
  final String mode;
  const _NumberPropertiesExplorer({required this.mode});
  @override
  State<_NumberPropertiesExplorer> createState() =>
      _NumberPropertiesExplorerState();
}

class _NumberPropertiesExplorerState extends State<_NumberPropertiesExplorer> {
  int number = 0;
  bool ascending = true;
  List<int> selected = [];
  @override
  Widget build(BuildContext context) {
    final order = widget.mode == 'ordering_numbers';
    final natural = widget.mode == 'natural_numbers';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              order
                  ? 'Son kartalari'
                  : natural
                  ? 'Sonning turli xossalari'
                  : 'Ikkitadan juftlash',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (order) ...[
              SwitchListTile(
                title: Text(
                  ascending
                      ? 'O‘sish: kichikdan kattaga'
                      : 'Kamayish: kattadan kichikka',
                ),
                value: ascending,
                onChanged: (v) => setState(() {
                  ascending = v;
                  selected = [];
                }),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final n in [5, 2, 9, 1])
                    ActionChip(
                      label: Text('$n'),
                      onPressed: selected.contains(n)
                          ? null
                          : () => setState(() => selected.add(n)),
                    ),
                ],
              ),
              Text('Tanlangan tartib: ${selected.join(', ')}'),
              if (selected.length == 4)
                Text(
                  (ascending
                          ? selected.join(',') == '1,2,5,9'
                          : selected.join(',') == '9,5,2,1')
                      ? 'Tartib mos. Barcha kartalar bir martadan ishlatildi.'
                      : 'Yo‘nalishni tekshir. Eng kichik yoki eng katta kartadan boshlash yordam beradi.',
                ),
              TextButton(
                onPressed: () => setState(selected.clear),
                child: const Text('Kartalarni qayta joylash'),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n
                      in natural
                          ? [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13]
                          : List.generate(11, (i) => i))
                    ChoiceChip(
                      label: Text('$n'),
                      selected: number == n,
                      onSelected: (_) => setState(() => number = n),
                    ),
                ],
              ),
              Text('Tanlangan son: $number'),
              if (natural) ...[
                Text(
                  number == 0
                      ? 'Shu darslik kelishuvida 0 natural emas.'
                      : '$number — shu darslikdagi natural sanoq soni.',
                ),
                Text(
                  '$number yozuvida ${number.toString().length} ta raqam bor. Natural bo‘lish bilan xona soni boshqa xossalar.',
                ),
              ] else ...[
                Text(
                  number.isEven
                      ? '$number — juft: juftsiz narsa qolmaydi.'
                      : '$number — toq: bitta narsa juftsiz qoladi.',
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < number; i += 2)
                      Semantics(
                        label: i + 1 < number
                            ? '${i ~/ 2 + 1}-juft, ikkita doira'
                            : 'Bitta juftsiz doira',
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: mathIndigo),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var j = i; j < number && j < i + 2; j++)
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SizedBox.square(
                                    dimension: 24,
                                    child: CustomPaint(
                                      painter: MathShapePainter(
                                        'circle',
                                        mathTurquoise,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                if (number == 0)
                  const Text(
                    'Guruh bo‘sh. Juftsiz narsa ham yo‘q; 0 juftlar ro‘yxatida.',
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
