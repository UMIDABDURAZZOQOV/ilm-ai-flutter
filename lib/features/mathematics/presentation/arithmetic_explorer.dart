part of 'math_models.dart';

/// A small concrete model, not a symbolic algebra solver or handwriting grader.
class _ArithmeticExplorer extends StatefulWidget {
  final String mode;
  const _ArithmeticExplorer({required this.mode});
  @override
  State<_ArithmeticExplorer> createState() => _ArithmeticExplorerState();
}

class _ArithmeticExplorerState extends State<_ArithmeticExplorer> {
  int a = 2, b = 1;
  bool two = false;
  MathJson dot(String id, int i, double y, String color) => {
    'id': id,
    'shape': 'circle',
    'color': color,
    'size': .55,
    'x': .12 + i * .15,
    'y': y,
  };
  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final single = mode == 'one_two';
    final subtract = mode == 'subtraction';
    final compare = mode == 'comparison';
    final first = single ? (two ? 2 : 1) : a;
    final second = subtract ? a - b : b;
    final expression = single
        ? 'Miqdor: $first'
        : compare
        ? '$a ${a == b
              ? '='
              : a > b
              ? '>'
              : '<'} $b'
        : subtract
        ? '$a − $b = ${a - b}'
        : '$a + $b = ${a + b}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              single
                  ? 'Bitta va ikkita'
                  : subtract
                  ? 'Oldin va keyin'
                  : compare
                  ? 'Guruhlarni solishtir'
                  : 'Ikki guruhni birlashtir',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              expression,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              semanticsLabel: single
                  ? '$first ta doira'
                  : compare
                  ? '$a ${a == b
                        ? 'teng'
                        : a > b
                        ? 'katta'
                        : 'kichik'} $b'
                  : subtract
                  ? '$a dan $b ni ayirsak ${a - b}'
                  : '$a ga $b qo‘shsak ${a + b}',
            ),
            if (!single)
              Text(
                subtract
                    ? 'Yuqorida avvalgi $a ta. Pastda $b tasi olingach qolgan ${a - b} ta; bu ikkita alohida holat.'
                    : 'A yuqorida: $a ta. B pastda: $b ta. Har bir doira bir marta sanaladi.',
              ),
            MathBoard(
              scene: {
                'type': 'shape_board',
                'items': [
                  for (var i = 0; i < first; i++)
                    dot('a$i', i, single ? .5 : .25, 'turquoise'),
                  if (!single)
                    for (var i = 0; i < second; i++)
                      dot('b$i', i, .75, 'yellow'),
                ],
              },
            ),
            if (single)
              SwitchListTile(
                title: const Text('Yana bitta doira qo‘sh'),
                value: two,
                onChanged: (v) => setState(() => two = v),
              )
            else ...[
              Text(subtract ? 'Avval bor edi: $a' : 'A guruh: $a'),
              Slider(
                value: a.toDouble(),
                min: 2,
                max: 5,
                divisions: 3,
                semanticFormatterCallback: (v) =>
                    'Birinchi miqdor ${v.round()}',
                onChanged: (v) => setState(() {
                  a = v.round();
                  if (subtract && b >= a) b = a - 1;
                }),
              ),
              Text(subtract ? 'Olinadi: $b' : 'B guruh: $b'),
              if (!subtract || a > 2)
                Slider(
                  value: b.toDouble(),
                  min: 1,
                  max: subtract ? (a - 1).toDouble() : 5,
                  divisions: subtract ? a - 2 : 4,
                  semanticFormatterCallback: (v) =>
                      'Ikkinchi miqdor ${v.round()}',
                  onChanged: (v) => setState(() => b = v.round()),
                )
              else
                const Text('Bu holatda bittasi olinadi, bittasi qoladi.'),
            ],
            Text(
              single
                  ? 'Bitta — 1. Ikkita — 2. Raqamni qo‘lda yozishni daftarda ham mashq qil.'
                  : subtract
                  ? 'Faqat pastdagi qolgan guruhni sana. Yuqori va pastki holatlarni qo‘shib sanama. Bu model nolni hali kiritmaydi.'
                  : compare
                  ? 'Belgining ochiq tomoni katta songa qaraydi. Miqdorlar teng bo‘lsa = yoziladi.'
                  : 'Jami miqdorni ikkala alohida guruhni birlashtirib topamiz.',
            ),
          ],
        ),
      ),
    );
  }
}
