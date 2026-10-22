import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../core/storage/prefs_service.dart';
import 'skill_tree_models.dart';

/// UI recovery only. The server still owns grading, expiry and rewards.
/// Writes and deletion are ordered so an older write cannot revive a draft.
class LessonDraftStore {
  final PrefsService prefs;
  final String key;
  Future<void> _writes = Future.value();

  LessonDraftStore(this.prefs, String origin, int user, int lesson)
    : key = 'lesson_ui_v1:${sha256.convert(utf8.encode(origin))}:$user:$lesson';

  Map<String, dynamic>? read() {
    try {
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final start = LessonStartResult.fromJson(
        Map<String, dynamic>.from(data['start'] as Map),
      );
      final index = data['index'] as int;
      final theoryIndex = data['theory_index'] as int;
      final results = (data['results'] as List).cast<Map>();
      final mistakes = (data['mistakes'] as List).cast<int>();
      final answered = data['answered'] as bool;
      final selected = data['selected'] as String?;
      final phase = data['phase'];
      final ids = start.questions.map((q) => q.id).toSet();
      if (start.attemptId <= 0 ||
          start.questions.isEmpty ||
          ids.length != start.questions.length ||
          index < 0 ||
          index >= start.questions.length ||
          theoryIndex < 0 ||
          (start.theory.isNotEmpty && theoryIndex >= start.theory.length) ||
          !{'learning', 'playing'}.contains(phase) ||
          (phase == 'learning' && start.theory.isEmpty) ||
          data['reviewing'] is! bool ||
          data['elapsed_ms'] is! int ||
          (data['elapsed_ms'] as int) < 0 ||
          data['started_at'] is! int ||
          (answered && selected == null) ||
          (selected != null &&
              !start.questions[index].options.contains(selected)) ||
          mistakes.any((i) => i < 0 || i >= start.questions.length) ||
          results.map((r) => r['question_id']).toSet().length !=
              results.length ||
          results.any(
            (r) =>
                !ids.contains(r['question_id']) ||
                r['user_answer'] is! String ||
                r['is_correct'] is! bool,
          )) {
        return null;
      }
      return data;
    } catch (_) {
      return null; // A damaged cache must not crash or alter server progress.
    }
  }

  Future<void> save(Map<String, dynamic> data) {
    final encoded = jsonEncode(data); // Freeze before queuing the write.
    return _enqueue(() => prefs.setString(key, encoded));
  }

  Future<void> clear() => _enqueue(() => prefs.remove(key));

  Future<void> _enqueue(Future<void> Function() action) {
    _writes = _writes.catchError((Object _) {}).then((_) => action());
    return _writes;
  }

  static Map<String, dynamic> snapshot(LessonStartResult start) => {
    'attempt_id': start.attemptId,
    'theory': [
      for (final c in start.theory)
        {
          'title': c.title,
          'body': c.body,
          'example': c.example,
          'source': c.source,
        },
    ],
    'questions': [
      for (final q in start.questions)
        {
          'id': q.id,
          'question_text': q.questionText,
          'options': q.options,
          'correct_answer': q.correctAnswer,
          'explanation': q.explanation,
          'order_index': q.orderIndex,
          'source': q.source,
        },
    ],
  };
}
