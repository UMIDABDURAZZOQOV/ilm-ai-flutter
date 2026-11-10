import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/lesson_draft_store.dart';
import '../data/skill_tree_models.dart';
import '../../learning/data/assessment_repository.dart';

enum LessonEntryState { start, resume, expired, review, locked }

/// Presentation of an existing server lesson and its validated local draft.
/// This never starts an attempt, unlocks a lesson or writes progress.
class LessonEntry {
  const LessonEntry(
    this.state, {
    this.position,
    this.total,
    this.theory = false,
  });
  final LessonEntryState state;
  final int? position, total;
  final bool theory;

  factory LessonEntry.resolve(
    SkillTreeLesson lesson,
    Map<String, dynamic>? draft,
    DateTime now,
  ) {
    if (lesson.status == LessonStatus.locked) {
      return const LessonEntry(LessonEntryState.locked);
    }
    if (lesson.status == LessonStatus.completed) {
      return const LessonEntry(LessonEntryState.review);
    }
    if (draft == null) return const LessonEntry(LessonEntryState.start);
    final age = now.millisecondsSinceEpoch - (draft['started_at'] as int);
    if (age < 0 || age >= const Duration(hours: 24).inMilliseconds) {
      return const LessonEntry(LessonEntryState.expired);
    }
    final theory = draft['phase'] == 'learning';
    final start = draft['start'] as Map;
    return LessonEntry(
      LessonEntryState.resume,
      position: (draft[theory ? 'theory_index' : 'index'] as int) + 1,
      total: (start[theory ? 'theory' : 'questions'] as List).length,
      theory: theory,
    );
  }

  String action(String language) {
    final labels = switch (state) {
      LessonEntryState.start => ['BOSHLASH', 'НАЧАТЬ', 'START'],
      LessonEntryState.resume => ['DAVOM ETISH', 'ПРОДОЛЖИТЬ', 'CONTINUE'],
      LessonEntryState.expired => [
        'URINISHNI YANGILASH',
        'ОБНОВИТЬ ПОПЫТКУ',
        'RENEW ATTEMPT',
      ],
      LessonEntryState.review => [
        'QAYTA O‘TISH',
        'ПОВТОРИТЬ',
        'PRACTISE AGAIN',
      ],
      LessonEntryState.locked => ['QULFLANGAN', 'ЗАБЛОКИРОВАНО', 'LOCKED'],
    };
    return labels[language == 'ru'
        ? 1
        : language == 'en'
        ? 2
        : 0];
  }

  String description(String language) {
    if (state == LessonEntryState.resume &&
        (position == null || total == null || total! <= 0)) {
      // A request ID is saved before the server responds. Until its content
      // arrives, the draft is resumable but its page count is unknown.
      return switch (language) {
        'ru' => 'Урок сохранён на устройстве',
        'en' => 'Lesson saved on this device',
        _ => 'Dars shu qurilmada saqlangan',
      };
    }
    final labels = switch (state) {
      LessonEntryState.start => [
        'Boshlashga tayyor',
        'Можно начинать',
        'Ready when you are',
      ],
      LessonEntryState.resume =>
        theory
            ? [
                'Nazariya $position/$total · shu qurilmada saqlangan',
                'Теория $position/$total · сохранено на устройстве',
                'Theory $position/$total · saved on this device',
              ]
            : [
                'Savol $position/$total · shu qurilmada saqlangan',
                'Вопрос $position/$total · сохранено на устройстве',
                'Question $position/$total · saved on this device',
              ],
      LessonEntryState.expired => [
        'Oldingi urinish muddati tugagan',
        'Срок предыдущей попытки истёк',
        'The previous attempt has expired',
      ],
      LessonEntryState.review => [
        'Bajarilgan · yana mashq qilish mumkin',
        'Завершено · можно повторить',
        'Completed · ready to practise again',
      ],
      LessonEntryState.locked => [
        'Oldingi qadamni tugating',
        'Завершите предыдущий шаг',
        'Complete the previous step first',
      ],
    };
    return labels[language == 'ru'
        ? 1
        : language == 'en'
        ? 2
        : 0];
  }
}

final lessonEntryProvider = Provider.autoDispose
    .family<LessonEntry, SkillTreeLesson>((ref, lesson) {
      final user = ref.watch(currentUserIdProvider);
      ref.watch(studyRevisionProvider);
      if (lesson.assessmentKey != null) {
        if (lesson.status == LessonStatus.locked) {
          return const LessonEntry(LessonEntryState.locked);
        }
        if (lesson.status == LessonStatus.completed) {
          return const LessonEntry(LessonEntryState.review);
        }
        if (user == null) return const LessonEntry(LessonEntryState.start);
        try {
          final raw = ref
              .watch(prefsServiceProvider)
              .getString(
                AssessmentRepository.storageKey(
                  apiBaseUrl,
                  user,
                  lesson.assessmentSubject!,
                  lesson.assessmentKey!,
                ),
              );
          if (raw == null) return const LessonEntry(LessonEntryState.start);
          final saved = jsonDecode(raw) as Map;
          final started = saved['started_at'] as int;
          final age = DateTime.now().millisecondsSinceEpoch - started;
          if (age < 0 || age >= const Duration(hours: 24).inMilliseconds) {
            return const LessonEntry(LessonEntryState.expired);
          }
          final theory = saved['teaching_done'] != true;
          final index =
              saved[theory ? 'teaching_index' : 'question_index'] as int? ?? 0;
          final storedTotal = saved[theory ? 'theory_total' : 'question_total'];
          final total = storedTotal is int && storedTotal > 0
              ? storedTotal
              : null;
          return LessonEntry(
            LessonEntryState.resume,
            position: total == null ? null : (index + 1).clamp(1, total),
            total: total,
            theory: theory,
          );
        } catch (_) {
          return const LessonEntry(LessonEntryState.start);
        }
      }
      final draft = user == null || lesson.status != LessonStatus.unlocked
          ? null
          : LessonDraftStore(
              ref.watch(prefsServiceProvider),
              apiBaseUrl,
              user,
              lesson.id,
            ).read();
      final now = DateTime.now();
      final entry = LessonEntry.resolve(lesson, draft, now);
      if (entry.state == LessonEntryState.resume) {
        final deadline = DateTime.fromMillisecondsSinceEpoch(
          draft!['started_at'] as int,
        ).add(const Duration(hours: 24));
        final timer = Timer(deadline.difference(now), ref.invalidateSelf);
        ref.onDispose(timer.cancel);
      }
      return entry;
    });
