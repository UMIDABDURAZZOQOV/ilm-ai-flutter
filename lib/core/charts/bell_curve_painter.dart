import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ported from ilm-ai-mobile's CollegeDetailScreen bell-curve chart: a fixed
/// normal-distribution curve over the 400-1600 SAT range with a marker line
/// at the college's median SAT score.
class BellCurveChart extends StatelessWidget {
  final int medianSat;
  final double width;
  final double height;

  const BellCurveChart({super.key, required this.medianSat, this.width = 300, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      size: Size(width, height),
      painter: _BellCurvePainter(
        medianSat: medianSat,
        curveColor: theme.colorScheme.primary,
        fillColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        markerColor: theme.colorScheme.secondary,
        labelColor: theme.hintColor,
      ),
    );
  }
}

class _BellCurvePainter extends CustomPainter {
  static const double satMin = 400;
  static const double satMax = 1600;
  static const double mean = 1050; // rough national SAT mean, fixed reference curve
  static const double stdDev = 200;

  final int medianSat;
  final Color curveColor;
  final Color fillColor;
  final Color markerColor;
  final Color labelColor;

  _BellCurvePainter({
    required this.medianSat,
    required this.curveColor,
    required this.fillColor,
    required this.markerColor,
    required this.labelColor,
  });

  double _gaussian(double x) => math.exp(-0.5 * math.pow((x - mean) / stdDev, 2));

  @override
  void paint(Canvas canvas, Size size) {
    const sampleCount = 80;
    final points = <Offset>[];
    var maxDensity = 0.0;
    for (var i = 0; i <= sampleCount; i++) {
      final x = satMin + (satMax - satMin) * i / sampleCount;
      final d = _gaussian(x);
      if (d > maxDensity) maxDensity = d;
    }

    double toX(double sat) => (sat - satMin) / (satMax - satMin) * size.width;
    double toY(double density) => size.height - (density / maxDensity) * size.height * 0.9;

    for (var i = 0; i <= sampleCount; i++) {
      final x = satMin + (satMax - satMin) * i / sampleCount;
      points.add(Offset(toX(x), toY(_gaussian(x))));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = curveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Median marker line
    final markerX = toX(medianSat.toDouble().clamp(satMin, satMax));
    canvas.drawLine(
      Offset(markerX, 0),
      Offset(markerX, size.height),
      Paint()
        ..color = markerColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(Offset(markerX, toY(_gaussian(medianSat.toDouble()))), 4, Paint()..color = markerColor);

    // Axis labels (min/max SAT)
    _drawText(canvas, '$satMin', Offset(2, size.height + 2), labelColor);
    final maxLabel = '${satMax.toInt()}';
    final maxLabelWidth = maxLabel.length * 6.5;
    _drawText(canvas, maxLabel, Offset(size.width - maxLabelWidth, size.height + 2), labelColor);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BellCurvePainter oldDelegate) => oldDelegate.medianSat != medianSat;
}
