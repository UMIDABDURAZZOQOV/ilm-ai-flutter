import 'package:flutter/material.dart';

enum IllustrationVariant { materials, math, chat, quiz, plan }

/// Ported from ilm-ai-mobile's OnboardingIllustration.tsx -- original,
/// simple geometric hero graphics per onboarding slide, drawn with
/// CustomPainter (mirrors the RN version's react-native-svg shapes) so no
/// external illustration assets are needed.
class OnboardingIllustration extends StatelessWidget {
  final IllustrationVariant variant;
  final double size;
  final Color tintBg;
  final Color tintBorder;
  final Color accent;

  const OnboardingIllustration({
    super.key,
    required this.variant,
    this.size = 240,
    required this.tintBg,
    required this.tintBorder,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tintBg, borderRadius: BorderRadius.circular(32), border: Border.all(color: tintBorder, width: 1.5)),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size * 0.6, size * 0.6),
        painter: _ScenePainter(variant: variant, accent: accent),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  final IllustrationVariant variant;
  final Color accent;
  _ScenePainter({required this.variant, required this.accent});

  // All scenes are authored against a 100x100 viewBox, like the RN version.
  double _sx(Size size) => size.width / 100;
  double _sy(Size size) => size.height / 100;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(_sx(size), _sy(size));
    switch (variant) {
      case IllustrationVariant.materials:
        _materials(canvas);
        break;
      case IllustrationVariant.math:
        _math(canvas);
        break;
      case IllustrationVariant.chat:
        _chat(canvas);
        break;
      case IllustrationVariant.quiz:
        _quiz(canvas);
        break;
      case IllustrationVariant.plan:
        _plan(canvas);
        break;
    }
    canvas.restore();
  }

  Paint _fill(Color c, [double opacity = 1]) => Paint()..color = c.withValues(alpha: opacity);
  Paint _stroke(Color c, double width, [double opacity = 1]) => Paint()
    ..color = c.withValues(alpha: opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  RRect _rrect(double x, double y, double w, double h, double r) => RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  void _materials(Canvas canvas) {
    canvas.drawRRect(_rrect(20, 30, 60, 45, 6), _fill(Colors.white, 0.9));
    canvas.drawRRect(_rrect(28, 42, 44, 5, 2.5), _fill(accent, 0.5));
    canvas.drawRRect(_rrect(28, 53, 34, 5, 2.5), _fill(accent, 0.35));
    canvas.drawRRect(_rrect(28, 64, 24, 5, 2.5), _fill(accent, 0.25));
    canvas.drawCircle(const Offset(72, 28), 16, _fill(accent));
    final arrow = Path()
      ..moveTo(72, 34)
      ..lineTo(72, 22)
      ..moveTo(66, 28)
      ..lineTo(72, 22)
      ..lineTo(78, 28);
    canvas.drawPath(arrow, _stroke(Colors.white, 3));
  }

  void _math(Canvas canvas) {
    canvas.drawRRect(_rrect(16, 28, 60, 48, 8), _fill(Colors.white, 0.9));
    canvas.drawRRect(_rrect(26, 40, 22, 5, 2.5), _fill(accent, 0.5));
    canvas.drawRRect(_rrect(52, 40, 8, 5, 2.5), _fill(accent, 0.5));
    canvas.drawRRect(_rrect(26, 51, 14, 5, 2.5), _fill(accent, 0.35));
    canvas.drawRRect(_rrect(44, 51, 22, 5, 2.5), _fill(accent, 0.35));
    canvas.drawRRect(_rrect(26, 62, 30, 5, 2.5), _fill(accent, 0.25));

    final corner = _stroke(accent, 4);
    canvas.drawPath(Path()..moveTo(10, 22)..lineTo(10, 12)..lineTo(20, 12), corner);
    canvas.drawPath(Path()..moveTo(80, 12)..lineTo(90, 12)..lineTo(90, 22), corner);
    canvas.drawPath(Path()..moveTo(90, 82)..lineTo(90, 92)..lineTo(80, 92), corner);
    canvas.drawPath(Path()..moveTo(20, 92)..lineTo(10, 92)..lineTo(10, 82), corner);

    canvas.drawCircle(const Offset(74, 26), 15, _fill(accent));
    canvas.drawPath(Path()..moveTo(67, 26)..lineTo(72, 31)..lineTo(82, 19), _stroke(Colors.white, 3));
  }

  void _chat(Canvas canvas) {
    canvas.drawRRect(_rrect(12, 20, 54, 34, 14), _fill(Colors.white, 0.9));
    canvas.drawCircle(const Offset(25, 37), 3, _fill(accent, 0.5));
    canvas.drawCircle(const Offset(37, 37), 3, _fill(accent, 0.5));
    canvas.drawCircle(const Offset(49, 37), 3, _fill(accent, 0.5));
    canvas.drawRRect(_rrect(38, 52, 48, 30, 14), _fill(accent));
    canvas.drawPath(Path()..moveTo(52, 65)..lineTo(58, 71)..lineTo(70, 59), _stroke(Colors.white, 3.5));
  }

  void _quiz(Canvas canvas) {
    canvas.drawRRect(_rrect(18, 15, 64, 20, 10), _fill(Colors.white, 0.9));
    canvas.drawCircle(const Offset(28, 25), 5, _fill(accent));
    canvas.drawRRect(_rrect(40, 22, 34, 6, 3), _fill(accent, 0.35));

    canvas.drawRRect(_rrect(18, 42, 64, 20, 10), _fill(accent));
    canvas.drawCircle(const Offset(28, 52), 5, _fill(Colors.white));
    canvas.drawPath(Path()..moveTo(25.5, 52)..lineTo(27.5, 54)..lineTo(31, 49.5), _stroke(accent, 2));
    canvas.drawRRect(_rrect(40, 49, 34, 6, 3), _fill(Colors.white, 0.7));

    canvas.drawRRect(_rrect(18, 69, 64, 20, 10), _fill(Colors.white, 0.6));
    canvas.drawCircle(const Offset(28, 79), 5, _fill(accent, 0.3));
    canvas.drawRRect(_rrect(40, 76, 24, 6, 3), _fill(accent, 0.2));
  }

  void _plan(Canvas canvas) {
    canvas.drawRRect(_rrect(14, 16, 72, 68, 10), _fill(Colors.white, 0.9));
    canvas.drawRRect(_rrect(14, 16, 72, 16, 10), _fill(accent));
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        final isHighlight = row == 1 && col == 2;
        canvas.drawRRect(
          _rrect(22 + col * 13, 42 + row * 11, 9, 7, 2),
          _fill(accent, isHighlight ? 1 : 0.15),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => oldDelegate.variant != variant || oldDelegate.accent != accent;
}
