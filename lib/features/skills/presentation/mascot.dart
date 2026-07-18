import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ILM AI's own friendly owl mascot -- fills the same encouraging-companion
/// role Duolingo's Duo plays (greets you, celebrates wins, looks sad when you
/// lose a heart), drawn from scratch as simple shapes, not a third-party asset.
enum MascotMood { idle, happy, sad, cheer }

class Mascot extends StatelessWidget {
  final MascotMood mood;
  final double size;
  const Mascot({super.key, this.mood = MascotMood.idle, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MascotPainter(mood: mood)),
    );
    if (mood == MascotMood.cheer) {
      return child.animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -14, duration: 300.ms, curve: Curves.easeInOut);
    }
    return child.animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.02, end: 0.02, duration: 1100.ms, curve: Curves.easeInOut);
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  _MascotPainter({required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    Offset p(double x, double y) => Offset(x * s, y * s);

    canvas.drawOval(Rect.fromCenter(center: p(50, 58), width: 76 * s, height: 68 * s), Paint()..color = const Color(0xFF58CC02));
    canvas.drawOval(Rect.fromCenter(center: p(28, 30), width: 28 * s, height: 32 * s), Paint()..color = const Color(0xFF58CC02));
    canvas.drawOval(Rect.fromCenter(center: p(72, 30), width: 28 * s, height: 32 * s), Paint()..color = const Color(0xFF58CC02));
    canvas.drawCircle(p(50, 50), 30 * s, Paint()..color = const Color(0xFF8DE24C));

    final eyesClosed = mood == MascotMood.sad;
    if (eyesClosed) {
      final linePaint = Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * s
        ..strokeCap = StrokeCap.round;
      final leftPath = Path()..moveTo(p(32, 48).dx, p(32, 48).dy)..quadraticBezierTo(p(38, 54).dx, p(38, 54).dy, p(44, 48).dx, p(44, 48).dy);
      final rightPath = Path()..moveTo(p(56, 48).dx, p(56, 48).dy)..quadraticBezierTo(p(62, 54).dx, p(62, 54).dy, p(68, 48).dx, p(68, 48).dy);
      canvas.drawPath(leftPath, linePaint);
      canvas.drawPath(rightPath, linePaint);
    } else {
      canvas.drawCircle(p(38, 48), 10 * s, Paint()..color = Colors.white);
      canvas.drawCircle(p(62, 48), 10 * s, Paint()..color = Colors.white);
      canvas.drawCircle(p(39, 49), 5 * s, Paint()..color = const Color(0xFF1A1A1A));
      canvas.drawCircle(p(63, 49), 5 * s, Paint()..color = const Color(0xFF1A1A1A));
    }

    final beak = Path()
      ..moveTo(p(46, 60).dx, p(46, 60).dy)
      ..lineTo(p(50, 68).dx, p(50, 68).dy)
      ..lineTo(p(54, 60).dx, p(54, 60).dy)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFF9600));

    final mouthPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;
    final mouth = Path();
    if (mood == MascotMood.happy || mood == MascotMood.cheer) {
      mouth.moveTo(p(38, 70).dx, p(38, 70).dy);
      mouth.quadraticBezierTo(p(50, 82).dx, p(50, 82).dy, p(62, 70).dx, p(62, 70).dy);
    } else if (mood == MascotMood.sad) {
      mouth.moveTo(p(38, 76).dx, p(38, 76).dy);
      mouth.quadraticBezierTo(p(50, 68).dx, p(50, 68).dy, p(62, 76).dx, p(62, 76).dy);
    } else {
      mouth.moveTo(p(40, 72).dx, p(40, 72).dy);
      mouth.quadraticBezierTo(p(50, 78).dx, p(50, 78).dy, p(60, 72).dx, p(60, 72).dy);
    }
    canvas.drawPath(mouth, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => oldDelegate.mood != mood;
}
