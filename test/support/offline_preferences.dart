import 'package:dio/dio.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';

/// Widget suites exercise cached/offline preferences without real HTTP timers.
class OfflinePreferences extends LearningPreferences {
  OfflinePreferences(PrefsService prefs) : super(Dio(), prefs);
  @override
  Future<bool> flush(int id) async => false;
  @override
  Future<void> restore(int id) async {}
}
