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
  final double height;

  const Duo3DButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.shadowColor,
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
    final topOffset = _pressed && enabled ? 4.0 : 0.0;
    final bottomBevel = _pressed && enabled ? 2.0 : 6.0;

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
                color: enabled ? Colors.white : const Color(0xFF777777),
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
    final fill = color ?? colors?.secondary ?? BrandPalette.accentOrange;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 16,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 16,
          backgroundColor: colors?.border ?? const Color(0xFFE5E5E5),
          color: fill,
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
