import 'dart:convert';
import '../../../core/storage/prefs_service.dart';

/// Local form state, scoped to guest or account. Never stores auth credentials.
class OnboardingDraftStore {
  final PrefsService prefs;
  const OnboardingDraftStore(this.prefs);
  String key(int? userId) => 'onboarding_draft_${userId ?? 'guest'}';

  Map<String, dynamic>? read(int? userId) {
    final raw = prefs.getString(key(userId));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(int? userId, Map<String, dynamic> draft) =>
      prefs.setString(key(userId), jsonEncode({'version': 1, ...draft}));

  Future<void> clear(int? userId) => prefs.remove(key(userId));

  Future<Map<String, dynamic>?> adopt(int userId) async {
    final own = read(userId);
    final guest = read(null);
    if (guest == null) return own;
    final draft = own ?? guest;
    if (own == null) await save(userId, draft);
    for (final field in ['subject', 'class', 'source', 'reason']) {
      final value = guest[field];
      if (value is String && prefs.getString('${field}_$userId') == null) {
        await prefs.setString('${field}_$userId', value);
      }
    }
    for (final field in ['daily_goal', 'level']) {
      final value = guest[field];
      if (value is int && prefs.getInt('${field}_$userId') == null) {
        await prefs.setInt('${field}_$userId', value);
      }
    }
    await clear(null); // One guest draft can be adopted by only one account.
    return draft;
  }
}
