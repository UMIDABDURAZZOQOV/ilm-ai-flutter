import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Visual style of a [PremiumButton]. `filled` is the default gradient button;
/// `outline` is a bordered transparent button; `ghost` is borderless/flat.
enum PremiumButtonVariant { filled, outline, ghost }

class PremiumButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  final bool outline;
  final bool ghost;
  final PremiumButtonVariant? variant;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.outline = false,
    this.ghost = false,
    this.variant,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final disabled = widget.onPressed == null || widget.loading;

    // A `variant` (if given) is equivalent to the matching bool flag.
    final isOutline = widget.outline || widget.variant == PremiumButtonVariant.outline;
    final isGhost = widget.ghost || widget.variant == PremiumButtonVariant.ghost;

    final bgColor = widget.backgroundColor ??
        (isOutline || isGhost ? Colors.transparent : colors.primary);
    final txtColor = widget.textColor ??
        (isOutline || isGhost ? colors.primary : Colors.white);
    final brColor = widget.borderColor ?? colors.primary;

    final content = widget.loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(txtColor),
            ),
          )
        : DefaultTextStyle.merge(
            style: TextStyle(
              color: txtColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
            child: widget.child,
          );

    final decoration = isGhost
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: bgColor,
          )
        : isOutline
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: brColor, width: 2),
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                // A solid fill when an explicit backgroundColor is given (e.g. a
                // red destructive button); otherwise the brand gradient.
                color: widget.backgroundColor,
                gradient: widget.backgroundColor == null
                    ? LinearGradient(
                        colors: [colors.primary, colors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (widget.backgroundColor ?? colors.primary).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.5 : 1,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                onTap: disabled ? null : widget.onPressed,
                onTapDown: disabled ? null : (_) => _controller.forward(),
                onTapUp: disabled ? null : (_) => _controller.reverse(),
                onTapCancel: disabled ? null : () => _controller.reverse(),
                splashColor: colors.primary.withValues(alpha: 0.1),
                highlightColor: colors.primary.withValues(alpha: 0.05),
                child: Container(
                  padding: widget.padding,
                  alignment: Alignment.center,
                  decoration: decoration,
                  child: content,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PremiumIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final double borderRadius;

  const PremiumIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size = 48,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    
    final bgColor = backgroundColor ?? colors.surface;
    final iconClr = iconColor ?? colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: colors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: colors.text.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconClr, size: 22),
        ),
      ),
    );
  }
}
