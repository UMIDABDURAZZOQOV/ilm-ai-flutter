import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/prefs_service.dart';

/// Offline writes are retained per account and retried at the next restoration.
class LearningPreferences {
  final Dio dio;
  final PrefsService prefs;
  final _inFlight = <int, Future<bool>>{};
  LearningPreferences(this.dio, this.prefs);
  static const fields = {
    'daily_goal_xp': 'daily_goal',
    'subject': 'subject',
    'grade': 'class',
    'source': 'source',
    'level': 'level',
    'reason': 'reason',
  };

  Map<String, dynamic> local(int id) {
    final values = <String, dynamic>{};
    for (final entry in fields.entries) {
      final Object? value = entry.key == 'daily_goal_xp' || entry.key == 'level'
          ? prefs.getInt('${entry.value}_$id')
          : prefs.getString('${entry.value}_$id');
      if (value != null) values[entry.key] = value;
    }
    return values;
  }

  Future<void> _store(int id, Map values) async {
    for (final entry in fields.entries) {
      final value = values[entry.key];
      if (value is int) await prefs.setInt('${entry.value}_$id', value);
      if (value is String) await prefs.setString('${entry.value}_$id', value);
    }
  }

  Future<void> save(int id, Map<String, dynamic> values) async {
    await _store(id, values);
    await prefs.setInt(
      'study_preferences_version_$id',
      (prefs.getInt('study_preferences_version_$id') ?? 0) + 1,
    );
    await prefs.setBool('study_preferences_dirty_$id', true);
    unawaited(flush(id));
  }

  Future<bool> flush(int id) {
    final running = _inFlight[id];
    if (running != null) return running;
    final task = _send(id);
    _inFlight[id] = task;
    return task.whenComplete(() => _inFlight.remove(id));
  }

  Future<bool> _send(int id) async {
    do {
      final version = prefs.getInt('study_preferences_version_$id') ?? 0;
      final cancel = CancelToken();
      final deadline = Timer(
        const Duration(seconds: 10),
        () => cancel.cancel('preference_timeout'),
      );
      try {
        await dio.post(
          '/skills/$id/preferences',
          data: local(id),
          cancelToken: cancel,
        );
        if (version == (prefs.getInt('study_preferences_version_$id') ?? 0)) {
          await prefs.setBool('study_preferences_dirty_$id', false);
          return true;
        }
      } catch (_) {
        return false;
      } finally {
        deadline.cancel();
      }
    } while (true); // A newer local edit is sent after the earlier request settles.
  }

  Future<void> restore(int id) async {
    if (prefs.getBool('study_preferences_dirty_$id')) {
      await flush(id);
      return;
    }
    try {
      final response = await dio
          .get('/skills/$id/preferences')
          .timeout(const Duration(seconds: 10));
      final remote = response.data['preferences'];
      if (prefs.getBool('study_preferences_dirty_$id')) return;
      if (remote is Map) {
        await _store(id, remote);
      } else if (local(id).isNotEmpty) {
        await save(id, {});
      }
    } catch (_) {
      /* Cached account preferences stay available offline. */
    }
  }
}

final learningPreferencesProvider = Provider(
  (ref) => LearningPreferences(
    ref.watch(dioProvider),
    ref.watch(prefsServiceProvider),
  ),
);
