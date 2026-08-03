import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  background: _hex('#F8FAFC'),
  surface: _hex('#FFFFFF'),
  card: _hex('#FFFFFF'),
  text: _hex('#0F172A'),
  textSecondary: _hex('#475569'),
  textMuted: _hex('#94A3B8'),
  border: _hex('#E2E8F0'),
  primary: _hex('#4F46E5'),
  primaryLight: _hex('#EEF2FF'),
  secondary: _hex('#7C3AED'),
  accent: _hex('#06B6D4'),
  error: _hex('#DC2626'),
  errorLight: _hex('#FEE2E2'),
  success: _hex('#059669'),
  successLight: _hex('#ECFDF5'),
  warning: _hex('#D97706'),
  warningLight: _hex('#FFFBEB'),
  inputBackground: _hex('#F1F5F9'),
  statusBarStyle: Brightness.dark,
  cardTints: [
    CardTint(bg: _hex('#EEF2FF'), border: _hex('#C7D2FE')),
    CardTint(bg: _hex('#ECFDF5'), border: _hex('#A7F3D0')),
    CardTint(bg: _hex('#FAF5FF'), border: _hex('#E9D5FF')),
    CardTint(bg: _hex('#ECFEFF'), border: _hex('#A5F3FC')),
    CardTint(bg: _hex('#FFF7ED'), border: _hex('#FED7AA')),
    CardTint(bg: _hex('#FEF2F2'), border: _hex('#FECACA')),
    CardTint(bg: _hex('#F0FDF4'), border: _hex('#86EFAC')),
  ],
);

final ThemeColors darkColors = ThemeColors(
  background: _hex('#0F172A'),
  surface: _hex('#1E293B'),
  card: _hex('#1E293B'),
  text: _hex('#F8FAFC'),
  textSecondary: _hex('#94A3B8'),
  textMuted: _hex('#64748B'),
  border: _hex('#334155'),
  primary: _hex('#6366F1'),
  primaryLight: _hex('#1E1B4B'),
  secondary: _hex('#A78BFA'),
  accent: _hex('#22D3EE'),
  error: _hex('#F87171'),
  errorLight: _hex('#450A0A'),
  success: _hex('#34D399'),
  successLight: _hex('#064E3B'),
  warning: _hex('#FBBF24'),
  warningLight: _hex('#451A03'),
  inputBackground: _hex('#0F172A'),
  statusBarStyle: Brightness.light,
  cardTints: [
    CardTint(bg: _hex('#1E2A4A'), border: _hex('#4338CA')),
    CardTint(bg: _hex('#132A1E'), border: _hex('#059669')),
    CardTint(bg: _hex('#2A1E3A'), border: _hex('#7C3AED')),
    CardTint(bg: _hex('#0E2A30'), border: _hex('#0891B2')),
    CardTint(bg: _hex('#3A2A15'), border: _hex('#D97706')),
    CardTint(bg: _hex('#3A1818'), border: _hex('#DC2626')),
    CardTint(bg: _hex('#123330'), border: _hex('#10B981')),
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

/// Status + navigation bar styling that makes both system bars blend into the
/// app: a transparent status bar (content draws behind it) and a navigation bar
/// painted the SAME colour as the page background — so there are no grey/black
/// strips ("chiziq") at the top or bottom. Icon brightness follows the theme.
SystemUiOverlayStyle systemOverlayStyleFor(ThemeColors c) {
  // c.statusBarStyle == Brightness.dark means a light theme (dark status icons).
  final light = c.statusBarStyle == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
    statusBarBrightness: light ? Brightness.light : Brightness.dark, // iOS
    systemNavigationBarColor: c.background,
    systemNavigationBarIconBrightness: light ? Brightness.dark : Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );
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
    appBarTheme: AppBarTheme(systemOverlayStyle: systemOverlayStyleFor(c)),
    extensions: [AppColors(c)],
  );
}
