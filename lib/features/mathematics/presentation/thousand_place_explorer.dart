part of 'math_models.dart';

/// Original teaching model. It never grades independent answers or awards XP.
class _ThousandPlaceExplorer extends StatefulWidget {
  final String mode;
  const _ThousandPlaceExplorer({required this.mode});
  @override
  State<_ThousandPlaceExplorer> createState() => _ThousandPlaceExplorerState();
}

class _ThousandPlaceExplorerState extends State<_ThousandPlaceExplorer> {
  late int value;
  int representation = 0;
  List<int> get samples => switch (widget.mode) {
    'hundreds_thousand' => [100, 300, 700, 1000],
    'three_digit_place' => [536, 629, 482],
    'zero_tens_place' => [206, 703, 901, 405],
    'zero_units_place' => [604, 640, 64, 340],
    _ => [637, 390, 705, 1000],
  };
  @override
  void initState() {
    super.initState();
    value = samples.first;
  }

  @override
  void didUpdateWidget(_ThousandPlaceExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      value = samples.first;
      representation = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final thousand = value ~/ 1000,
        h = value ~/ 100 % 10,
        t = value ~/ 10 % 10,
        u = value % 10;
    final hundredsOnly = widget.mode == 'hundreds_thousand';
    final expression = representation == 1
        ? '$value = ${value ~/ 10} to‘liq o‘nlik + $u birlik'
        : representation == 2
        ? '$value = ${value ~/ 100} to‘liq yuzlik + ${value % 100} birlik'
        : value == 1000
        ? '1000 = 1 ming + 0 yuzlik + 0 o‘nlik + 0 birlik'
        : '$value = ${h * 100} + ${t * 10} + $u';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hundredsOnly
                  ? 'Yuzliklardan minggacha'
                  : 'Xona raqami va to‘liq guruhlar',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in samples)
                  ChoiceChip(
                    key: ValueKey('place-sample-$n'),
                    label: Text('$n'),
                    selected: value == n,
                    onSelected: (_) => setState(() => value = n),
                  ),
              ],
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                '$value',
                key: const ValueKey('thousand-value'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${value.toString().length} xonali yozuv',
              key: const ValueKey('thousand-digits'),
            ),
            Text(
              'Ming: $thousand; yuzlik raqami: $h; o‘nlik raqami: $t; birlik raqami: $u',
              key: const ValueKey('place-digits'),
            ),
            Semantics(
              label:
                  '$value birlik: $thousand ming, $h yuzlik, $t o‘nlik, $u birlik. Katta blok100,ustun10,nuqta1birlik.',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 180,
                  child: CustomPaint(painter: _ThousandPlacePainter(value)),
                ),
              ),
            ),
            if (hundredsOnly) ...[
              const Text(
                '100 birlik = 1 yuzlik = 10 o‘nlik. 1000 = 10 yuzlik; yozuvda 4 ta raqam.',
              ),
              Slider(
                key: const ValueKey('hundreds-slider'),
                value: value.toDouble(),
                min: 0,
                max: 1000,
                divisions: 10,
                semanticFormatterCallback: (v) =>
                    '${v.round()} birlik,${v.round() ~/ 100} yuzlik',
                onChanged: (v) => setState(() => value = v.round()),
              ),
            ] else ...[
              const Text(
                'Xona raqamlarini o‘zgartirib sonni tiklang. Nolning o‘rnini saqlang.',
              ),
              if (value == 1000)
                const Text(
                  '1000 alohida ming xonasiga ega. Pastki xonalarni o‘zgartirish uchun mingdan kichik namunani tanlang.',
                ),
              for (var i = 0; i < 3; i++) ...[
                Text(
                  '${['Yuzlik raqami', 'O‘nlik raqami', 'Birlik raqami'][i]}: ${[h, t, u][i]}',
                ),
                Slider(
                  key: ValueKey('three-digit-$i'),
                  value: [h, t, u][i].toDouble(),
                  min: 0,
                  max: 9,
                  divisions: 9,
                  semanticFormatterCallback: (v) =>
                      '${['Yuzlik', 'O‘nlik', 'Birlik'][i]} raqami ${v.round()}',
                  onChanged: value == 1000
                      ? null
                      : (v) => setState(() {
                          final digits = [h, t, u];
                          digits[i] = v.round();
                          value = digits[0] * 100 + digits[1] * 10 + digits[2];
                        }),
                ),
              ],
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    key: ValueKey('place-representation-$i'),
                    label: Text(
                      ['Xonalar', 'To‘liq o‘nlik', 'To‘liq yuzlik'][i],
                    ),
                    selected: representation == i,
                    onSelected: (_) => setState(() => representation = i),
                  ),
              ],
            ),
            Semantics(
              liveRegion: true,
              child: Text(expression, key: const ValueKey('place-equation')),
            ),
            Text(
              'To‘liq o‘nliklar: ${value ~/ 10}; to‘liq yuzliklar: ${value ~/ 100}',
              key: const ValueKey('place-full-groups'),
            ),
            const Text(
              'Bu sonli model; shaklning ekran o‘lchami birlik miqdori emas. Mustaqil savol serverda tekshiriladi.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ThousandPlacePainter extends CustomPainter {
  final int value;
  _ThousandPlacePainter(this.value);
  @override
  void paint(Canvas c, Size s) {
    final border = Paint()
      ..color = mathIndigo
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    if (value == 1000) {
      final r = Rect.fromLTWH(6, 6, s.width - 12, 150);
      c.drawRect(r, Paint()..color = mathYellow.withValues(alpha: .2));
      c.drawRect(r, border);
      for (var i = 0; i < 10; i++) {
        final x = 12 + (i % 5) * (s.width - 24) / 5, y = 18.0 + (i ~/ 5) * 65;
        final tile = Rect.fromLTWH(x, y, (s.width - 36) / 5, 50);
        c.drawRect(tile, Paint()..color = mathTurquoise);
        c.drawRect(tile, border);
      }
      return;
    }
    final h = value ~/ 100,
        t = value ~/ 10 % 10,
        u = value % 10,
        col = s.width / 3;
    for (var i = 0; i < h; i++) {
      final edge = col / 3 - 4,
          x = 2 + (i % 3) * (col / 3),
          y = 10 + (i ~/ 3) * (edge + 7),
          r = Rect.fromLTWH(x, y, edge, edge);
      c.drawRect(r, Paint()..color = mathTurquoise.withValues(alpha: .4));
      c.drawRect(r, border);
      for (var j = 1; j < 10; j++) {
        c.drawLine(
          Offset(x + j * edge / 10, y),
          Offset(x + j * edge / 10, y + edge),
          border,
        );
        c.drawLine(
          Offset(x, y + j * edge / 10),
          Offset(x + edge, y + j * edge / 10),
          border,
        );
      }
    }
    for (var i = 0; i < t; i++) {
      final x = col + 4 + (i % 5) * (col - 8) / 5,
          y = 10.0 + (i ~/ 5) * 65,
          rect = Rect.fromLTWH(x, y, 7, 50);
      c.drawRect(rect, Paint()..color = mathYellow);
      c.drawRect(rect, border);
      for (var j = 1; j < 10; j++) {
        c.drawLine(Offset(x, y + j * 5), Offset(x + 7, y + j * 5), border);
      }
    }
    for (var i = 0; i < u; i++) {
      final p = Offset(
        col * 2 + 12 + (i % 3) * (col - 20) / 3,
        20 + (i ~/ 3) * 22,
      );
      c.drawCircle(p, 5, Paint()..color = mathIndigo);
    }
  }

  @override
  bool shouldRepaint(_ThousandPlacePainter old) => old.value != value;
}
