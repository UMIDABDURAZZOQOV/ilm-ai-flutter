part of 'math_models.dart';

class _ClockDiagramBoard extends StatelessWidget {
  final MathJson scene;
  const _ClockDiagramBoard({required this.scene});
  @override
  Widget build(BuildContext context) {
    final h = (scene['hour_hand'] as List).cast<num>(),
        m = (scene['minute_hand'] as List).cast<num>();
    final hour = ((math.atan2(h[0], -h[1]) * 180 / math.pi + 360) % 360 / 30)
        .floor();
    final mark =
        ((math.atan2(m[0], -m[1]) * 180 / math.pi + 360) % 360 / 30).round() %
        12;
    return Semantics(
      label:
          '${scene['mirrored'] == true ? 'Ko‘zgudagi aks; odatdagi ko‘rinishga qaytarganda' : 'Soat'}: qisqa mil ${hour == 0 ? 12 : hour} va ${hour == 11 ? 12 : hour + 1} oralig‘ida; uzun mil ${mark == 0 ? 12 : mark} bo‘linmasida.',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 250,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(
              scene['mirrored'] == true ? -1 : 1,
              1,
              1,
            ),
            child: CustomPaint(painter: _ClockVectorsPainter(h, m)),
          ),
        ),
      ),
    );
  }
}

class _ClockVectorsPainter extends CustomPainter {
  final List<num> hour, minute;
  _ClockVectorsPainter(this.hour, this.minute);
  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2),
        r = math.min(s.width, s.height) / 2 - 14;
    c.drawCircle(center, r, Paint()..color = Colors.white);
    c.drawCircle(
      center,
      r,
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (int n = 1; n <= 12; n++) {
      final a = (n * 30 - 90) * math.pi / 180;
      final p = center + Offset(math.cos(a), math.sin(a)) * r * .78;
      final t = TextPainter(
        text: TextSpan(
          text: '$n',
          style: const TextStyle(
            fontSize: 16,
            color: mathIndigo,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(c, p - Offset(t.width / 2, t.height / 2));
    }
    c.drawLine(
      center,
      center + Offset(hour[0].toDouble(), hour[1].toDouble()) * r * .48,
      Paint()
        ..color = mathIndigo
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      center,
      center + Offset(minute[0].toDouble(), minute[1].toDouble()) * r * .71,
      Paint()
        ..color = const Color(0xFF0F766E)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(center, 4, Paint()..color = mathIndigo);
  }

  @override
  bool shouldRepaint(_ClockVectorsPainter old) =>
      old.hour.toString() != hour.toString() ||
      old.minute.toString() != minute.toString();
}

class _RosetteSetBoard extends StatelessWidget {
  final MathJson scene;
  final String? selected;
  final ValueChanged<String>? onSelect;
  const _RosetteSetBoard({required this.scene, this.selected, this.onSelect});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final p in mathRows(scene['patterns']))
        Semantics(
          label:
              '${p['id']}: aylana bo‘ylab ${(p['colors'] as List).map((c) => _colorNames[c]).join(', ')}',
          selected: selected == p['id'],
          button: onSelect != null,
          onTap: onSelect == null ? null : () => onSelect!(p['id'] as String),
          child: InkWell(
            onTap: onSelect == null ? null : () => onSelect!(p['id'] as String),
            child: Container(
              width: 108,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected == p['id'] ? mathIndigo : Colors.grey,
                ),
              ),
              child: Column(
                children: [
                  Text((p['id'] as String).toUpperCase()),
                  SizedBox(
                    height: 76,
                    width: 76,
                    child: CustomPaint(
                      painter: _LogicRosettePainter(
                        (p['colors'] as List).cast<String>(),
                        0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class _LogicRosettePainter extends CustomPainter {
  final List<String> colors;
  final int rotation;
  _LogicRosettePainter(this.colors, this.rotation);
  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2),
        r = math.min(s.width, s.height) / 2 - 3;
    for (int i = 0; i < 6; i++) {
      final a = (i + rotation) * math.pi / 3;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r)
        ..lineTo(
          center.dx + math.cos(a + math.pi / 3) * r,
          center.dy + math.sin(a + math.pi / 3) * r,
        )
        ..close();
      c.drawPath(path, Paint()..color = _colors[colors[i]]!);
      c.drawPath(
        path,
        Paint()
          ..color = mathIndigo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    c.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_LogicRosettePainter old) =>
      old.rotation != rotation || old.colors.join() != colors.join();
}

class _Book2LogicExplorer extends StatefulWidget {
  final String mode;
  const _Book2LogicExplorer({required this.mode});
  @override
  State<_Book2LogicExplorer> createState() => _Book2LogicState();
}

class _Book2LogicState extends State<_Book2LogicExplorer> {
  int chosen = 0,
      next = 1,
      main = 0,
      side = 0,
      bar = 3,
      route = 0,
      weight = 1,
      rotation = 0,
      piece = 0,
      x = 0,
      y = 0,
      turn = 0;
  bool mirrored = true, patternMore = false;
  String message = '';
  final bags = <int, int>{};
  final placed = <int, List<(int, int)>>{};
  List<int> boxes = [7, 9, 1], layers = [0, 1, 2];
  static const pieces = <List<(int, int)>>[
    [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)],
    [(0, 0), (1, 0), (0, 1), (1, 1), (1, 2)],
    [(0, 0), (1, 0), (1, 1), (2, 1), (2, 2)],
    [(0, 0), (1, 0), (0, 1), (1, 1), (2, 1)],
  ];
  List<(int, int)> shape() {
    var cells = List<(int, int)>.from(pieces[piece]);
    for (int r = 0; r < turn; r++) {
      cells = cells.map((c) => (-c.$2, c.$1)).toList();
    }
    final minX = cells.map((c) => c.$1).reduce(math.min),
        minY = cells.map((c) => c.$2).reduce(math.min);
    return cells.map((c) => (c.$1 - minX + x, c.$2 - minY + y)).toList();
  }

  void place() {
    final cells = shape();
    final occupied = placed.entries
        .where((e) => e.key != piece)
        .expand((e) => e.value)
        .toSet();
    if (cells.any((c) => c.$1 < 0 || c.$1 >= 4 || c.$2 < 0 || c.$2 >= 5)) {
      message = 'Detal chetdan chiqdi. Joyini yoki burilishini o‘zgartiring.';
    } else if (cells.any(occupied.contains)) {
      message = 'Detallar ustma-ust tushdi. Boshqa joyni sinang.';
    } else {
      placed[piece] = cells;
      message = 'Detal joylandi.';
    }
  }

  void sampleTiling() {
    placed.clear();
    for (final p in [(0, 0, 0), (1, 2, 0), (2, 1, 2), (3, 0, 3)]) {
      placed[p.$1] = pieces[p.$1]
          .map((c) => (c.$1 + p.$2, c.$2 + p.$3))
          .toList();
    }
    message = 'Namuna 20 katakni aynan bir martadan qoplaydi.';
  }

  Widget chip(String key, String title, int n) => ChoiceChip(
    key: ValueKey(key),
    label: Text(title),
    selected: chosen == n,
    onSelected: (_) => setState(() => chosen = n),
  );
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final mode = widget.mode;
    if (mode == 'clock_offsets_overnight') {
      children.addAll([
        const Text('Vaziyat va sana aniq berilsin'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('overnight-0', 'Ertasi kungacha', 0),
            chip('overnight-1', '15 minut orqada', 1),
            chip('overnight-2', 'Dars va tanaffus', 2),
          ],
        ),
        Text(
          chosen == 0
              ? '21:00 → 24:00: 3 soat; ertasi kuni 0:00 → 7:00: 7 soat. Jami 10 soat.'
              : chosen == 1
              ? 'Soat 8:20 ni ko‘rsatadi, 15 minut orqada. Haqiqiy vaqt 8:35. Boshlanish 8:30 bo‘lsa, 5 minut kech.'
              : '40 minut dars + 15 minut tanaffus + 40 minut dars = 95 minut.',
          key: const ValueKey('overnight-result'),
        ),
      ]);
    } else if (mode == 'mixed_review_quantities' ||
        mode == 'book2_final_summary') {
      children.addAll([
        Wrap(
          spacing: 8,
          children: [
            chip('review-0', 'Tenglama', 0),
            chip('review-1', 'Uzunlik', 1),
            chip('review-2', 'Vaqt', 2),
          ],
        ),
        if (chosen == 0)
          const _ThreeDigitEquationExplorer()
        else if (chosen == 1)
          const _MetricLengthExplorer(mode: 'metre_mixed_lengths')
        else
          const _TimeArithmeticExplorer(),
      ]);
    } else if (mode == 'logic_digit_search') {
      final numbers = [7, 2, 13, 5, 11, 1, 9, 15, 4, 12, 6, 3, 14, 8, 10];
      children.addAll([
        const Text('1 dan 15 gacha tartib bilan toping'),
        Text(
          next == 16
              ? 'Barcha 15 son tartib bilan topildi.'
              : 'Keyingi son: $next',
          key: const ValueKey('logic-digit-next'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in numbers)
              Semantics(
                label: '$n',
                child: OutlinedButton(
                  key: ValueKey('logic-digit-$n'),
                  onPressed: n < next
                      ? null
                      : () => setState(() {
                          if (n == next) {
                            next++;
                            message = '';
                          } else {
                            message = 'Navbatdagi sonni tekshiring.';
                          }
                        }),
                  child: Transform.rotate(
                    angle: (n % 3 - 1) * math.pi / 8,
                    child: Text('$n'),
                  ),
                ),
              ),
          ],
        ),
        Text(message),
        OutlinedButton(
          key: const ValueKey('logic-digit-reset'),
          onPressed: () => setState(() => next = 1),
          child: const Text('Yana boshlash'),
        ),
      ]);
    } else if (mode == 'logic_periodic_patterns') {
      children.addAll([
        const Text(
          'Qoida: indigo, sariq, firuza, sariq to‘rtligi takrorlanadi.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < (patternMore ? 12 : 8); i++)
              Chip(
                label: Text(['Indigo', 'Sariq', 'Firuza', 'Sariq'][i % 4]),
                avatar: CircleAvatar(
                  backgroundColor: [
                    mathIndigo,
                    mathYellow,
                    mathTurquoise,
                    mathYellow,
                  ][i % 4],
                ),
              ),
          ],
        ),
        OutlinedButton(
          key: const ValueKey('logic-pattern-more'),
          onPressed: () => setState(() => patternMore = !patternMore),
          child: const Text('Yana bir davrni ochish'),
        ),
        const Text(
          'Sonli qoida alohida: 2, +2 → 4, +3 → 7, +4 → 11, +5 → 16, +6 → 22.',
        ),
      ]);
    } else if (mode == 'logic_menu_pairs') {
      children.addAll([
        const Text('Har asosiy tanlovni har garnir bilan juftlang'),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 0; i < 3; i++)
              ChoiceChip(
                key: ValueKey('logic-main-$i'),
                label: Text(['A', 'B', 'C'][i]),
                selected: main == i,
                onSelected: (_) => setState(() => main = i),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 0; i < 3; i++)
              ChoiceChip(
                key: ValueKey('logic-side-$i'),
                label: Text('G${i + 1}'),
                selected: side == i,
                onSelected: (_) => setState(() => side = i),
              ),
          ],
        ),
        Text(
          '${['A', 'B', 'C'][main]} + G${side + 1}',
          key: const ValueKey('logic-menu-choice'),
        ),
        const Text(
          'A ning 3 jufti, B ning 3 jufti, C ning 3 jufti: 3 + 3 + 3 = 9 tanlov.',
        ),
      ]);
    } else if (mode == 'logic_layer_stack') {
      children.addAll([
        const Text('Original uch qatlam'),
        SizedBox(
          height: 110,
          child: Stack(
            children: [
              for (int i = 2; i >= 0; i--)
                Positioned(
                  left: i * 12.0,
                  top: i * 24.0,
                  child: Container(
                    width: 150,
                    height: 56,
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.all(4),
                    color: [mathIndigo, mathYellow, mathTurquoise][layers[i]],
                    child: Text(
                      ['Indigo', 'Sariq', 'Firuza'][layers[i]],
                      style: TextStyle(
                        color: layers[i] == 0 ? Colors.white : mathIndigo,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          'Tepada: ${['Indigo', 'Sariq', 'Firuza'][layers.first]}',
          key: const ValueKey('logic-top-layer'),
        ),
        OutlinedButton(
          key: const ValueKey('logic-swap-layers'),
          onPressed: () => setState(() {
            final old = layers[0];
            layers[0] = layers[1];
            layers[1] = old;
          }),
          child: const Text('Yuqori ikki qatlamni almashtirish'),
        ),
      ]);
    } else if (mode == 'logic_scaled_bars') {
      children.addAll([
        const Text('7 teng katak 7 metr: har katak 1 metr.'),
        Row(
          children: [
            for (int i = 0; i < 7; i++)
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: i < bar ? mathTurquoise : Colors.white,
                    border: Border.all(color: mathIndigo),
                  ),
                ),
              ),
          ],
        ),
        Text(
          '$bar katak = $bar metr',
          key: const ValueKey('logic-scaled-length'),
        ),
        Slider(
          key: const ValueKey('logic-scale-slider'),
          value: bar.toDouble(),
          min: 0,
          max: 7,
          divisions: 7,
          onChanged: (v) => setState(() => bar = v.round()),
        ),
      ]);
    } else if (mode == 'logic_grid_route') {
      const points = [(0, 0), (4, 0), (4, 2), (0, 2), (0, 0)];
      const sums = [0, 4, 6, 10, 12];
      children.addAll([
        const Text(
          '4 o‘ngga → 2 pastga → 4 chapga → 2 yuqoriga. 1 qadam 1 katak.',
        ),
        SizedBox(
          height: 200,
          child: CustomPaint(painter: _LogicRoutePainter(route)),
        ),
        Text(
          'Manzil: ${points[route].$1},${points[route].$2}; yurilgan ${sums[route]} qadam',
          key: const ValueKey('logic-route-state'),
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('logic-route-reset'),
              onPressed: () => setState(() => route = 0),
              child: const Text('Boshlanish'),
            ),
            FilledButton(
              key: const ValueKey('logic-route-next'),
              onPressed: route == 4 ? null : () => setState(() => route++),
              child: const Text('Keyingi buyruq'),
            ),
          ],
        ),
        const Text(
          'Tutash yo‘l namunasi: A → K → D va B → M → C. A dan chiqish D ga olib boradi.',
        ),
      ]);
    } else if (mode == 'logic_constraint_boxes') {
      children.add(
        const Text(
          '1 toshda emas; 9 toshda ham, kulbada ham emas. Har raqam bir joyda.',
        ),
      );
      for (int i = 0; i < 3; i++) {
        children.add(
          Row(
            children: [
              Expanded(child: Text(['Tosh', 'Daraxt', 'Kulba'][i])),
              DropdownButton<int>(
                key: ValueKey('logic-box-$i'),
                value: boxes[i],
                items: [
                  for (final n in [1, 7, 9])
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) => setState(() {
                  final other = boxes.indexOf(n!);
                  final old = boxes[i];
                  boxes[i] = n;
                  boxes[other] = old;
                }),
              ),
            ],
          ),
        );
      }
      children.addAll([
        Text(
          'Shartlar: ${boxes[0] != 1 && boxes[0] != 9 && boxes[2] != 9 ? 'mos' : 'hali mos emas'}',
          key: const ValueKey('logic-box-result'),
        ),
        const Text(
          'Tosh 7, daraxt 9, kulba 1 namunasini barcha shartlarda tekshiring.',
        ),
      ]);
    } else if (mode == 'logic_equal_bags') {
      children.addAll([
        const Text(
          '1–7 kg li har yukni bitta guruhga qo‘ying. Maqsad: 4 guruh 7 kg dan.',
        ),
        Wrap(
          spacing: 8,
          children: [
            for (int n = 1; n <= 7; n++)
              ChoiceChip(
                key: ValueKey('logic-weight-$n'),
                label: Text('$n kg'),
                selected: weight == n,
                onSelected: (_) => setState(() => weight = n),
              ),
          ],
        ),
      ]);
      for (int group = 1; group <= 4; group++) {
        final weights =
            bags.entries
                .where((e) => e.value == group)
                .map((e) => e.key)
                .toList()
              ..sort();
        final sum = weights.fold(0, (int a, b) => a + b);
        children.add(
          OutlinedButton(
            key: ValueKey('logic-bag-$group'),
            onPressed: () => setState(() => bags[weight] = group),
            child: Text('$group-guruh: ${weights.join('+')} = $sum kg'),
          ),
        );
      }
      final sums = [
        for (int i = 1; i <= 4; i++)
          bags.entries
              .where((e) => e.value == i)
              .fold(0, (int a, e) => a + e.key),
      ];
      children.addAll([
        Text(
          bags.length == 7 && sums.every((s) => s == 7)
              ? 'To‘rtta guruh 7 kg dan; har yuk bir marta.'
              : 'Joylashishni davom ettiring.',
          key: const ValueKey('logic-bags-result'),
        ),
        OutlinedButton(
          key: const ValueKey('logic-bags-example'),
          onPressed: () => setState(() {
            bags.clear();
            bags.addAll({7: 1, 1: 2, 6: 2, 2: 3, 5: 3, 3: 4, 4: 4});
          }),
          child: const Text('Namunani ochish'),
        ),
        OutlinedButton(
          key: const ValueKey('logic-bags-reset'),
          onPressed: () => setState(bags.clear),
          child: const Text('Tozalash'),
        ),
      ]);
    } else if (mode == 'logic_tiling_lab') {
      children.addAll([
        const Text(
          '4 × 5 katak. 4 tutash detalning har biri 5 katak. Chetdan chiqmasin, ustma-ust tushmasin.',
        ),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 0; i < 4; i++)
              ChoiceChip(
                key: ValueKey('logic-piece-$i'),
                label: Text(['A', 'B', 'C', 'D'][i]),
                selected: piece == i,
                onSelected: (_) => setState(() => piece = i),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            DropdownButton<int>(
              key: const ValueKey('logic-piece-x'),
              isExpanded: true,
              value: x,
              items: [
                for (int n = 0; n < 4; n++)
                  DropdownMenuItem(value: n, child: Text('Ustun ${n + 1}')),
              ],
              onChanged: (n) => setState(() => x = n!),
            ),
            DropdownButton<int>(
              key: const ValueKey('logic-piece-y'),
              isExpanded: true,
              value: y,
              items: [
                for (int n = 0; n < 5; n++)
                  DropdownMenuItem(value: n, child: Text('Qator ${n + 1}')),
              ],
              onChanged: (n) => setState(() => y = n!),
            ),
          ],
        ),
        Text('Burilish: ${turn * 90}°'),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('logic-piece-rotate'),
              onPressed: () => setState(() => turn = (turn + 1) % 4),
              child: const Text('90° burish'),
            ),
            FilledButton(
              key: const ValueKey('logic-piece-place'),
              onPressed: () => setState(place),
              child: const Text('Joylash'),
            ),
          ],
        ),
      ]);
      for (int row = 0; row < 5; row++) {
        children.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int col = 0; col < 4; col++)
                Builder(
                  builder: (_) {
                    final owner = placed.entries
                        .where((e) => e.value.contains((col, row)))
                        .map((e) => e.key)
                        .firstOrNull;
                    return Semantics(
                      label:
                          'Qator ${row + 1}, ustun ${col + 1}: ${owner == null ? 'bo‘sh' : ['A', 'B', 'C', 'D'][owner]}',
                      child: InkWell(
                        onTap: () => setState(() {
                          x = col;
                          y = row;
                        }),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: owner == null
                                ? Colors.white
                                : [
                                    mathIndigo,
                                    mathYellow,
                                    mathTurquoise,
                                    const Color(0xFFDDD6FE),
                                  ][owner],
                            border: Border.all(color: mathIndigo),
                          ),
                          child: Text(
                            owner == null ? '·' : ['A', 'B', 'C', 'D'][owner],
                            style: TextStyle(
                              color: owner == 0 ? Colors.white : mathIndigo,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }
      final covered = placed.values.expand((v) => v).toSet().length;
      children.addAll([
        Text(
          'Qoplangan: $covered / 20',
          key: const ValueKey('logic-tiling-covered'),
        ),
        Text(message, key: const ValueKey('logic-tiling-feedback')),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('logic-piece-remove'),
              onPressed: () => setState(() => placed.remove(piece)),
              child: const Text('Tanlanganini olish'),
            ),
            OutlinedButton(
              key: const ValueKey('logic-tiling-example'),
              onPressed: () => setState(sampleTiling),
              child: const Text('Namunani ochish'),
            ),
            OutlinedButton(
              key: const ValueKey('logic-tiling-reset'),
              onPressed: () => setState(() {
                placed.clear();
                message = '';
              }),
              child: const Text('Tozalash'),
            ),
          ],
        ),
      ]);
    } else if (mode == 'logic_hourglass_interval') {
      children.addAll([
        const Text(
          'Ikkala soat bir paytda boshlanadi: 0. 3 minutlik tugaganda interval boshlanadi, 7 minutlik tugaganda tugaydi.',
        ),
        const Wrap(
          spacing: 20,
          children: [
            Icon(Icons.hourglass_bottom, color: mathIndigo, size: 48),
            Icon(Icons.hourglass_bottom, color: mathIndigo, size: 64),
          ],
        ),
        Text(
          chosen == 0
              ? '0: ikkalasi boshlandi.'
              : chosen == 1
              ? '3 minut: birinchi tugadi; endi interval boshlanadi.'
              : '7 minut: ikkinchi tugadi; interval 7 − 3 = 4 minut.',
          key: const ValueKey('logic-hourglass-state'),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 0; i < 3; i++)
              chip('hourglass-$i', ['0', '3', '7'][i], i),
          ],
        ),
        const Text(
          'Bu 4 minutlik interval 0 dan emas, 3 dan 7 gacha. Haqiqiy qum soati tajribasi bajarildi degani emas.',
        ),
      ]);
    } else if (mode == 'logic_mirror_clock') {
      final r = const MathClockReading(3, 25);
      children.addAll([
        const Text(
          'Original namuna 3:25. Barcha raqam va millar birga aks etadi.',
        ),
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(mirrored ? -1 : 1, 1, 1),
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(painter: _TeachingClockPainter(r)),
          ),
        ),
        OutlinedButton(
          key: const ValueKey('logic-clock-mirror'),
          onPressed: () => setState(() => mirrored = !mirrored),
          child: Text(
            mirrored ? 'Oddiy ko‘rinishga qaytarish' : 'Ko‘zguga aks ettirish',
          ),
        ),
        Text(
          mirrored ? 'Ko‘zgudagi aks' : 'Asl 3:25',
          key: const ValueKey('logic-clock-view'),
        ),
      ]);
    } else if (mode == 'logic_rosette_pairs') {
      children.addAll([
        const Text(
          'Ranglar aylana bo‘ylab bir tartibda qolsa, butun naqshni burish uning turini o‘zgartirmaydi.',
        ),
        SizedBox(
          height: 140,
          child: CustomPaint(
            painter: _LogicRosettePainter(const [
              'indigo',
              'yellow',
              'turquoise',
              'indigo',
              'yellow',
              'turquoise',
            ], rotation),
          ),
        ),
        OutlinedButton(
          key: const ValueKey('logic-rosette-turn'),
          onPressed: () => setState(() => rotation = (rotation + 1) % 6),
          child: const Text('60° burish'),
        ),
        Text(
          'Burilish: ${rotation * 60}°. Ko‘zguga aks ettirish alohida amal.',
        ),
      ]);
    }
    children.add(
      const Text(
        'Namunani o‘rganing,so‘ng mustaqil mashqqa o‘ting. Fizik tajriba bajarilganini bu model tasdiqlamaydi.',
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _LogicRoutePainter extends CustomPainter {
  final int step;
  _LogicRoutePainter(this.step);
  @override
  void paint(Canvas c, Size s) {
    final scale = math.min((s.width - 40) / 5, (s.height - 40) / 3);
    const points = [(0, 0), (4, 0), (4, 2), (0, 2), (0, 0)];
    Offset at((int, int) p) => Offset(20 + p.$1 * scale, 20 + p.$2 * scale);
    for (int x = 0; x <= 5; x++) {
      c.drawLine(
        Offset(20 + x * scale, 20),
        Offset(20 + x * scale, 20 + 3 * scale),
        Paint()..color = const Color(0xFFDDD6FE),
      );
    }
    for (int y = 0; y <= 3; y++) {
      c.drawLine(
        Offset(20, 20 + y * scale),
        Offset(20 + 5 * scale, 20 + y * scale),
        Paint()..color = const Color(0xFFDDD6FE),
      );
    }
    final path = Path()..moveTo(at(points[0]).dx, at(points[0]).dy);
    for (final p in points.take(step + 1).skip(1)) {
      path.lineTo(at(p).dx, at(p).dy);
    }
    c.drawPath(
      path,
      Paint()
        ..color = mathIndigo
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    c.drawCircle(at(points[step]), 5, Paint()..color = mathTurquoise);
  }

  @override
  bool shouldRepaint(_LogicRoutePainter old) => old.step != step;
}
