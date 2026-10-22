import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/services/sound_service.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/celebration_confetti.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/settings_screen.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/lesson_draft_store.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/daily_goal_bottom_sheet.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_lesson_screen.dart';
import 'subject_experience_test.dart' as fixture;
import 'support/offline_preferences.dart';

class _Repository extends fixture.FakeRepository {
  int starts = 0, completes = 0;
  bool failStart = false, failComplete = false;
  bool passed = false;
  final List<int> attempts = [];
  @override
  Future<LessonStartResult> startLesson({
    required int lessonId,
    required int userId,
    String language = 'uz',
  }) async {
    starts++;
    if (failStart) throw TimeoutException('offline');
    return super.startLesson(
      lessonId: lessonId,
      userId: userId,
      language: language,
    );
  }

  @override
  Future<LessonCompleteResult> completeLesson({
    required int lessonId,
    required int userId,
    required int attemptId,
    required List<LessonResultItem> results,
  }) async {
    completes++;
    attempts.add(attemptId);
    if (failComplete) {
      failComplete = false;
      throw TimeoutException('response lost');
    }
    final result = await super.completeLesson(
      lessonId: lessonId,
      userId: userId,
      attemptId: attemptId,
      results: results,
    );
    return passed
        ? LessonCompleteResult(
            stars: 3,
            score: 1,
            total: 1,
            xpAwarded: 20,
            xpTotal: 20,
            streakDays: 1,
            newlyUnlockedLessonIds: [],
          )
        : result;
  }
}

class _Auth extends fixture.FakeAuth {
  final pending = Completer<void>();
  int saves = 0;
  @override
  Future<StoredTokens?> build() async => StoredTokens(
    accessToken: 'test',
    refreshToken: 'test',
    userId: 7,
    name: 'Learner',
  );
  @override
  Future<void> updateDisplayName(String name) {
    saves++;
    return pending.future;
  }
}

class _Preferences extends OfflinePreferences {
  _Preferences(super.prefs);
  int saves = 0;
  Completer<void>? pending;
  bool fail = true;
  @override
  Future<void> save(int id, Map<String, dynamic> values) async {
    saves++;
    if (pending != null) await pending!.future;
    if (fail) throw StateError('storage unavailable');
    await super.save(id, values);
  }
}

class _DiskPrefs extends PrefsService {
  _DiskPrefs(super.prefs);
  bool fail = true;
  @override
  Future<void> setString(String key, String value) {
    if (fail && key.startsWith('lesson_ui_v1:')) {
      throw StateError('disk full');
    }
    return super.setString(key, value);
  }
}

void main() {
  late PrefsService prefs;
  late _Repository repo;
  late FakeSoundService sounds;
  setUp(() async {
    SharedPreferences.setMockInitialValues({PrefsKeys.language: 'en'});
    prefs = await PrefsService.create();
    repo = _Repository();
    sounds = FakeSoundService();
  });

  Future<void> mount(
    WidgetTester tester, {
    Widget? screen,
    int user = 7,
    _Auth? auth,
    _Preferences? preferences,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(user),
          learningPreferencesProvider.overrideWithValue(
            preferences ?? OfflinePreferences(prefs),
          ),
          skillTreeRepositoryProvider.overrideWithValue(repo),
          soundServiceProvider.overrideWithValue(sounds),
          if (auth != null) authControllerProvider.overrideWith(() => auth),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: screen ?? SkillLessonScreen(lesson: fixture.lesson),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  testWidgets('load failure retries in place and AI explain stays hidden', (
    tester,
  ) async {
    repo.failStart = true;
    await mount(tester);
    expect(find.text('Request timed out. Please try again.'), findsOneWidget);
    repo.failStart = false;
    await tap(tester, 'Retry');
    expect(repo.starts, 2);
    await tap(tester, '3');
    await tap(tester, 'CHECK');
    expect(find.text('Explain with AI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reopen restores mistakes, original answers and lost completion retry',
    (tester) async {
      await mount(tester);
      await tap(tester, '3');
      await tap(tester, 'CHECK');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await mount(tester);
      expect(repo.starts, 1);
      expect(
        find.text('This question will appear again at the end'),
        findsOneWidget,
      );
      await tap(tester, 'Continue');
      await tap(tester, '4');
      await tap(tester, 'CHECK');
      repo.failComplete = true;
      await tap(tester, 'Continue');
      expect(repo.completes, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await mount(tester);
      expect(repo.starts, 1);
      await tap(tester, 'Continue');
      expect(repo.attempts, [1, 1]);
      expect(repo.saved!.single.userAnswer, '3');
      expect(repo.saved!.single.isCorrect, false);
      expect(find.byType(CelebrationConfetti), findsNothing);
      expect(sounds.playLessonCompleteCount, 0);
      expect(
        LessonDraftStore(prefs, apiBaseUrl, 7, fixture.lesson.id).read(),
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('successful server result still celebrates once', (tester) async {
    repo.passed = true;
    await mount(tester);
    await tap(tester, '4');
    await tap(tester, 'CHECK');
    await tap(tester, 'Continue');
    expect(find.byType(CelebrationConfetti), findsOneWidget);
    expect(sounds.playLessonCompleteCount, 1);
    expect(repo.completes, 1);
  });

  testWidgets(
    'disk failure is visible and completion waits for a durable retry',
    (tester) async {
      final disk = _DiskPrefs(await SharedPreferences.getInstance());
      prefs = disk;
      await mount(tester);
      expect(
        find.text(
          'Could not save this lesson on the device. Retry before closing the app.',
        ),
        findsOneWidget,
      );
      await tap(tester, '4');
      await tap(tester, 'CHECK');
      await tap(tester, 'Continue');
      expect(repo.completes, 0);
      disk.fail = false;
      await tap(tester, 'Retry');
      await tap(tester, 'Continue');
      expect(repo.completes, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('expired draft requires explicit restart', (tester) async {
    await mount(tester);
    final store = LessonDraftStore(prefs, apiBaseUrl, 7, fixture.lesson.id);
    final draft = store.read()!;
    draft['started_at'] = DateTime.now()
        .subtract(const Duration(days: 2))
        .millisecondsSinceEpoch;
    await store.save(draft);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await mount(tester);
    expect(repo.starts, 1);
    expect(find.text('Start again'), findsOneWidget);
    await tap(tester, 'Start again');
    expect(repo.starts, 2);
    expect(find.text('CHECK'), findsOneWidget);
  });

  testWidgets(
    'drafts are isolated by account and API origin and reject damage',
    (tester) async {
      await mount(tester);
      await tap(tester, '3');
      final store = LessonDraftStore(prefs, apiBaseUrl, 7, fixture.lesson.id);
      expect(store.read()!['selected'], '3');
      expect(
        LessonDraftStore(prefs, apiBaseUrl, 8, fixture.lesson.id).read(),
        isNull,
      );
      expect(
        LessonDraftStore(
          prefs,
          'http://localhost:8000',
          7,
          fixture.lesson.id,
        ).read(),
        isNull,
      );
      final damaged = store.read()!..['index'] = 999;
      await store.save(damaged);
      expect(store.read(), isNull);
      await prefs.setString(store.key, '{broken');
      expect(store.read(), isNull);
    },
  );

  testWidgets(
    'name save blocks duplicate requests and handles dismissal during failure',
    (tester) async {
      final auth = _Auth();
      await mount(tester, screen: const SettingsScreen(), auth: auth);
      await tap(tester, 'Learner');
      await tester.enterText(find.byType(TextField), 'Learner Updated');
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(auth.saves, 1);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNotNull,
      );
      await tap(tester, 'Cancel');
      auth.pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'goal save failure stays open with retry and disables duplicate submit',
    (tester) async {
      final preferences = _Preferences(prefs)..pending = Completer<void>();
      await mount(
        tester,
        screen: const Scaffold(
          body: DailyGoalBottomSheet(language: 'en', accentColor: Colors.amber),
        ),
        preferences: preferences,
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNull,
      );
      preferences.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Could not save the goal. Please retry.'),
        findsOneWidget,
      );
      preferences
        ..pending = null
        ..fail = false;
      await tap(tester, 'Save');
      expect(preferences.saves, 2);
      expect(prefs.getInt('daily_goal_7'), 20);
      expect(tester.takeException(), isNull);
    },
  );
}
