import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/learning/data/assessment_repository.dart';
import 'package:ilm_ai_flutter/features/skills/application/lesson_entry.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';

SkillTreeLesson lesson({LessonStatus status = LessonStatus.unlocked}) =>
    SkillTreeLesson(
      id: 1,
      slug: 'synthetic-reviewed',
      assessmentKey: 'synthetic-reviewed',
      assessmentSubject: 'fizika',
      grade: 6,
      titleUz: 'Synthetic',
      titleRu: 'Synthetic',
      titleEn: 'Synthetic',
      orderIndex: 1,
      xpReward: 10,
      status: status,
      stars: 0,
    );

Future<LessonEntry> entry(
  Map<String, dynamic> saved, {
  LessonStatus status = LessonStatus.unlocked,
  int user = 7,
}) async {
  final key = AssessmentRepository.storageKey(
    apiBaseUrl,
    7,
    'fizika',
    'synthetic-reviewed',
  );
  final original = jsonEncode(saved);
  SharedPreferences.setMockInitialValues({key: original});
  final prefs = await PrefsService.create();
  final container = ProviderContainer(
    overrides: [
      prefsServiceProvider.overrideWithValue(prefs),
      currentUserIdProvider.overrideWithValue(user),
    ],
  );
  try {
    final result = container.read(lessonEntryProvider(lesson(status: status)));
    expect(
      prefs.getString(key),
      original,
    ); // Presentation never rewrites drafts.
    return result;
  } finally {
    container.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> saved(bool theory) => {
    'request_id': 'synthetic-request-before-response',
    'drafts': <String, dynamic>{},
    'started_at': DateTime.now().millisecondsSinceEpoch,
    'teaching_done': !theory,
    'teaching_index': 0,
    'question_index': 0,
  };

  for (final theory in [true, false]) {
    test(
      'unreceived ${theory ? 'theory' : 'question'} total is not guessed',
      () async {
        final value = await entry(saved(theory));
        expect(value.state, LessonEntryState.resume);
        expect(value.total, isNull);
        expect(value.position, isNull);
        for (final language in ['uz', 'ru', 'en']) {
          expect(value.description(language), isNot(contains('1/1')));
          expect(value.description(language), isNot(contains('null')));
          expect(value.description(language), isNotEmpty);
        }
      },
    );
    for (final invalid in [0, -1, 'unknown']) {
      test(
        'invalid ${theory ? 'theory' : 'question'} total $invalid stays resumable',
        () async {
          final value = await entry({
            ...saved(theory),
            theory ? 'theory_total' : 'question_total': invalid,
          });
          expect(value.state, LessonEntryState.resume);
          expect(value.total, isNull);
          expect(value.position, isNull);
        },
      );
    }
    test(
      'known ${theory ? 'theory' : 'question'} position remains exact',
      () async {
        final value = await entry({
          ...saved(theory),
          theory ? 'theory_total' : 'question_total': 5,
          theory ? 'teaching_index' : 'question_index': 1,
        });
        expect(value.state, LessonEntryState.resume);
        expect(value.position, 2);
        expect(value.total, 5);
        for (final language in ['uz', 'ru', 'en']) {
          expect(value.description(language), contains('2/5'));
        }
      },
    );
  }
  test(
    'unknown totals do not bypass server lock/completion or account scope',
    () async {
      expect(
        (await entry(saved(true), status: LessonStatus.locked)).state,
        LessonEntryState.locked,
      );
      expect(
        (await entry(saved(true), status: LessonStatus.completed)).state,
        LessonEntryState.review,
      );
      expect((await entry(saved(true), user: 8)).state, LessonEntryState.start);
    },
  );
}
