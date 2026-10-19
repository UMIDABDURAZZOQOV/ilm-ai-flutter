import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

Color duoShadowOf(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - 0.18).clamp(0.05, 1.0)).toColor();
}

/// Duolingo-style 3D press button. Colours come from the brand palette by
/// default (indigo face, darker indigo bevel) — never Duo green.
class Duo3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? shadowColor;
  final Color? textColor;
  final Color? borderColor;
  final double height;

  const Duo3DButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.shadowColor,
    this.textColor,
    this.borderColor,
    this.height = 52,
  });

  @override
  State<Duo3DButton> createState() => _Duo3DButtonState();
}

class _Duo3DButtonState extends State<Duo3DButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()?.colors;
    final enabled = widget.onPressed != null;
    final face = enabled
        ? (widget.color ?? colors?.primary ?? BrandPalette.indigo)
        : const Color(0xFFE5E5E5);
    final bevel = enabled
        ? (widget.shadowColor ?? duoShadowOf(face))
        : const Color(0xFFB0B0B0);
    final textCol = enabled
        ? (widget.textColor ?? Colors.white)
        : const Color(0xFF777777);
    final topOffset = _pressed && enabled ? 4.0 : 0.0;
    final bottomBevel = _pressed && enabled ? 2.0 : 5.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      child: Transform.translate(
        offset: Offset(0, topOffset),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.height),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(16),
              border: widget.borderColor != null
                  ? Border.all(color: widget.borderColor!, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: bevel,
                  offset: Offset(0, bottomBevel),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: textCol,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class DuoProgressBar extends StatelessWidget {
  final double value;
  final Color? color;

  const DuoProgressBar({super.key, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()?.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = color ?? colors?.primary ?? BrandPalette.indigo;
    final trackColor =
        isDark ? const Color(0xFF2B2353) : const Color(0xFFE5E5E5);

    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 16,
        color: trackColor,
        alignment: Alignment.centerLeft,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth * clamped;
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: barWidth),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, width, _) {
                if (width <= 0) return const SizedBox.shrink();
                return Container(
                  width: width,
                  height: 16,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 2,
                        left: 4,
                        right: 4,
                        height: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class DuoChoiceCard extends StatelessWidget {
  final String text;
  final bool selected;
  final bool answered;
  final bool isCorrectOption;
  final VoidCallback? onTap;

  const DuoChoiceCard({
    super.key,
    required this.text,
    required this.selected,
    required this.answered,
    required this.isCorrectOption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    Color border = colors.border;
    Color bg = colors.card;
    Color textColor = colors.text;
    Color shadow = colors.border;

    if (!answered && selected) {
      border = colors.primary;
      bg = colors.primaryLight;
      shadow = duoShadowOf(colors.primary).withValues(alpha: 0.45);
    } else if (answered) {
      if (isCorrectOption) {
        border = colors.success;
        bg = colors.successLight;
        shadow = colors.success.withValues(alpha: 0.45);
      } else if (selected) {
        border = colors.error;
        bg = colors.errorLight;
        textColor = colors.error;
        shadow = colors.error.withValues(alpha: 0.4);
      } else {
        textColor = colors.textMuted;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: answered ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2.4),
            boxShadow: [
              BoxShadow(color: shadow, offset: const Offset(0, 4), blurRadius: 0),
            ],
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 17.5,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class DuoNavItem {
  final IconData icon;
  final String label;
  const DuoNavItem({required this.icon, required this.label});
}

/// Icon + label bar. Selected uses brand indigo; no Material 3 pill.
class DuoBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<DuoNavItem> items;

  const DuoBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    return Material(
      color: colors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onChanged(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              items[i].icon,
                              size: 28,
                              color: i == index
                                  ? colors.primary
                                  : colors.textMuted,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: i == index
                                    ? colors.primary
                                    : colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum BubblePointerDirection { left, down, none }

class DuoSpeechBubble extends StatelessWidget {
  final Widget? child;
  final String? text;
  final BubblePointerDirection pointerDirection;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  const DuoSpeechBubble({
    super.key,
    this.child,
    this.text,
    this.pointerDirection = BubblePointerDirection.left,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()?.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? BrandPalette.indigoDarkCard : Colors.white;
    final border = colors?.border ?? const Color(0xFFE5E2F2);
    final shadow = isDark ? Colors.black26 : const Color(0x12000000);

    final content = child ??
        Text(
          text ?? '',
          style: textStyle ??
              TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: colors?.text ?? const Color(0xFF1E1A34),
                height: 1.35,
              ),
        );

    if (pointerDirection == BubblePointerDirection.down) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  offset: const Offset(0, 3.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: content,
          ),
          Transform.translate(
            offset: const Offset(0, -1),
            child: CustomPaint(
              size: const Size(18, 9),
              painter: _BubbleTailPainter(
                color: bg,
                borderColor: border,
                direction: BubblePointerDirection.down,
              ),
            ),
          ),
        ],
      );
    } else if (pointerDirection == BubblePointerDirection.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(1, 0),
            child: CustomPaint(
              size: const Size(9, 18),
              painter: _BubbleTailPainter(
                color: bg,
                borderColor: border,
                direction: BubblePointerDirection.left,
              ),
            ),
          ),
          Flexible(
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    offset: const Offset(0, 3.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: shadow,
            offset: const Offset(0, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: content,
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final BubblePointerDirection direction;

  const _BubbleTailPainter({
    required this.color,
    required this.borderColor,
    required this.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final paintBorder = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (direction == BubblePointerDirection.down) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.close();
      canvas.drawPath(path, paintFill);

      final borderPath = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
      canvas.drawPath(borderPath, paintBorder);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paintFill);

      final borderPath = Path()
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height);
      canvas.drawPath(borderPath, paintBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      color != oldDelegate.color ||
      borderColor != oldDelegate.borderColor ||
      direction != oldDelegate.direction;
}
