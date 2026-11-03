part of 'math_models.dart';

class _SegmentExplorer extends StatefulWidget {
  const _SegmentExplorer();
  @override
  State<_SegmentExplorer> createState() => _SegmentExplorerState();
}

class _SegmentExplorerState extends State<_SegmentExplorer> {
  bool three = false;
  double bend = .25;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tutashgan kesmalar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Semantics(
            label: three
                ? 'AB, BC va CD uchta bo‘g‘in, A B C D to‘rtta nuqta.'
                : 'AB va BC ikkita bo‘g‘in, A B C uchta nuqta.',
            child: SizedBox(
              height: 180,
              child: CustomPaint(painter: _SegmentPainter(three, bend)),
            ),
          ),
          SwitchListTile(
            title: const Text('CD bo‘g‘inini ham qo‘sh'),
            value: three,
            onChanged: (v) => setState(() => three = v),
          ),
          Slider(
            value: bend,
            min: .15,
            max: .4,
            divisions: 5,
            semanticFormatterCallback: (v) => 'B nuqtaning balandligi',
            onChanged: (v) => setState(() => bend = v),
          ),
          Text(
            three
                ? 'AB → BC → CD. Uchta bo‘g‘in, to‘rtta nuqta.'
                : 'AB → BC. Ikkita bo‘g‘in, uchta nuqta.',
          ),
          const Text(
            'Har bo‘g‘in ikki oxir nuqta orasidagi kesma. Balandlik o‘zgarsa ham tutashgan bo‘g‘inlar soni o‘zgarmaydi.',
          ),
        ],
      ),
    ),
  );
}

class _SegmentPainter extends CustomPainter {
  final bool three;
  final double bend;
  _SegmentPainter(this.three, this.bend);
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * .1, size.height * .7),
      Offset(size.width * .4, size.height * bend),
      Offset(size.width * .7, size.height * .7),
      if (three) Offset(size.width * .9, size.height * .25),
    ];
    final stroke = Paint()
      ..color = mathIndigo
      ..strokeWidth = 3;
    for (var i = 1; i < points.length; i++) {
      canvas.drawLine(points[i - 1], points[i], stroke);
    }
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, Paint()..color = mathYellow);
      final label = TextPainter(
        text: TextSpan(
          text: ['A', 'B', 'C', 'D'][i],
          style: const TextStyle(
            color: mathIndigo,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, points[i] + const Offset(-5, -28));
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      three != old.three || bend != old.bend;
}
