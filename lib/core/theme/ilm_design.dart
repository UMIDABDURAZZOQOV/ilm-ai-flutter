import 'package:flutter/material.dart';

abstract final class IlmSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const page = EdgeInsets.all(lg);
}

abstract final class IlmRadius {
  static const small = 12.0;
  static const control = 16.0;
  static const card = 20.0;
  static const sheet = 28.0;
}

/// Indigo actions, turquoise progress and amber milestones have separate roles.
/// The lighter dark-mode link colour must never imply a white foreground.
class IlmDesign extends ThemeExtension<IlmDesign> {
  const IlmDesign({
    required this.action,
    required this.onAction,
    required this.focus,
  });
  final Color action;
  final Color onAction;
  final Color focus;
  static const touchTarget = 48.0;
  static const readingWidth = 640.0;
  static const pageWidth = 960.0;
  static const transition = Duration(milliseconds: 180);

  @override
  IlmDesign copyWith({Color? action, Color? onAction, Color? focus}) =>
      IlmDesign(
        action: action ?? this.action,
        onAction: onAction ?? this.onAction,
        focus: focus ?? this.focus,
      );
  @override
  IlmDesign lerp(covariant IlmDesign? other, double t) => other == null
      ? this
      : IlmDesign(
          action: Color.lerp(action, other.action, t)!,
          onAction: Color.lerp(onAction, other.onAction, t)!,
          focus: Color.lerp(focus, other.focus, t)!,
        );
}

/// A width bound, with no fixed height or text scaling override.
class IlmReadingWidth extends StatelessWidget {
  const IlmReadingWidth({
    super.key,
    required this.child,
    this.maxWidth = IlmDesign.readingWidth,
  });
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
