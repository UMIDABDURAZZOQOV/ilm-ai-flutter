import 'package:flutter/material.dart';

import '../../features/math_solver/data/math_models.dart';

/// Ported from ilm-ai-mobile's MathGraphPlot.tsx: samples the function over
/// x in [-10, 10] at 61 points, auto-scales the y-axis with 10% padding
/// (falling back to a +-1 spread for constant functions), then draws axes +
/// the sampled curve. A pure client-side plot, no charting library.
class MathGraphPlot extends StatelessWidget {
  final MathGraph graph;
  final double width;
  final double height;

  const MathGraphPlot({super.key, required this.graph, this.width = 280, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context);
    return CustomPaint(
      size: Size(width, height),
      painter: _MathGraphPainter(
        graph: graph,
        axisColor: colors.dividerColor,
        curveColor: colors.colorScheme.primary,
        labelColor: colors.hintColor,
      ),
    );
  }
}

class _MathGraphPainter extends CustomPainter {
  final MathGraph graph;
  final Color axisColor;
  final Color curveColor;
  final Color labelColor;

  _MathGraphPainter({required this.graph, required this.axisColor, required this.curveColor, required this.labelColor});

  @override
  void paint(Canvas canvas, Size size) {
    const domainMin = -10.0;
    const domainMax = 10.0;
    const sampleCount = 61;
    final step = (domainMax - domainMin) / (sampleCount - 1);

    final points = <Offset>[];
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    final rawPoints = <(double, double)>[];
    for (var i = 0; i < sampleCount; i++) {
      final x = domainMin + step * i;
      final y = graph.evaluate(x);
      rawPoints.add((x, y));
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    if (minY > 0) minY = 0;
    if (maxY < 0) maxY = 0;
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final pad = (maxY - minY) * 0.1;
    minY -= pad;
    maxY += pad;

    double toSvgX(double x) => (x - domainMin) / (domainMax - domainMin) * size.width;
    double toSvgY(double y) => size.height - (y - minY) / (maxY - minY) * size.height;

    for (final (x, y) in rawPoints) {
      points.add(Offset(toSvgX(x), toSvgY(y)));
    }

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    // X axis (y=0) and Y axis (x=0), only drawn if within the visible range.
    if (minY <= 0 && maxY >= 0) {
      final y0 = toSvgY(0);
      canvas.drawLine(Offset(0, y0), Offset(size.width, y0), axisPaint);
    }
    if (domainMin <= 0 && domainMax >= 0) {
      final x0 = toSvgX(0);
      canvas.drawLine(Offset(x0, 0), Offset(x0, size.height), axisPaint);
    }

    // Origin marker
    if (minY <= 0 && maxY >= 0 && domainMin <= 0 && domainMax >= 0) {
      canvas.drawCircle(Offset(toSvgX(0), toSvgY(0)), 2.5, Paint()..color = axisColor);
    }

    // Curve
    final curvePaint = Paint()
      ..color = curveColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, curvePaint);

    // Axis-end labels
    _drawText(canvas, 'x', Offset(size.width - 12, size.height / 2 + 4), labelColor);
    _drawText(canvas, 'y', Offset(size.width / 2 + 4, 4), labelColor);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MathGraphPainter oldDelegate) => oldDelegate.graph != graph;
}
