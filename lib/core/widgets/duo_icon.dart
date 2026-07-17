import 'package:flutter/material.dart';

/// Fakes a "duotone" icon look (soft tinted glyph behind, bold glyph on top,
/// tiny offset) using only stock Material Icons -- avoids depending on a
/// third-party icon-font package, several of which currently fail to build
/// on this Flutter version because it made `IconData` a `final class`
/// (breaks any package's `class XIconData extends IconData` pattern).
class DuoIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const DuoIcon(this.icon, {super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: size, color: color.withValues(alpha: 0.22)),
          Icon(icon, size: size * 0.72, color: color),
        ],
      ),
    );
  }
}
