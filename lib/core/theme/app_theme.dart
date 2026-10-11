import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/product_mode.dart';

/// Legacy palettes remain available when subjects-only mode is disabled.
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
  final Color creamWhite;
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
    this.creamWhite = const Color(0xFFFAF7F2),
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

/// Ilm AI Brand Identity Palette
/// Asosiy: Indigo #2A1F6B
/// Aksent: Sariq-to'q sariq #F9A825
/// Ajratib turuvchi: Turkuaz #2DD4BF
/// Maskot rangi: Qaymoq-oq #FAF7F2
/// Brend shakli: Romb (Diamond)
class BrandPalette {
  static const Color indigo = Color(0xFF2A1F6B);
  static const Color indigoDarkBg = Color(0xFF13102C);
  static const Color indigoDarkSurface = Color(0xFF1C173E);
  static const Color indigoDarkCard = Color(0xFF251F50);
  static const Color indigoDarkBorder = Color(0xFF3C3375);
  static const Color indigoDarkPrimary = Color(0xFF5C4BD8);

  static const Color accentOrange = Color(0xFFF9A825);
  static const Color turquoise = Color(0xFF2DD4BF);
  static const Color creamWhite = Color(0xFFFAF7F2);
}

ThemeColors learningPalette(ThemeColors base) {
  if (!subjectsOnly) return base;
  final dark = base.statusBarStyle == Brightness.light;
  return ThemeColors(
    background: dark ? BrandPalette.indigoDarkBg : Colors.white,
    surface: dark ? BrandPalette.indigoDarkSurface : Colors.white,
    card: dark ? BrandPalette.indigoDarkCard : Colors.white,
    text: dark ? const Color(0xFFF1F0FA) : const Color(0xFF1E1A34),
    textSecondary: dark ? const Color(0xFFA69EC6) : const Color(0xFF5A537E),
    textMuted: dark ? const Color(0xFF766E99) : const Color(0xFF8C86A8),
    border: dark ? BrandPalette.indigoDarkBorder : const Color(0xFFE5E2F2),
    primary: dark ? BrandPalette.indigoDarkPrimary : BrandPalette.indigo,
    secondary: BrandPalette.accentOrange,
    primaryLight: dark ? const Color(0xFF2E2660) : const Color(0xFFECE9F8),
    accent: BrandPalette.turquoise,
    creamWhite: BrandPalette.creamWhite,
    error: base.error,
    errorLight: base.errorLight,
    success: base.success,
    successLight: base.successLight,
    warning: base.warning,
    warningLight: base.warningLight,
    inputBackground: dark ? BrandPalette.indigoDarkSurface : const Color(0xFFF6F5FB),
    statusBarStyle: base.statusBarStyle,
    cardTints: base.cardTints,
  );
}

final ThemeColors lightColors = ThemeColors(
  background: _hex('#F8FAFC'),
  surface: _hex('#FFFFFF'),
  card: _hex('#FFFFFF'),
  text: _hex('#0F172A'),
  textSecondary: _hex('#475569'),
  textMuted: _hex('#94A3B8'),
  border: _hex('#E2E8F0'),
  primary: _hex('#2A1F6B'),
  primaryLight: _hex('#ECE9F8'),
  secondary: _hex('#F9A825'),
  accent: _hex('#2DD4BF'),
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
  primary: _hex('#5C4BD8'),
  primaryLight: _hex('#2E2660'),
  secondary: _hex('#F9A825'),
  accent: _hex('#2DD4BF'),
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
    systemNavigationBarIconBrightness: light
        ? Brightness.dark
        : Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}

ThemeData buildAppTheme(ThemeColors c) {
  c = learningPalette(c);
  final brightness = c.statusBarStyle == Brightness.dark
      ? Brightness.light
      : Brightness.dark;
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
