import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/prefs_service.dart';
import '../theme/app_theme.dart';

/// Overridden with the real instance in main.dart after async init.
final prefsServiceProvider = Provider<PrefsService>(
  (ref) => throw UnimplementedError('prefsServiceProvider must be overridden in main.dart'),
);

class ThemeModeNotifier extends Notifier<String> {
  static const supported = ['light', 'dark', 'system'];

  @override
  String build() {
    final saved = ref.read(prefsServiceProvider).getString(PrefsKeys.themeMode);
    return supported.contains(saved) ? saved! : 'system';
  }

  void setMode(String mode) {
    if (!supported.contains(mode)) return;
    state = mode;
    ref.read(prefsServiceProvider).setString(PrefsKeys.themeMode, mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, String>(ThemeModeNotifier.new);

/// Resolves 'system' against the platform brightness, mirroring RN's
/// ThemeContext resolvedTheme derivation via useColorScheme().
final resolvedColorsProvider = Provider<ThemeColors>((ref) {
  final mode = ref.watch(themeModeProvider);
  if (mode == 'light') return lightColors;
  if (mode == 'dark') return darkColors;
  final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  return brightness == Brightness.dark ? darkColors : lightColors;
});

class LanguageNotifier extends Notifier<String> {
  static const supported = ['uz', 'ru', 'en'];

  @override
  String build() {
    final saved = ref.read(prefsServiceProvider).getString(PrefsKeys.language);
    return supported.contains(saved) ? saved! : 'en';
  }

  void setLanguage(String lang) {
    if (!supported.contains(lang)) return;
    state = lang;
    ref.read(prefsServiceProvider).setString(PrefsKeys.language, lang);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(prefsServiceProvider).getBool(PrefsKeys.onboardingComplete);

  /// Fixes a known RN-app bug where this flag was read but never persisted,
  /// so onboarding replayed on every cold start. Flutter version persists it.
  void complete() {
    state = true;
    ref.read(prefsServiceProvider).setBool(PrefsKeys.onboardingComplete, true);
  }
}

final onboardingCompleteProvider = NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
