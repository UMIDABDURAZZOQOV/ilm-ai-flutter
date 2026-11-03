part of 'math_models.dart';

class _PointLineExplorer extends StatefulWidget {
  const _PointLineExplorer();
  @override
  State<_PointLineExplorer> createState() => _PointLineExplorerState();
}

class _PointLineExplorerState extends State<_PointLineExplorer> {
  double angle = .4;
  bool curved = false;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nuqta va yo‘nalish',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Semantics(
            label: curved
                ? 'Egri va to‘g‘ri chiziq A nuqtada uchrashgan.'
                : 'Turli yo‘nalishdagi ikki to‘g‘ri chiziq A nuqtada kesishadi.',
            child: SizedBox(
              height: 180,
              child: CustomPaint(painter: _PointLinePainter(angle, curved)),
            ),
          ),
          SwitchListTile(
            title: const Text('Bir chiziqni egri qil'),
            value: curved,
            onChanged: (v) => setState(() => curved = v),
          ),
          if (!curved)
            Slider(
              value: angle,
              min: .2,
              max: 1,
              divisions: 8,
              semanticFormatterCallback: (v) =>
                  'Qiya to‘g‘ri chiziq yo‘nalishi',
              onChanged: (v) => setState(() => angle = v),
            ),
          Text(
            curved
                ? 'Egri chiziq buriladi. To‘g‘ri chiziq bilan umumiy A nuqtani top.'
                : 'Qiyalikni o‘zgartir. Chiziq qiya bo‘lsa ham to‘g‘ri bo‘lib qoladi. A nuqta joyida turibdi.',
          ),
          const Text(
            'A — nuqtaning nomi. Ekranda chiziqning bir qismi ko‘rsatilgan.',
          ),
        ],
      ),
    ),
  );
}

class _PointLinePainter extends CustomPainter {
  final double angle;
  final bool curved;
  _PointLinePainter(this.angle, this.curved);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final first = Paint()
      ..color = mathIndigo
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final second = Paint()
      ..color = mathTurquoise
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(10, center.dy),
      Offset(size.width - 10, center.dy),
      first,
    );
    void arrow(Offset tip, double direction, Paint paint) {
      for (final delta in [-.5, .5]) {
        canvas.drawLine(
          tip,
          tip -
              Offset(math.cos(direction + delta), math.sin(direction + delta)) *
                  9,
          paint,
        );
      }
    }

    arrow(Offset(10, center.dy), math.pi, first);
    arrow(Offset(size.width - 10, center.dy), 0, first);
    if (curved) {
      final path = Path()
        ..moveTo(12, size.height * .75)
        ..quadraticBezierTo(
          size.width * .1,
          size.height - 5,
          center.dx,
          center.dy,
        )
        ..quadraticBezierTo(
          size.width * .9,
          5,
          size.width - 12,
          size.height * .25,
        );
      canvas.drawPath(path, second);
    } else {
      final length = math.min(size.width * .42, size.height * .4);
      final vector = Offset(math.cos(angle), -math.sin(angle)) * length;
      canvas.drawLine(center - vector, center + vector, second);
      arrow(center + vector, -angle, second);
      arrow(center - vector, math.pi - angle, second);
    }
    canvas.drawCircle(center, 5, Paint()..color = mathYellow);
    canvas.drawCircle(center, 5, first..strokeWidth = 1);
    final label = TextPainter(
      text: const TextSpan(
        text: 'A',
        style: TextStyle(
          color: mathIndigo,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, center + const Offset(8, -30));
  }

  @override
  bool shouldRepaint(_PointLinePainter old) =>
      angle != old.angle || curved != old.curved;
}
