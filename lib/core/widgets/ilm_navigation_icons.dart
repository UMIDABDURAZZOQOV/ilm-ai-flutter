import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single 32-unit vector grid for ILM AI's five learning destinations.
/// These illustrations describe destinations, never user status or rewards.
enum IlmNavIcon { learn, practice, quests, league, profile }

class IlmNavigationIcon extends StatelessWidget {
  const IlmNavigationIcon({
    super.key,
    required this.icon,
    required this.progress,
    required this.color,
    required this.accent,
  });
  final IlmNavIcon icon;
  final double progress;
  final Color color, accent;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 30,
    child: CustomPaint(
      painter: _NavigationIconPainter(icon, progress, color, accent),
    ),
  );
}

class _NavigationIconPainter extends CustomPainter {
  const _NavigationIconPainter(
    this.icon,
    this.progress,
    this.color,
    this.accent,
  );
  final IlmNavIcon icon;
  final double progress;
  final Color color, accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final detail = Paint()
      ..color = Color.lerp(color, accent, progress)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pulse = math.sin(progress * math.pi);
    switch (icon) {
      case IlmNavIcon.learn:
        canvas.drawPath(
          Path()
            ..moveTo(16, 9)
            ..cubicTo(12, 6, 8, 6, 4, 7)
            ..lineTo(4, 25)
            ..cubicTo(8, 24, 12, 24, 16, 27)
            ..cubicTo(20, 24, 24, 24, 28, 25)
            ..lineTo(28, 7)
            ..cubicTo(24, 6, 20, 6, 16, 9)
            ..lineTo(16, 27),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 12)
            ..quadraticBezierTo(10, 11.8, 12, 13)
            ..moveTo(8, 17)
            ..quadraticBezierTo(10, 16.8, 12, 18),
          line,
        );
        canvas.save();
        canvas.translate(20, 10);
        canvas.rotate(-pulse * .18);
        canvas.drawPath(
          Path()
            ..moveTo(0, 2)
            ..quadraticBezierTo(2, .8, 4, 1)
            ..moveTo(0, 7)
            ..quadraticBezierTo(2, 5.8, 4, 6),
          detail,
        );
        canvas.restore();
      case IlmNavIcon.practice:
        canvas.save();
        canvas.translate(16, 15);
        canvas.rotate(math.pi / 4 + pulse * .12);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(-3.5, -11, 3.5, 6),
            const Radius.circular(1.5),
          ),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-3.5, 6)
            ..lineTo(0, 12)
            ..lineTo(3.5, 6),
          line,
        );
        canvas.drawLine(const Offset(-3.5, -6), const Offset(3.5, -6), detail);
        canvas.restore();
        _drawProgress(
          canvas,
          Path()
            ..moveTo(18, 27)
            ..quadraticBezierTo(22, 24, 28, 26),
          detail,
          progress,
        );
      case IlmNavIcon.quests:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(6, 7, 26, 28),
            const Radius.circular(4),
          ),
          line,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(11, 4, 21, 10),
            const Radius.circular(2.5),
          ),
          Paint()..color = color.withValues(alpha: .10 + progress * .08),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(11, 4, 21, 10),
            const Radius.circular(2.5),
          ),
          line,
        );
        for (final y in [16.0, 22.0]) {
          canvas.drawLine(Offset(17, y), Offset(22, y), line);
          if (progress == 0) {
            canvas.drawLine(Offset(10, y), Offset(12, y), line);
          } else {
            _drawProgress(
              canvas,
              Path()
                ..moveTo(9, y)
                ..lineTo(11, y + 2)
                ..lineTo(14, y - 2),
              detail,
              progress,
            );
          }
        }
      case IlmNavIcon.league:
        canvas.drawPath(
          Path()
            ..moveTo(16, 3)
            ..lineTo(27, 7)
            ..lineTo(26, 17)
            ..cubicTo(25, 22, 21, 27, 16, 29)
            ..cubicTo(11, 27, 7, 22, 6, 17)
            ..lineTo(5, 7)
            ..close(),
          line,
        );
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final angle = -math.pi / 2 + i * math.pi / 5 + pulse * .12;
          final radius = i.isEven ? 5.8 : 2.7;
          final x = 16 + math.cos(angle) * radius,
              y = 15 + math.sin(angle) * radius;
          if (i == 0) {
            star.moveTo(x, y);
          } else {
            star.lineTo(x, y);
          }
        }
        star.close();
        if (progress > 0) {
          canvas.drawPath(
            star,
            Paint()..color = accent.withValues(alpha: progress * .22),
          );
        }
        canvas.drawPath(star, detail);
      case IlmNavIcon.profile:
        canvas.save();
        canvas.translate(16, 10);
        canvas.rotate(pulse * .12);
        canvas.drawOval(const Rect.fromLTRB(-5, -5.5, 5, 5.5), line);
        canvas.restore();
        canvas.drawPath(
          Path()
            ..moveTo(5, 28)
            ..lineTo(5, 26)
            ..cubicTo(5, 21, 9, 18, 16, 18)
            ..cubicTo(23, 18, 27, 21, 27, 26)
            ..lineTo(27, 28),
          line,
        );
        _drawProgress(
          canvas,
          Path()
            ..moveTo(12, 24)
            ..quadraticBezierTo(16, 21.5, 20, 24),
          detail,
          progress,
        );
    }
    canvas.restore();
  }

  void _drawProgress(Canvas canvas, Path path, Paint paint, double value) {
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * value.clamp(0, 1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NavigationIconPainter oldDelegate) =>
      oldDelegate.icon != icon ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.accent != accent;
}
