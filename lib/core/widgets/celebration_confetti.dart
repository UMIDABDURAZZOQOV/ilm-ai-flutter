import 'dart:math' as math;
import 'package:flutter/material.dart';

class CelebrationConfetti extends StatefulWidget {
  final Widget? child;
  final Duration duration;

  const CelebrationConfetti({
    super.key,
    this.child,
    this.duration = const Duration(milliseconds: 2800),
  });

  @override
  State<CelebrationConfetti> createState() => _CelebrationConfettiState();
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double rotation;
  double rotationSpeed;
  Color color;
  bool isCircle;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.isCircle,
  });
}

class _CelebrationConfettiState extends State<CelebrationConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  bool _initialized = false;

  static const _palette = [
    Color(0xFF58CC02), // Green
    Color(0xFFFFC800), // Gold
    Color(0xFF1CB0F6), // Blue
    Color(0xFFFF4B4B), // Coral
    Color(0xFFCE82FF), // Purple
    Color(0xFFFF9600), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addListener(() {
      if (mounted) setState(_updateParticles);
    });
  }

  void _initParticles(Size size) {
    if (_initialized || size.width == 0 || size.height == 0) return;
    _initialized = true;

    // 40 particles for battery efficiency while keeping it festive
    for (int i = 0; i < 42; i++) {
      final angle =
          -math.pi / 2 + (_random.nextDouble() - 0.5) * (math.pi * 0.7);
      final speed = 8.0 + _random.nextDouble() * 10.0;
      _particles.add(
        _Particle(
          x: size.width * (0.35 + _random.nextDouble() * 0.3),
          y: size.height * 0.45,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 6.0 + _random.nextDouble() * 6.0,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
          color: _palette[_random.nextInt(_palette.length)],
          isCircle: _random.nextBool(),
        ),
      );
    }
    _controller.forward();
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.35; // gravity
      p.vx *= 0.985; // air drag
      p.rotation += p.rotationSpeed;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return widget.child ?? const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_initialized && constraints.maxWidth > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _initParticles(Size(constraints.maxWidth, constraints.maxHeight));
            }
          });
        }

        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    if (opacity <= 0.0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      final flipScale = math.cos(p.rotation * 2);
      canvas.scale(1.0, flipScale);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.5,
              height: p.size,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
