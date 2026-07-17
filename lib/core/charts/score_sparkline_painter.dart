import 'package:flutter/material.dart';

/// Ported from ilm-ai-mobile's ScoreSparkline.tsx: a filled trend line over
/// the last N quiz score percentages, no charting library.
class ScoreSparkline extends StatelessWidget {
  final List<double> values; // 0-100 scale
  final double height;

  const ScoreSparkline({super.key, required this.values, this.height = 64});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, height),
        painter: _SparklinePainter(values: values, lineColor: theme.colorScheme.primary, fillColor: theme.colorScheme.primary.withValues(alpha: 0.12)),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({required this.values, required this.lineColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final stepX = size.width / (values.length - 1);
    Offset pointAt(int i) {
      final normalized = (values[i] - minV) / range;
      return Offset(stepX * i, size.height - normalized * size.height * 0.85 - size.height * 0.075);
    }

    final linePath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      linePath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(pointAt(values.length - 1).dx, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(pointAt(i), 2.5, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values;
}
