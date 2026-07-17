import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ported from ilm-ai-mobile's GradientButton.tsx -- solid variant is a
/// primary->secondary gradient fill, outline is a bordered ghost button.
/// Adds a subtle press-scale on top of the ripple for tactile feedback.
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  final bool outline;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.outline = false,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final disabled = widget.onPressed == null || widget.loading;

    final content = widget.loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(widget.outline ? colors.primary : Colors.white),
            ),
          )
        : DefaultTextStyle.merge(
            style: TextStyle(
              color: widget.outline ? colors.primary : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            child: widget.child,
          );

    final decoration = widget.outline
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: colors.primary, width: 1.5),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(colors: [colors.primary, colors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: disabled ? 0.6 : 1,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: disabled ? null : widget.onPressed,
            onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
            onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
            onTapCancel: disabled ? null : () => setState(() => _pressed = false),
            child: Container(
              padding: widget.padding,
              alignment: Alignment.center,
              decoration: decoration,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
