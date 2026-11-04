import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../data/math_repository.dart';
part 'elementary_explorer.dart';
part 'arithmetic_explorer.dart';
part 'concrete_number_explorer.dart';
part 'number_properties_explorer.dart';
part 'point_line_explorer.dart';
part 'unknown_number_explorer.dart';
part 'segment_explorer.dart';
part 'operation_properties_explorer.dart';
part 'place_value_explorer.dart';
part 'bracket_explorer.dart';
part 'ten_strategy_explorer.dart';
part 'hundred_explorer.dart';
part 'two_digit_explorer.dart';

const mathIndigo = Color(0xFF2A1F6B);
const mathYellow = Color(0xFFF9A825);
const mathTurquoise = Color(0xFF2DD4BF);
const _names = {
  'circle': 'doira',
  'square': 'kvadrat',
  'triangle': 'uchburchak',
  'rectangle': 'to‘g‘ri to‘rtburchak',
  'sphere': 'shar modeli chizmasi',
  'cube': 'kub modeli chizmasi',
};
const _colors = {
  'indigo': mathIndigo,
  'yellow': mathYellow,
  'turquoise': mathTurquoise,
};
const _colorNames = {
  'indigo': 'indigo',
  'yellow': 'sariq',
  'turquoise': 'turkuaz',
};

/// Original geometry. Shape and bar lengths share one consistent board scale.
class MathBoard extends StatelessWidget {
  final MathJson scene;
  final String? selected;
  final ValueChanged<String>? onSelect;
  const MathBoard({
    super.key,
    required this.scene,
    this.selected,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = mathRows(scene['items']);
    final bars = scene['type'] == 'bars';
    return LayoutBuilder(
      builder: (context, bounds) {
        final width = bounds.maxWidth;
        return SizedBox(
          height: 250,
          child: Stack(
            children: [
              for (final item in items)
                Positioned(
                  left: bars
                      ? 8
                      : 8 + (width - 96) * (item['x'] as num).toDouble(),
                  top: 8 + 140 * (item['y'] as num).toDouble(),
                  width: bars ? width - 16 : 80,
                  height: bars ? 56 : 90,
                  child: Semantics(
                    label:
                        '${(item['id'] as String).toUpperCase()}: ${_colorNames[item['color']]}, ${_names[item['shape']]}.',
                    value:
                        '${(item['x'] as num) < .4
                            ? 'Doskaning chap qismida'
                            : (item['x'] as num) > .6
                            ? 'Doskaning o‘ng qismida'
                            : 'Doskaning o‘rta qismida'}, ${(item['y'] as num) < .4
                            ? 'teparoqda'
                            : (item['y'] as num) > .6
                            ? 'pastroqda'
                            : 'o‘rta balandlikda'}.',
                    onTap: onSelect == null
                        ? null
                        : () => onSelect!(item['id'] as String),
                    button: onSelect != null,
                    selected: item['id'] == selected,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onSelect == null
                            ? null
                            : () => onSelect!(item['id'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: ExcludeSemantics(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: item['id'] == selected
                                    ? mathIndigo
                                    : Colors.transparent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: bars
                                ? Row(
                                    children: [
                                      Text(
                                        (item['id'] as String).toUpperCase(),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor:
                                                (item['size'] as num)
                                                    .toDouble() *
                                                .6,
                                            child: Container(
                                              height: 20,
                                              color: _colors[item['color']],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: SizedBox.square(
                                            dimension:
                                                34 *
                                                (item['size'] as num)
                                                    .toDouble(),
                                            child: CustomPaint(
                                              painter: MathShapePainter(
                                                item['shape'] as String,
                                                _colors[item['color']]!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        (item['id'] as String).toUpperCase(),
                                        style: const TextStyle(
                                          color: mathIndigo,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class MathShapePainter extends CustomPainter {
  final String shape;
  final Color color;
  const MathShapePainter(this.shape, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = mathIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    if (shape == 'triangle') {
      final p = Path()
        ..moveTo(size.width / 2, 1)
        ..lineTo(size.width - 1, size.height - 1)
        ..lineTo(1, size.height - 1)
        ..close();
      canvas.drawPath(p, fill);
      canvas.drawPath(p, stroke);
    } else if (shape == 'square' || shape == 'rectangle') {
      canvas.drawRect(r.deflate(1), fill);
      canvas.drawRect(r.deflate(1), stroke);
    } else if (shape == 'cube') {
      final w = size.width, h = size.height;
      final front = Path()
        ..moveTo(1, h * .25)
        ..lineTo(w * .72, h * .25)
        ..lineTo(w * .72, h - 1)
        ..lineTo(1, h - 1)
        ..close();
      final top = Path()
        ..moveTo(1, h * .25)
        ..lineTo(w * .25, 1)
        ..lineTo(w - 1, 1)
        ..lineTo(w * .72, h * .25)
        ..close();
      final side = Path()
        ..moveTo(w * .72, h * .25)
        ..lineTo(w - 1, 1)
        ..lineTo(w - 1, h * .72)
        ..lineTo(w * .72, h - 1)
        ..close();
      canvas.drawPath(front, fill);
      canvas.drawPath(
        top,
        Paint()..color = Color.lerp(color, Colors.white, .4)!,
      );
      canvas.drawPath(
        side,
        Paint()..color = Color.lerp(color, mathIndigo, .3)!,
      );
      for (final p in [front, top, side]) {
        canvas.drawPath(p, stroke);
      }
    } else {
      if (shape == 'sphere') {
        fill.shader = RadialGradient(
          center: const Alignment(-.4, -.4),
          colors: [Color.lerp(color, Colors.white, .55)!, color, mathIndigo],
        ).createShader(r);
      }
      canvas.drawOval(r.deflate(1), fill);
      canvas.drawOval(r.deflate(1), stroke);
    }
  }

  @override
  bool shouldRepaint(MathShapePainter old) =>
      old.shape != shape || old.color != color;
}

/// Testable elementary models. No graph/CAS/3D capability is implied by these.
class MathExplorer extends StatefulWidget {
  final String mode;
  const MathExplorer({super.key, required this.mode});
  @override
  State<MathExplorer> createState() => _MathExplorerState();
}

class _MathExplorerState extends State<MathExplorer> {
  String shape = 'circle', color = 'turquoise';
  double amount = 1;
  final Set<String> touched = {};
  @override
  Widget build(BuildContext context) {
    MathJson item(
      String id,
      String form,
      double x, {
      double y = .5,
      double size = 1,
    }) => {
      'id': id,
      'shape': form,
      'color': color,
      'size': size,
      'x': x,
      'y': y,
    };
    final mode = widget.mode;
    if ({
      'two_digit_addition',
      'two_digit_missing_addend',
      'two_digit_subtraction',
      'two_digit_inverse',
    }.contains(mode)) {
      return _TwoDigitExplorer(mode: mode);
    }
    if (mode == 'compare_place_value_100') {
      return const _PlaceComparisonExplorer(large: true);
    }
    if ({
      'round_tens_100',
      'hundred_chart',
      'place_value_100',
      'abacus_100',
    }.contains(mode)) {
      return _HundredExplorer(mode: mode);
    }
    if ({
      'bridge_ten_intro',
      'bridge_ten_apply',
      'bridge_ten_line',
      'subtract_units_20',
      'subtract_bridge_ten',
      'subtract_from_ten',
    }.contains(mode)) {
      return _TenStrategyExplorer(mode: mode);
    }
    if (mode == 'compare_place_value_20') {
      return const _PlaceComparisonExplorer();
    }
    if (mode == 'brackets_single' || mode == 'brackets_double') {
      return _BracketExplorer(mode: mode);
    }
    if ({
      'tens_units_20',
      'number_pairs_12',
      'number_pairs_14',
      'number_pairs_16',
      'number_pairs_18',
      'number_pairs_20',
    }.contains(mode)) {
      return _PlaceValueExplorer(mode: mode);
    }
    if ({
      'commutative',
      'addition_table',
      'compare_same_addend',
      'expression_steps',
    }.contains(mode)) {
      return _OperationPropertiesExplorer(mode: mode);
    }
    if (mode == 'segments') return const _SegmentExplorer();
    if ({
      'missing_addend',
      'missing_minuend',
      'missing_subtrahend',
    }.contains(mode)) {
      return _UnknownNumberExplorer(mode: mode);
    }
    if ({'natural_numbers', 'parity', 'ordering_numbers'}.contains(mode)) {
      return _NumberPropertiesExplorer(mode: mode);
    }
    if (mode == 'point_line') return const _PointLineExplorer();
    if ({
      'compose_three',
      'compose_four',
      'compose_five',
      'compose_six',
      'compose_seven',
      'compose_eight',
      'compose_nine',
      'compose_ten',
      'zero',
      'part_whole_five',
      'inverse_family',
      'steps_five',
    }.contains(mode)) {
      return _ConcreteNumberExplorer(mode: mode);
    }
    if ({'addition', 'subtraction', 'comparison', 'one_two'}.contains(mode)) {
      return _ArithmeticExplorer(mode: mode);
    }
    if ({
      'timeline',
      'group_members',
      'pair_groups',
      'number_line',
    }.contains(mode)) {
      return _ElementaryExplorer(mode: mode);
    }
    final items = mode == 'count_once'
        ? List.generate(
            4,
            (i) => item('s${i + 1}', 'circle', .15 + .23 * i, size: .7),
          )
        : mode == 'compare_lengths'
        ? [
            item('a', 'rectangle', .1, y: .25, size: 1),
            item('b', 'rectangle', .1, y: .7, size: amount),
          ]
        : mode == 'positions'
        ? [
            item('a', 'circle', .1 + amount * .6, y: .25),
            item('b', 'square', .5, y: .7),
          ]
        : mode == 'flat_solid'
        ? [
            item('a', shape == 'circle' ? 'circle' : 'square', .2),
            item('b', shape == 'circle' ? 'sphere' : 'cube', .8),
          ]
        : [item('a', shape, .5, size: amount)];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ilmo bilan sinab ko‘r',
              style: TextStyle(fontWeight: FontWeight.bold, color: mathIndigo),
            ),
            MathBoard(
              scene: {
                'type': mode == 'compare_lengths' ? 'bars' : 'shape_board',
                'items': items,
              },
              selected: touched.isEmpty ? null : touched.last,
              onSelect: mode == 'count_once'
                  ? (id) => setState(() => touched.add(id))
                  : null,
            ),
            if (mode == 'count_once') ...[
              Text(
                'Bir martadan tegilgan shakllar: ${touched.length}. Yana o‘sha shaklga tegsang, sanoq ortmaydi.',
                semanticsLabel:
                    'Bir martadan tegilgan shakllar ${touched.length}.',
              ),
              TextButton(
                onPressed: () => setState(touched.clear),
                child: const Text('Sanashni qaytadan boshlash'),
              ),
            ] else ...[
              if (mode == 'shape_properties' || mode == 'flat_solid')
                Wrap(
                  spacing: 8,
                  children: [
                    for (final form
                        in mode == 'flat_solid'
                            ? ['circle', 'square']
                            : ['circle', 'square', 'triangle'])
                      ChoiceChip(
                        label: Text(_names[form]!),
                        selected: shape == form,
                        onSelected: (_) => setState(() => shape = form),
                      ),
                  ],
                ),
              if (mode == 'shape_properties')
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in _colors.keys)
                      ChoiceChip(
                        label: Text(_colorNames[c]!),
                        selected: color == c,
                        onSelected: (_) => setState(() => color = c),
                      ),
                  ],
                ),
              if (mode != 'flat_solid')
                Slider(
                  value: amount,
                  min: .5,
                  max: 1.3,
                  divisions: 8,
                  semanticFormatterCallback: (v) => mode == 'positions'
                      ? (v < 2 / 3
                            ? 'Doira kvadratdan chapda'
                            : 'Doira kvadratdan o‘ngda')
                      : 'Kattalikni o‘zgartirish',
                  onChanged: (v) => setState(() => amount = v),
                ),
              Text(
                mode == 'flat_solid'
                    ? 'Chapda yassi shakl, o‘ngda hajmli buyumning chizmasi. Bu haqiqiy 3D o‘lchash modeli emas.'
                    : mode == 'positions'
                    ? 'Doirani siljit. Chap va o‘ngni kvadratga nisbatan tekshir.'
                    : mode == 'compare_lengths'
                    ? 'Ikkala tasma bir joydan boshlanadi. B tasmani o‘zgartirib, uzunliklarini taqqosla.'
                    : 'Rang yoki kattalikni o‘zgartirsang ham, tanlangan shaklning nomi o‘zgarmaydi.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
