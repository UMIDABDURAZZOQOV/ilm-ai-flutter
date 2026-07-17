import 'package:flutter/material.dart';

/// Ported verbatim from ilm-ai-mobile/src/utils/theme.ts — 18 semantic fields
/// per palette plus a 7-entry cardTints array. Do not invent or "improve" any
/// value here; if the design changes, change theme.ts first and re-port.
class CardTint {
  final Color bg;
  final Color border;
  const CardTint({required this.bg, required this.border});
}

class ThemeColors {
  final Color background;
  final Color surface;
  final Color card;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color accent;
  final Color error;
  final Color errorLight;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color inputBackground;
  final Brightness statusBarStyle;
  final List<CardTint> cardTints;

  const ThemeColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
    required this.error,
    required this.errorLight,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.inputBackground,
    required this.statusBarStyle,
    required this.cardTints,
  });
}

Color _hex(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

final ThemeColors lightColors = ThemeColors(
  background: _hex('#f8fafc'),
  surface: _hex('#ffffff'),
  card: _hex('#ffffff'),
  text: _hex('#1f2937'),
  textSecondary: _hex('#6b7280'),
  textMuted: _hex('#9ca3af'),
  border: _hex('#e5e7eb'),
  primary: _hex('#6366f1'),
  primaryLight: _hex('#eff6ff'),
  secondary: _hex('#a855f7'),
  accent: _hex('#22d3ee'),
  error: _hex('#ef4444'),
  errorLight: _hex('#fee2e2'),
  success: _hex('#22c55e'),
  successLight: _hex('#f0fdf4'),
  warning: _hex('#f59e0b'),
  warningLight: _hex('#fffbeb'),
  inputBackground: _hex('#f9fafb'),
  statusBarStyle: Brightness.dark,
  cardTints: [
    CardTint(bg: _hex('#eff6ff'), border: _hex('#bfdbfe')),
    CardTint(bg: _hex('#f0fdf4'), border: _hex('#bbf7d0')),
    CardTint(bg: _hex('#fdf4ff'), border: _hex('#e9d5ff')),
    CardTint(bg: _hex('#ecfeff'), border: _hex('#a5f3fc')),
    CardTint(bg: _hex('#fff7ed'), border: _hex('#fed7aa')),
    CardTint(bg: _hex('#fef2f2'), border: _hex('#fecaca')),
    CardTint(bg: _hex('#f0fdfa'), border: _hex('#99f6e4')),
  ],
);

final ThemeColors darkColors = ThemeColors(
  background: _hex('#0f172a'),
  surface: _hex('#1e293b'),
  card: _hex('#1e293b'),
  text: _hex('#f1f5f9'),
  textSecondary: _hex('#94a3b8'),
  textMuted: _hex('#64748b'),
  border: _hex('#334155'),
  primary: _hex('#818cf8'),
  primaryLight: _hex('#1e1b4b'),
  secondary: _hex('#c084fc'),
  accent: _hex('#67e8f9'),
  error: _hex('#f87171'),
  errorLight: _hex('#450a0a'),
  success: _hex('#4ade80'),
  successLight: _hex('#052e16'),
  warning: _hex('#fbbf24'),
  warningLight: _hex('#451a03'),
  inputBackground: _hex('#0f172a'),
  statusBarStyle: Brightness.light,
  cardTints: [
    CardTint(bg: _hex('#1e2a4a'), border: _hex('#2c3e6b')),
    CardTint(bg: _hex('#132a1e'), border: _hex('#1f4a30')),
    CardTint(bg: _hex('#2a1e3a'), border: _hex('#432a5a')),
    CardTint(bg: _hex('#0e2a30'), border: _hex('#164752')),
    CardTint(bg: _hex('#3a2a15'), border: _hex('#5a4520')),
    CardTint(bg: _hex('#3a1818'), border: _hex('#5a2626')),
    CardTint(bg: _hex('#123330'), border: _hex('#1c524d')),
  ],
);

/// ThemeExtension so `Theme.of(context).extension<AppColors>()` exposes the
/// exact same field set as the RN app's ThemeColors, in both light and dark.
class AppColors extends ThemeExtension<AppColors> {
  final ThemeColors colors;
  const AppColors(this.colors);

  @override
  AppColors copyWith({ThemeColors? colors}) => AppColors(colors ?? this.colors);

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return t < 0.5 ? this : other;
  }
}

ThemeData buildAppTheme(ThemeColors c) {
  final brightness = c.statusBarStyle == Brightness.dark ? Brightness.light : Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      secondary: c.secondary,
      error: c.error,
      surface: c.surface,
    ),
    extensions: [AppColors(c)],
  );
}
