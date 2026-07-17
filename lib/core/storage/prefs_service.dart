import 'package:shared_preferences/shared_preferences.dart';

/// Keys mirror ilm-ai-mobile's AsyncStorage keys exactly, for parity.
class PrefsKeys {
  static const themeMode = 'app_theme_mode';
  static const language = 'app_language';
  static const onboardingComplete = 'onboarding_complete';
  static const collegeSaved = 'college_saved';
}

class PrefsService {
  final SharedPreferences _prefs;
  const PrefsService(this._prefs);

  static Future<PrefsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsService(prefs);
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  bool getBool(String key, {bool defaultValue = false}) => _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
}
