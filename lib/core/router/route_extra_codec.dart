import 'dart:convert';

import '../../features/quiz/data/quiz_models.dart';
import '../../features/skills/data/skill_tree_models.dart';
import '../../features/skills/presentation/skill_practice_screen.dart';

/// Keeps navigation descriptors when go_router serializes a pushed route.
/// Serializes existing route DTOs; auth/session storage is separate from routing.
class LearningRouteExtraCodec extends Codec<Object?, Object?> {
  const LearningRouteExtraCodec();

  @override
  Converter<Object?, Object?> get encoder => const _ExtraEncoder();
  @override
  Converter<Object?, Object?> get decoder => const _ExtraDecoder();
}

Map<String, Object?> _tag(String type, Object? value) => {
  '_ilm_route': type,
  'version': 1,
  'value': value,
};

class _ExtraEncoder extends Converter<Object?, Object?> {
  const _ExtraEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null || input is String || input is num || input is bool) {
      return input;
    }
    if (input is SkillTreeLesson) {
      return _tag('lesson', {
        'id': input.id,
        'slug': input.slug,
        'title_uz': input.titleUz,
        'title_ru': input.titleRu,
        'title_en': input.titleEn,
        'order_index': input.orderIndex,
        'xp_reward': input.xpReward,
        'status': input.status.name,
        'stars': input.stars,
        'best_score_pct': input.bestScorePct,
        'assessment_key': input.assessmentKey,
        'assessment_subject': input.assessmentSubject,
        'grade': input.grade,
      });
    }
    if (input is SkillSubject) {
      return _tag('subject', {
        'id': input.id,
        'slug': input.slug,
        'name_uz': input.nameUz,
        'name_ru': input.nameRu,
        'name_en': input.nameEn,
        'icon': input.icon,
        'color': input.color,
        'available': input.available,
        'grades': input.grades,
      });
    }
    if (input is PracticeMode) return _tag('practice', input.name);
    if (input is List<QuizQuestion>) {
      return _tag('quiz_questions', input.map(convert).toList());
    }
    if (input is List<QuizResultItem>) {
      return _tag('quiz_results', input.map(convert).toList());
    }
    if (input is QuizQuestion) {
      return _tag('quiz_question', {
        'question': input.question,
        'options': input.options,
        'correct_answer': input.correctAnswer,
        'explanation': input.explanation,
        'type': input.type,
        'topic': input.topic,
      });
    }
    if (input is QuizResultItem) return _tag('quiz_result', input.toJson());
    if (input is List) return input.map(convert).toList();
    if (input is Map && input.keys.every((key) => key is String)) {
      return _tag('map', {
        for (final entry in input.entries)
          entry.key as String: convert(entry.value),
      });
    }
    // Matches go_router's previous unsupported-extra behavior, without persisting
    // arbitrary objects or weakening the object-backed route guards.
    return null;
  }
}

class _ExtraDecoder extends Converter<Object?, Object?> {
  const _ExtraDecoder();

  @override
  Object? convert(Object? input) {
    if (input == null || input is String || input is num || input is bool) {
      return input;
    }
    if (input is List) return input.map(convert).toList();
    if (input is! Map || input['version'] != 1) return null;
    try {
      final value = input['value'];
      switch (input['_ilm_route']) {
        case 'lesson':
          final lesson = SkillTreeLesson.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
          if (lesson.assessmentKey != null &&
              ((lesson.assessmentSubject ?? '').isEmpty ||
                  lesson.grade == null ||
                  lesson.grade! < 5 ||
                  lesson.grade! > 11)) {
            return null;
          }
          return lesson;
        case 'subject':
          return SkillSubject.fromJson(Map<String, dynamic>.from(value as Map));
        case 'practice':
          return PracticeMode.values.byName(value as String);
        case 'quiz_question':
          return QuizQuestion.fromJson(Map<String, dynamic>.from(value as Map));
        case 'quiz_questions':
          return (value as List).map(convert).cast<QuizQuestion>().toList();
        case 'quiz_results':
          return (value as List).map(convert).cast<QuizResultItem>().toList();
        case 'quiz_result':
          final data = Map<String, dynamic>.from(value as Map);
          return QuizResultItem(
            question: data['question'] as String,
            userAnswer: data['user_answer'] as String,
            correctAnswer: data['correct_answer'] as String,
            isCorrect: data['is_correct'] as bool,
            topic: data['topic'] as String?,
            explanation: data['explanation'] as String?,
          );
        case 'map':
          final map = Map<String, dynamic>.from(value as Map);
          return map.map((key, value) => MapEntry(key, convert(value)));
        default:
          return null;
      }
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    } on FormatException {
      return null;
    }
  }
}
