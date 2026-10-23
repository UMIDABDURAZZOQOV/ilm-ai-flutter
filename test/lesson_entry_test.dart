import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/services/sound_service.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/skills/application/lesson_entry.dart';
import 'package:ilm_ai_flutter/features/skills/data/lesson_draft_store.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/learning_journey_widgets.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_lesson_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_path_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/study_start_sheet.dart';
import 'subject_experience_test.dart' as fixture;

final _start = LessonStartResult.fromJson(
  jsonDecode(File('test/fixtures/biology_first_lesson.json').readAsStringSync())
      as Map<String, dynamic>,
);
Map<String, dynamic> _draft(DateTime now, {bool theory = false}) => {
  'start': LessonDraftStore.snapshot(_start),
  'index': 4,
  'theory_index': 0,
  'selected': null,
  'answered': false,
  'reviewing': false,
  'phase': theory ? 'learning' : 'playing',
  'results': <Map<String, dynamic>>[],
  'mistakes': <int>[],
  'elapsed_ms': 1000,
  'started_at': now.millisecondsSinceEpoch,
};

SkillTreeLesson _lesson(int id, LessonStatus status) => SkillTreeLesson(
  id: id,
  slug: 'lesson-$id',
  titleUz: 'Dars $id',
  titleRu: 'Урок $id',
  titleEn: 'Lesson $id',
  orderIndex: id,
  xpReward: 10,
  status: status,
  stars: status == LessonStatus.completed ? 2 : 0,
);
SkillTreeUnit _unit(
  List<SkillTreeLesson> lessons, {
  String exam = 'none',
  bool coverage = true,
}) => SkillTreeUnit(
  id: 1,
  slug: 'unit',
  titleUz: 'Birinchi bo‘lim',
  titleRu: 'Первый раздел',
  titleEn: 'First unit',
  orderIndex: 0,
  lessons: lessons,
  examStatus: exam,
  coverageComplete: coverage,
);

class _Repository extends fixture.FakeRepository {
  _Repository(List<SkillTreeUnit> units) : super(units: units);
  int starts = 0;
  @override
  Future<LessonStartResult> startLesson({
    required int lessonId,
    required int userId,
    String language = 'uz',
  }) async {
    starts++;
    return _start;
  }
}

void main() {
  final now = DateTime(2026, 10, 23, 14);
  test('entry trusts server lock/completion ahead of stale local drafts', () {
    expect(
      LessonEntry.resolve(
        _lesson(1, LessonStatus.locked),
        _draft(now),
        now,
      ).state,
      LessonEntryState.locked,
    );
    expect(
      LessonEntry.resolve(
        _lesson(1, LessonStatus.completed),
        _draft(now),
        now,
      ).state,
      LessonEntryState.review,
    );
    expect(
      LessonEntry.resolve(_lesson(1, LessonStatus.unlocked), null, now).state,
      LessonEntryState.start,
    );
  });
  test(
    'entry reports the exact saved theory/question, never guessed completion',
    () {
      final lesson = _lesson(1, LessonStatus.unlocked);
      final question = LessonEntry.resolve(lesson, _draft(now), now);
      expect(question.position, 5);
      expect(question.total, 12);
      expect(question.theory, false);
      final theory = LessonEntry.resolve(
        lesson,
        _draft(now, theory: true),
        now,
      );
      expect(theory.position, 1);
      expect(theory.total, _start.theory.length);
      expect(theory.theory, true);
    },
  );
  test(
    'expiry matches the existing lesson boundary, including clock rollback',
    () {
      final lesson = _lesson(1, LessonStatus.unlocked);
      expect(
        LessonEntry.resolve(
          lesson,
          _draft(now),
          now.add(const Duration(hours: 24) - Duration(milliseconds: 1)),
        ).state,
        LessonEntryState.resume,
      );
      expect(
        LessonEntry.resolve(
          lesson,
          _draft(now),
          now.add(const Duration(hours: 24)),
        ).state,
        LessonEntryState.expired,
      );
      expect(
        LessonEntry.resolve(
          lesson,
          _draft(now),
          now.subtract(const Duration(milliseconds: 1)),
        ).state,
        LessonEntryState.expired,
      );
    },
  );

  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      for (final state in [
        LessonEntryState.start,
        LessonEntryState.resume,
        LessonEntryState.expired,
      ]) {
        testWidgets('entry card $lang/$dark/$state at 320dp/200%', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final entry = LessonEntry(state, position: 5, total: 12);
          var taps = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(dark ? darkColors : lightColors),
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        LearningContinueCard(
                          language: lang,
                          title: 'Lesson title / Dars / Урок',
                          entry: entry,
                          todayXp: 10,
                          goalXp: 20,
                          onGoal: () {},
                          onContinue: () => taps++,
                        ),
                        LearningUnitHeader(
                          title: 'Unit / Bo‘lim / Раздел',
                          language: lang,
                          completed: 1,
                          total: 4,
                          coverageComplete: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(entry.action(lang)));
          await tester.tap(find.text(entry.action(lang)));
          await tester.pumpAndSettle();
          expect(taps, 1);
          expect(find.text(entry.description(lang)), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  test(
    'provider isolates user/origin, ignores damaged cache and never writes it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await PrefsService.create();
      final lesson = _lesson(1, LessonStatus.unlocked);
      final store = LessonDraftStore(prefs, apiBaseUrl, 7, 1);
      final draft = _draft(DateTime.now());
      await store.save(draft);
      final before = prefs.getString(store.key);
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(7),
        ],
      );
      final subscription = container.listen(
        lessonEntryProvider(lesson),
        (_, _) {},
      );
      expect(
        container.read(lessonEntryProvider(lesson)).state,
        LessonEntryState.resume,
      );
      expect(prefs.getString(store.key), before);
      subscription.close();
      container.dispose();
      final other = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(8),
        ],
      );
      expect(
        other.read(lessonEntryProvider(lesson)).state,
        LessonEntryState.start,
      );
      other.dispose();
      await prefs.remove(store.key);
      await LessonDraftStore(
        prefs,
        'https://another-origin.test',
        7,
        1,
      ).save(draft);
      final isolated = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(7),
        ],
      );
      expect(
        isolated.read(lessonEntryProvider(lesson)).state,
        LessonEntryState.start,
      );
      await prefs.setString(store.key, 'broken');
      isolated.invalidate(lessonEntryProvider(lesson));
      expect(
        isolated.read(lessonEntryProvider(lesson)).state,
        LessonEntryState.start,
      );
      isolated.dispose();
    },
  );

  test('switching accounts invalidates a visible resume entry', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefsService.create();
    final lesson = _lesson(1, LessonStatus.unlocked);
    await LessonDraftStore(
      prefs,
      apiBaseUrl,
      7,
      1,
    ).save(_draft(DateTime.now()));
    final account = StateProvider<int?>((ref) => 7);
    final container = ProviderContainer(
      overrides: [
        prefsServiceProvider.overrideWithValue(prefs),
        currentUserIdProvider.overrideWith((ref) => ref.watch(account)),
      ],
    );
    final subscription = container.listen(
      lessonEntryProvider(lesson),
      (_, _) {},
    );
    expect(
      container.read(lessonEntryProvider(lesson)).state,
      LessonEntryState.resume,
    );
    container.read(account.notifier).state = 8;
    expect(
      container.read(lessonEntryProvider(lesson)).state,
      LessonEntryState.start,
    );
    subscription.close();
    container.dispose();
  });

  for (final status in ['new', 'saved', 'expired']) {
    testWidgets(
      'home, row and sheet agree for $status; resume makes no start request',
      (tester) async {
        SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
        final prefs = await PrefsService.create();
        final lesson = _lesson(1, LessonStatus.unlocked);
        final repo = _Repository([
          _unit([lesson]),
        ]);
        if (status != 'new') {
          await LessonDraftStore(prefs, apiBaseUrl, 7, 1).save(
            _draft(
              DateTime.now().subtract(
                Duration(hours: status == 'expired' ? 24 : 0),
              ),
            ),
          );
        }
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => SkillPathScreen(subject: fixture.subject),
            ),
            GoRoute(
              path: '/skills/lesson',
              builder: (_, state) =>
                  SkillLessonScreen(lesson: state.extra! as SkillTreeLesson),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              prefsServiceProvider.overrideWithValue(prefs),
              currentUserIdProvider.overrideWithValue(7),
              skillTreeRepositoryProvider.overrideWithValue(repo),
              soundServiceProvider.overrideWithValue(FakeSoundService()),
            ],
            child: MaterialApp.router(
              theme: buildAppTheme(lightColors),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final expected = LessonEntry(
          status == 'new'
              ? LessonEntryState.start
              : status == 'saved'
              ? LessonEntryState.resume
              : LessonEntryState.expired,
        ).action('en');
        expect(find.text(expected), findsNWidgets(2));
        await tester.tap(find.byType(LearningJourneyTile).first);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(LessonPopoverContent),
            matching: find.text(expected),
          ),
          findsOneWidget,
        );
        expect(repo.starts, 0);
        if (status == 'saved') {
          await tester.tap(
            find.descendant(
              of: find.byType(LessonPopoverContent),
              matching: find.text(expected),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Question 5/12'), findsOneWidget);
          expect(repo.starts, 0);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.tap(find.text('Save & leave'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Question 5/12'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'earlier unlocked checkpoint is the next action before a later lesson',
    (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
      final prefs = await PrefsService.create();
      final completed = _unit([
        _lesson(1, LessonStatus.completed),
      ], exam: 'unlocked');
      final later = _unit([_lesson(2, LessonStatus.unlocked)]);
      final repo = _Repository([completed, later]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue(7),
            skillTreeRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: SkillPathScreen(subject: fixture.subject),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('UNIT CHECKPOINT'), findsOneWidget);
      await tester.tap(find.text('UNIT CHECKPOINT'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckpointPopoverContent), findsOneWidget);
      expect(repo.starts, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large path lazily mounts rows and reports real unit progress', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
    final prefs = await PrefsService.create();
    final lessons = [
      for (var i = 0; i < 406; i++)
        _lesson(
          i,
          i == 0
              ? LessonStatus.completed
              : i == 1
              ? LessonStatus.unlocked
              : LessonStatus.locked,
        ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(7),
          skillTreeRepositoryProvider.overrideWithValue(
            _Repository([_unit(lessons, coverage: false)]),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: SkillPathScreen(subject: fixture.subject),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LearningJourneyTile).evaluate().length, lessThan(20));
    expect(find.text('1/406 available lessons completed'), findsOneWidget);
    expect(
      find.text('More lessons in this unit are in preparation.'),
      findsOneWidget,
    );
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Lesson 405'), findsOneWidget);
    expect(find.byType(LearningJourneyTile).evaluate().length, lessThan(20));
    expect(tester.takeException(), isNull);
  });
}
