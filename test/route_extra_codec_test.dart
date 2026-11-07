import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/router/route_extra_codec.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_practice_screen.dart';
import 'package:ilm_ai_flutter/features/quiz/data/quiz_models.dart';

void main() {
  const codec = LearningRouteExtraCodec();
  Object? roundtrip(Object? input) =>
      codec.decode(jsonDecode(jsonEncode(codec.encode(input))));

  test(
    'reviewed lesson preserves every descriptor field, including locked state',
    () {
      final value = SkillTreeLesson(
        id: -9,
        slug: 'fixture',
        titleUz: 'UZ',
        titleRu: 'RU',
        titleEn: 'EN',
        orderIndex: 4,
        xpReward: 10,
        status: LessonStatus.locked,
        stars: 2,
        bestScorePct: 75.5,
        assessmentKey: 'fixture-p1',
        assessmentSubject: 'fizika',
        grade: 6,
      );
      final restored = roundtrip(value) as SkillTreeLesson;
      expect(restored.id, value.id);
      expect(restored.slug, value.slug);
      expect(restored.titleUz, value.titleUz);
      expect(restored.titleRu, value.titleRu);
      expect(restored.titleEn, value.titleEn);
      expect(restored.orderIndex, value.orderIndex);
      expect(restored.xpReward, value.xpReward);
      expect(restored.status, LessonStatus.locked);
      expect(restored.stars, value.stars);
      expect(restored.bestScorePct, value.bestScorePct);
      expect(restored.assessmentKey, value.assessmentKey);
      expect(restored.assessmentSubject, value.assessmentSubject);
      expect(restored.grade, value.grade);
    },
  );

  test('subject availability and grades survive serialization', () {
    final subject = SkillSubject(
      id: 3,
      slug: 'kimyo',
      nameUz: 'Kimyo',
      nameRu: 'RU',
      nameEn: 'Chemistry',
      available: false,
      grades: [7, 8, 9],
      icon: 'flask',
      color: 'purple',
    );
    final restored = roundtrip(subject) as SkillSubject;
    expect(restored.available, isFalse);
    expect(restored.grades, [7, 8, 9]);
    expect(restored.slug, subject.slug);
    expect(restored.icon, subject.icon);
    expect(restored.color, subject.color);
  });

  test('practice and existing quiz extras remain typed inside nested maps', () {
    final map =
        roundtrip({
              'mode': PracticeMode.checkpoint,
              'unit_id': 9,
              'questions': [
                QuizQuestion(
                  question: 'Fixture',
                  options: ['a', 'b'],
                  correctAnswer: 'a',
                  explanation: 'Fixture',
                ),
              ],
              'plain': {
                'value': true,
                'list': [1, 'two', null],
              },
            })
            as Map;
    expect(map['mode'], PracticeMode.checkpoint);
    expect(map['unit_id'], 9);
    expect(map['questions'], isA<List<QuizQuestion>>());
    expect(
      (map['questions'] as List<QuizQuestion>).single,
      isA<QuizQuestion>(),
    );
    expect(map['plain'], {
      'value': true,
      'list': [1, 'two', null],
    });
  });

  test('existing quiz result route retains its typed result list', () {
    final result = QuizResultItem(
      question: 'Fixture',
      userAnswer: 'b',
      correctAnswer: 'a',
      isCorrect: false,
      topic: 'Fixture',
      explanation: 'Fixture',
    );
    final map =
        roundtrip({
              'score': 0,
              'total': 1,
              'results': [result],
            })
            as Map;
    final rows = map['results'] as List<QuizResultItem>;
    expect(rows.single.toJson(), result.toJson());
  });

  test('malformed or unsupported descriptors fail closed', () {
    for (final extra in [
      {'_ilm_route': 'lesson', 'version': 1, 'value': {}},
      {'_ilm_route': 'practice', 'version': 1, 'value': 'invalid'},
      {'_ilm_route': 'subject', 'version': 99, 'value': {}},
      {'_ilm_route': 'unknown', 'version': 1, 'value': {}},
    ]) {
      expect(codec.decode(extra), isNull);
    }
    expect(codec.encode(Object()), isNull);
    expect(roundtrip(null), isNull);
  });
}
