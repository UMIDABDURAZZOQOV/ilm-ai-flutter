import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Romb (Diamond) badge component representing Ilm AI's signature brand shape.
/// Rotates a rounded container 45° with an upright counter-rotated child.
class RombBadge extends StatelessWidget {
  final Widget child;
  final double size;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final Color? shadowColor;
  final double elevation;
  final double borderRadius;

  const RombBadge({
    super.key,
    required this.child,
    this.size = 48,
    required this.color,
    this.borderColor,
    this.borderWidth = 2,
    this.shadowColor,
    this.elevation = 4,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    // Inner box is slightly smaller so rotated corners fit within bounds
    final innerSize = size / math.sqrt(2);

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: borderWidth)
                  : null,
              boxShadow: shadowColor != null && elevation > 0
                  ? [
                      BoxShadow(
                        color: shadowColor!,
                        offset: Offset(0, elevation),
                        blurRadius: elevation > 4 ? 6 : 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
