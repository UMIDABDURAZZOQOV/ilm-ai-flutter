import 'package:shared_preferences/shared_preferences.dart';

/// Keys mirror ilm-ai-mobile's AsyncStorage keys exactly, for parity.
class PrefsKeys {
  static const themeMode = 'app_theme_mode';
  static const language = 'app_language';
  static const onboardingComplete = 'onboarding_complete';
  static const collegeSaved = 'college_saved';
  static const soundEffects = 'sound_effects_enabled';
}

class PrefsService {
  final SharedPreferences _prefs;
  const PrefsService(this._prefs);

  static Future<PrefsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsService(prefs);
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) async {
    if (!_deletedOwner(key)) await _prefs.setString(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) async {
    if (!_deletedOwner(key)) await _prefs.setBool(key, value);
  }

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) async {
    if (!_deletedOwner(key)) await _prefs.setInt(key, value);
  }

  Future<void> remove(String key) => _prefs.remove(key);

  static const _deleted = 'deleted_account_ids';
  static bool _owned(String key, String id) {
    const fields = [
      'subject',
      'class',
      'source',
      'reason',
      'daily_goal',
      'level',
      'study_preferences_version',
      'study_preferences_dirty',
      'onboarding_draft',
      'onboarding_completed',
    ];
    if (fields.any((field) => key == '${field}_$id')) return true;
    final parts = key.split(':');
    return parts.length >= 4 &&
        const {
          'beta_v2',
          'lesson_ui_v1',
          'physics_v2',
          'chemistry_v2',
          'world_history_v2',
          'uzbekistan_history_v2',
        }.contains(parts[0]) &&
        parts[2] == id;
  }

  bool _deletedOwner(String key) =>
      (_prefs.getStringList(_deleted) ?? const []).any((id) => _owned(key, id));

  /// A durable marker also blocks queued writes from a disposed lesson screen.
  /// Global appearance/onboarding settings and other accounts are preserved.
  Future<void> clearAccountData(int userId) async {
    if (userId <= 0) throw ArgumentError.value(userId);
    final deleted = {...?_prefs.getStringList(_deleted), '$userId'};
    await _prefs.setStringList(_deleted, deleted.toList());
    for (final key
        in _prefs.getKeys().where((key) => _owned(key, '$userId')).toList()) {
      await _prefs.remove(key);
    }
  }
}
