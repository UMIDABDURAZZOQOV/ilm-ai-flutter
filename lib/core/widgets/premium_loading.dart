import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumLoading extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const PremiumLoading({
    super.key,
    this.size = 40,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? colors.primary),
        backgroundColor: colors.primary.withValues(alpha: 0.1),
      ),
    );
  }
}

class PremiumShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const PremiumShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor ?? colors.border.withValues(alpha: 0.3),
            highlightColor ?? colors.border.withValues(alpha: 0.1),
            baseColor ?? colors.border.withValues(alpha: 0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
          tileMode: TileMode.repeated,
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

class PremiumSuccessAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final double size;

  const PremiumSuccessAnimation({
    super.key,
    this.onComplete,
    this.size = 80,
  });

  @override
  State<PremiumSuccessAnimation> createState() => _PremiumSuccessAnimationState();
}

class _PremiumSuccessAnimationState extends State<PremiumSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: colors.success,
                size: widget.size * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class PremiumPulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool pulsing;

  const PremiumPulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.pulsing = true,
  });

  @override
  State<PremiumPulse> createState() => _PremiumPulseState();
}

class _PremiumPulseState extends State<PremiumPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.pulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
