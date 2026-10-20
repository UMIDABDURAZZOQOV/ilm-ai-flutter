import 'support/offline_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/product_mode.dart';
import 'package:ilm_ai_flutter/core/router/app_router.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_home_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_lesson_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_practice_screen.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/study_exit_guard.dart';
import 'package:ilm_ai_flutter/core/services/sound_service.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/settings_screen.dart';
import 'package:ilm_ai_flutter/core/widgets/celebration_confetti.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_path_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/daily_goal_bottom_sheet.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/streak_calendar_widget.dart';
import 'package:ilm_ai_flutter/core/widgets/mascot_image.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_ui.dart';

final subject = SkillSubject(
  id: 1,
  slug: 'math',
  nameUz: 'Matematika',
  nameRu: 'Математика',
  nameEn: 'Mathematics',
);
final lesson = SkillTreeLesson(
  id: 1,
  slug: 'addition',
  titleUz: 'Addition',
  titleRu: 'Addition',
  titleEn: 'Addition',
  orderIndex: 0,
  xpReward: 10,
  status: LessonStatus.unlocked,
  stars: 0,
);

class FakeRepository extends SkillTreeRepository {
  FakeRepository({
    this.empty = false,
    this.units = const [],
    this.customQuestions,
  }) : super(Dio());
  final bool empty;
  final List<SkillTreeUnit> units;
  final List<SkillQuestion>? customQuestions;
  List<LessonResultItem>? saved;
  @override
  Future<LessonCompleteResult> completeLesson({
    required int lessonId,
    required int userId,
    required int attemptId,
    required List<LessonResultItem> results,
  }) async {
    saved = List.of(results);
    return LessonCompleteResult(
      stars: 0,
      score: 0,
      total: results.length,
      xpAwarded: 0,
      xpTotal: 0,
      streakDays: 0,
      newlyUnlockedLessonIds: [],
    );
  }

  @override
  Future<List<SkillSubject>> getSubjects() async => [subject];
  @override
  Future<SkillTreeResponse> getTree({
    required int userId,
    required String subjectSlug,
  }) async => SkillTreeResponse(
    subject: subject,
    units: units,
    user: GamificationSummary(xpTotal: 0, streakDays: 0, todayXp: 10, dailyGoalXp: 50),
  );
  @override
  Future<LessonStartResult> startLesson({
    required int lessonId,
    required int userId,
    String language = 'uz',
  }) async => LessonStartResult(
    attemptId: 1,
    theory: [],
    questions: empty
        ? []
        : customQuestions ??
            [
              SkillQuestion(
                id: 1,
                questionText: '2 + 2 = ?',
                options: ['3', '4'],
                correctAnswer: '4',
                orderIndex: 0,
              ),
            ],
  );
}

class FakeAuth extends AuthController {
  @override
  Future<StoredTokens?> build() async =>
      StoredTokens(accessToken: 'test', refreshToken: 'test', userId: 7);
}

/// Forces UI language in widget tests (prefs alone can race LanguageNotifier).
class _FixedLanguageNotifier extends LanguageNotifier {
  _FixedLanguageNotifier(this._lang);
  final String _lang;
  @override
  String build() => _lang;
}

class FakeExtras extends SkillExtrasRepository {
  FakeExtras({
    this.placementError404 = false,
    this.failPlacementSaveOnce = false,
  }) : super(Dio(), 'en');
  int? savedUnit;
  int saveCount = 0;
  int placementSaveCount = 0;
  String? savedSubject;
  final bool placementError404;
  final bool failPlacementSaveOnce;

  @override
  Future<List<PracticeQuestion>> getPlacement(int userId, String subject) async {
    if (placementError404) {
      throw DioException(
        requestOptions: RequestOptions(path: '/skills/level-test'),
        response: Response(
          requestOptions: RequestOptions(path: '/skills/level-test'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return getUnitExam(userId, 0);
  }

  @override
  Future<Map<String, dynamic>> completePlacement(
    int userId,
    String subject,
    List<Map<String, dynamic>> results, {String? attemptId}
  ) async {
    savedSubject = subject;
    placementSaveCount++;
    if (failPlacementSaveOnce && placementSaveCount == 1) {
      throw StateError('Temporary save network failure');
    }
    return {
      'label': '2-daraja',
      'breakdown': [
        {'label': '1-daraja', 'correct': 1, 'asked': 1, 'mastered': true},
        {'label': '2-daraja', 'correct': 0, 'asked': 1, 'mastered': false},
      ],
    };
  }

  @override
  Future<List<PracticeQuestion>> getUnitExam(int userId, int unitId) async => [
    PracticeQuestion(
      id: 1,
      questionText: '2 + 2 = ?',
      options: ['3', '4'],
      correctAnswer: '4',
    ),
  ];
  @override
  Future<Map<String, dynamic>> completeUnitExam(
    int userId,
    int unitId,
    List<Map<String, dynamic>> results, {String? attemptId}
  ) async {
    savedUnit = unitId;
    saveCount++;
    if (saveCount == 1) throw StateError('Temporary network error');
    return {'passed': true, 'xp_awarded': 50};
  }
}

void main() {
  testWidgets('Android back keeps the lesson until exit is confirmed', (
    tester,
  ) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        home: const Scaffold(body: Text('Home')),
      ),
    );
    key.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const StudyExitGuard(
          active: true,
          saving: false,
          language: 'en',
          child: Scaffold(body: Text('Lesson')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Leave this lesson?'), findsOneWidget);
    await tester.tap(find.text('Keep learning'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
  testWidgets(
    'legacy deep links and incomplete lesson links return to learning',
    (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await PrefsService.create();
      final container = ProviderContainer(
        overrides: [
        learningPreferencesProvider.overrideWith((ref) => OfflinePreferences(ref.read(prefsServiceProvider))),
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(FakeAuth.new),
          skillTreeRepositoryProvider.overrideWithValue(FakeRepository()),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
        ],
      );
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: buildAppTheme(lightColors),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      for (final path in [
        '/sat',
        '/ielts',
        '/profile/college',
        '/assistant',
        '/skills/lesson',
        '/skills/practice',
      ]) {
        router.go(path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          router.routeInformationProvider.value.uri.path,
          '/learn',
          reason: path,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      container.dispose();
    },
  );
  test('subject mode hides every unrelated destination and keeps learning', () {
    expect(subjectsOnly, isTrue);
    for (final path in [
      '/home',
      '/sat',
      '/ielts',
      '/studio',
      '/chat',
      '/assistant',
      '/files',
      '/quiz',
      '/profile',
      '/live-voice',
      '/skills/classes',
      '/skills/parent',
      '/skills/referral',
    ]) {
      expect(isSubjectRoute(path), isFalse, reason: path);
    }
    for (final path in [
      '/learn',
      '/setup',
      '/settings',
      '/skills/lesson',
      '/skills/practice',
    ]) {
      expect(isSubjectRoute(path), isTrue, reason: path);
    }
  });

  Future<PrefsService> mount(
    WidgetTester tester,
    Widget child, {
    bool empty = false,
    FakeRepository? repository,
    FakeExtras? extras,
    FakeSoundService? soundService,
    Map<String, Object> saved = const {},
    String? language,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final initial = Map<String, Object>.from(saved);
    if (language != null) {
      initial[PrefsKeys.language] = language;
    }
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await PrefsService.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
        learningPreferencesProvider.overrideWith((ref) => OfflinePreferences(ref.read(prefsServiceProvider))),
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(7),
          if (language != null)
            languageProvider.overrideWith(
              () => _FixedLanguageNotifier(language),
            ),
          soundServiceProvider.overrideWithValue(
            soundService ?? FakeSoundService(),
          ),
          if (extras != null)
            skillExtrasRepositoryProvider.overrideWithValue(extras),
          skillTreeRepositoryProvider.overrideWithValue(
            repository ?? FakeRepository(empty: empty),
          ),
        ],
        child: MaterialApp(theme: buildAppTheme(lightColors), home: child),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    return prefs;
  }

  testWidgets(
    'first visit selects and persists a subject, with only learning tabs',
    (tester) async {
      final prefs = await mount(tester, const SubjectHomeScreen());
      expect(find.text('What will you learn?'), findsOneWidget);
      await tester.tap(find.text('Mathematics'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(prefs.getString('subject_7'), 'math');
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('DAILY GOAL'), findsOneWidget);
      expect(find.text('SAT'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('returning learner opens their path directly', (tester) async {
    await mount(
      tester,
      const SubjectHomeScreen(),
      saved: {'subject_7': 'math'},
    );
    expect(find.text('What will you learn?'), findsNothing);
    expect(find.text('DAILY GOAL'), findsOneWidget);
  });

  testWidgets('another account does not inherit the previous subject', (
    tester,
  ) async {
    await mount(
      tester,
      const SubjectHomeScreen(),
      saved: {'subject_8': 'math'},
    );
    expect(find.text('What will you learn?'), findsOneWidget);
  });

  testWidgets('selecting an answer requires Check before feedback', (
    tester,
  ) async {
    await mount(tester, SkillLessonScreen(lesson: lesson));
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('CHECK'), findsOneWidget);
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('CHECK'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('CHECK'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an empty lesson shows an error instead of indexing an empty list',
    (tester) async {
      await mount(tester, SkillLessonScreen(lesson: lesson), empty: true);
      expect(find.text('CHECK'), findsNothing);
      expect(find.byType(SkillLessonScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mistakes must be corrected without rewriting the original score',
    (tester) async {
      final repository = FakeRepository();
      await mount(
        tester,
        SkillLessonScreen(lesson: lesson),
        repository: repository,
      );
      Future<void> tap(String label) async {
        await tester.tap(find.text(label).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }

      await tap('3');
      await tap('CHECK');
      await tap('Continue');
      expect(find.text('REVIEW YOUR MISTAKES'), findsOneWidget);
      expect(repository.saved, isNull);
      await tap('3');
      await tap('CHECK');
      await tap('Continue');
      expect(repository.saved, isNull);
      await tap('4');
      await tap('CHECK');
      await tap('Continue');
      expect(repository.saved, hasLength(1));
      expect(repository.saved!.single.isCorrect, isFalse);
      expect(find.text('First-attempt accuracy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('checkpoint waits for saving and can retry a failed request', (
    tester,
  ) async {
    final extras = FakeExtras();
    await mount(
      tester,
      const SkillPracticeScreen(mode: PracticeMode.checkpoint, unitId: 42),
      extras: extras,
    );
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('CHECK'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Next unit unlocked!'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(extras.savedUnit, 42);
    expect(extras.saveCount, 2);
    expect(find.text('Next unit unlocked!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'placement submits the selected subject and shows level breakdown',
    (tester) async {
      final extras = FakeExtras();
      await mount(
        tester,
        const SkillPracticeScreen(
          mode: PracticeMode.placement,
          subjectSlug: 'math',
        ),
        extras: extras,
      );
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('CHECK'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(extras.savedSubject, 'math');
      expect(find.text('Estimated level: 2-daraja'), findsOneWidget);
      expect(find.text('1-daraja'), findsOneWidget);
      expect(find.text('2-daraja'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'answering triggers mock sound service for correct, incorrect, and lesson completion',
    (tester) async {
      final fakeSound = FakeSoundService();
      final repository = FakeRepository();
      await mount(
        tester,
        SkillLessonScreen(lesson: lesson),
        repository: repository,
        soundService: fakeSound,
      );

      Future<void> tap(String label) async {
        await tester.tap(find.text(label).first, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }

      // 1. Wrong answer -> playIncorrect
      await tap('3');
      await tap('CHECK');
      expect(fakeSound.playIncorrectCount, 1);
      expect(fakeSound.playCorrectCount, 0);

      // Move forward to review mistakes
      await tap('Continue');

      // 2. Correct answer in review -> playCorrect
      await tap('4');
      await tap('CHECK');
      expect(fakeSound.playCorrectCount, 1);

      // 3. Complete lesson -> playLessonComplete
      await tap('Continue');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeSound.playLessonCompleteCount, 1);
      expect(find.byType(CelebrationConfetti), findsOneWidget);
      expect(find.text('First-attempt accuracy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings screen toggles sound effects and persists state', (
    tester,
  ) async {
    final prefs = await mount(tester, const SettingsScreen());
    expect(find.text('Sound effects'), findsOneWidget);
    expect(prefs.getBool(PrefsKeys.soundEffects, defaultValue: true), isTrue);

    // Tap switch to turn off
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(prefs.getBool(PrefsKeys.soundEffects, defaultValue: true), isFalse);

    // Tap switch to turn back on
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(prefs.getBool(PrefsKeys.soundEffects, defaultValue: true), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'popover displays correctly for unlocked, completed, and locked states without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final unlockedLesson = SkillTreeLesson(
        id: 1,
        slug: 'lesson-1',
        titleUz: 'Dars 1: Qo‘shish',
        titleRu: 'Урок 1: Сложение',
        titleEn: 'Lesson 1: Addition',
        orderIndex: 0,
        xpReward: 15,
        status: LessonStatus.unlocked,
        stars: 0,
      );

      final completedLesson = SkillTreeLesson(
        id: 2,
        slug: 'lesson-2',
        titleUz: 'Dars 2: Ayirish',
        titleRu: 'Урок 2: Вычитание',
        titleEn: 'Lesson 2: Subtraction',
        orderIndex: 1,
        xpReward: 20,
        status: LessonStatus.completed,
        stars: 3,
      );

      final lockedLesson = SkillTreeLesson(
        id: 3,
        slug: 'lesson-3',
        titleUz: 'Dars 3: Ko‘paytirish',
        titleRu: 'Урок 3: Умножение',
        titleEn: 'Lesson 3: Multiplication',
        orderIndex: 2,
        xpReward: 25,
        status: LessonStatus.locked,
        stars: 0,
      );

      // 1. Test UNLOCKED state
      bool unlockedStarted = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(
            body: LessonPopoverContent(
              lesson: unlockedLesson,
              unitTitle: '1-Bo‘lim: Arifmetika',
              language: 'uz',
              color: const Color(0xFF58CC02),
              onStart: () => unlockedStarted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dars 1: Qo‘shish'), findsOneWidget);
      expect(find.text('+15 XP'), findsOneWidget);
      expect(find.text('BOSHLASH'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('BOSHLASH'));
      await tester.pump();
      expect(unlockedStarted, isTrue);

      // 2. Test COMPLETED state
      bool completedStarted = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(
            body: LessonPopoverContent(
              lesson: completedLesson,
              unitTitle: '1-Bo‘lim: Arifmetika',
              language: 'uz',
              color: const Color(0xFF58CC02),
              onStart: () => completedStarted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dars 2: Ayirish'), findsOneWidget);
      expect(find.text('+20 XP'), findsOneWidget);
      expect(find.text('QAYTA O‘TISH'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('QAYTA O‘TISH'));
      await tester.pump();
      expect(completedStarted, isTrue);

      // 3. Test LOCKED state
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(
            body: LessonPopoverContent(
              lesson: lockedLesson,
              unitTitle: '1-Bo‘lim: Arifmetika',
              language: 'uz',
              color: const Color(0xFF58CC02),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dars 3: Ko‘paytirish'), findsOneWidget);
      expect(find.text('Oldingi darslar va bo‘lim sinovini tugating.'), findsOneWidget);
      expect(find.text('QULFLANGAN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'skill path displays floating start indicator on active node and opens lesson popover',
    (tester) async {
      final unitWithLessons = SkillTreeUnit(
        id: 10,
        slug: 'arithmetic',
        titleUz: 'Arifmetika',
        titleRu: 'Арифметика',
        titleEn: 'Arithmetic',
        orderIndex: 0,
        examStatus: 'unlocked',
        lessons: [
          SkillTreeLesson(
            id: 101,
            slug: 'l1',
            titleUz: 'Qo‘shish',
            titleRu: 'Сложение',
            titleEn: 'Addition',
            orderIndex: 0,
            xpReward: 10,
            status: LessonStatus.unlocked,
            stars: 0,
          ),
        ],
      );

      final treeRepo = FakeRepository(units: [unitWithLessons]);
      await mount(
        tester,
        SkillPathScreen(subject: subject),
        repository: treeRepo,
      );

      // Floating indicator shows Start in English (or BOSHLASH in Uzbek)
      expect(find.text('START'), findsWidgets);
      expect(find.text('DAILY GOAL'), findsOneWidget);

      // Tap the node to open the popover
      await tester.tap(find.byIcon(Icons.star_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LessonPopoverContent), findsOneWidget);
      expect(find.text('Addition'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'popover displays specific lock reasons and hides XP when xpReward is zero or absent',
    (tester) async {
      final lockedLessonPrev = SkillTreeLesson(
        id: 201,
        slug: 'l201',
        titleUz: 'Tenglamalar',
        titleRu: 'Уравнения',
        titleEn: 'Equations',
        orderIndex: 1,
        xpReward: 10,
        status: LessonStatus.locked,
        stars: 0,
      );
      final lockedLessonCheckpoint = SkillTreeLesson(
        id: 202,
        slug: 'l202',
        titleUz: 'Funksiyalar',
        titleRu: 'Функции',
        titleEn: 'Functions',
        orderIndex: 0,
        xpReward: 0,
        status: LessonStatus.locked,
        stars: 0,
      );

      // 1. Test previous lesson incomplete reason
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(
            body: LessonPopoverContent(
              lesson: lockedLessonPrev,
              unitTitle: '1-Bo‘lim',
              language: 'uz',
              color: const Color(0xFF58CC02),
              lockReason: LessonLockReason.previousLessonIncomplete,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Oldingi dars tugallanmagan.'), findsOneWidget);
      expect(find.text('+10 XP'), findsOneWidget);

      // 2. Test checkpoint required reason and zero XP omission
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(
            body: LessonPopoverContent(
              lesson: lockedLessonCheckpoint,
              unitTitle: '2-Bo‘lim',
              language: 'uz',
              color: const Color(0xFF58CC02),
              lockReason: LessonLockReason.checkpointRequired,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bo‘lim sinovidan o‘tish kerak.'), findsOneWidget);
      // xpReward == 0 -> XP chip must be omitted ("Raqam to'qima")
      expect(find.textContaining('XP'), findsNothing);

      // 3. Verify resolveLessonLockReason logic on tree
      final multiUnitTree = SkillTreeResponse(
        subject: subject,
        units: [
          SkillTreeUnit(
            id: 1,
            slug: 'u1',
            titleUz: 'Bo‘lim 1',
            titleRu: 'Раздел 1',
            titleEn: 'Unit 1',
            orderIndex: 0,
            examStatus: 'unlocked', // checkpoint not passed!
            lessons: [
              SkillTreeLesson(
                id: 11,
                slug: 'l11',
                titleUz: 'Dars 1',
                titleRu: 'Урок 1',
                titleEn: 'Lesson 1',
                orderIndex: 0,
                xpReward: 10,
                status: LessonStatus.completed,
                stars: 3,
              ),
              SkillTreeLesson(
                id: 12,
                slug: 'l12',
                titleUz: 'Dars 2',
                titleRu: 'Урок 2',
                titleEn: 'Lesson 2',
                orderIndex: 1,
                xpReward: 10,
                status: LessonStatus.locked,
                stars: 0,
              ),
            ],
          ),
          SkillTreeUnit(
            id: 2,
            slug: 'u2',
            titleUz: 'Bo‘lim 2',
            titleRu: 'Раздел 2',
            titleEn: 'Unit 2',
            orderIndex: 1,
            examStatus: 'locked',
            lessons: [
              SkillTreeLesson(
                id: 21,
                slug: 'l21',
                titleUz: 'Dars 3',
                titleRu: 'Урок 3',
                titleEn: 'Lesson 3',
                orderIndex: 0,
                xpReward: 10,
                status: LessonStatus.locked,
                stars: 0,
              ),
            ],
          ),
        ],
        user: GamificationSummary(xpTotal: 0, streakDays: 0),
      );

      final lessonInSameUnit = multiUnitTree.units[0].lessons[1];
      final lessonInNextUnit = multiUnitTree.units[1].lessons[0];

      expect(
        resolveLessonLockReason(tree: multiUnitTree, lesson: lessonInSameUnit),
        LessonLockReason.previousLessonIncomplete,
      );
      expect(
        resolveLessonLockReason(tree: multiUnitTree, lesson: lessonInNextUnit),
        LessonLockReason.checkpointRequired,
      );

      // 4. Verify SkillTreeLesson.fromJson does not invent default 10 XP
      final parsedWithoutXp = SkillTreeLesson.fromJson({
        'id': 99,
        'slug': 'no_xp',
        'title_uz': 'No XP',
        'title_ru': 'No XP',
        'title_en': 'No XP',
        'order_index': 0,
        'status': 'unlocked',
        'stars': 0,
      });
      expect(parsedWithoutXp.xpReward, 0);
    },
  );

  testWidgets(
    'daily goal selection persists per-user in SharedPreferences and isolates by userId',
    (tester) async {
      SharedPreferences.setMockInitialValues({'daily_goal_7': 20});
      final prefs = await PrefsService.create();
      final container = ProviderContainer(
        overrides: [
        learningPreferencesProvider.overrideWith((ref) => OfflinePreferences(ref.read(prefsServiceProvider))),
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(7),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(userDailyGoalProvider), 20);

      // Save a new goal (30 XP) for user 7
      await container.read(prefsServiceProvider).setInt('daily_goal_7', 30);
      container.read(userDailyGoalProvider.notifier).state = 30;
      expect(prefs.getInt('daily_goal_7'), 30);
      expect(container.read(userDailyGoalProvider), 30);

      // User 8 has no saved goal, defaults to 20
      final containerUser8 = ProviderContainer(
        overrides: [
        learningPreferencesProvider.overrideWith((ref) => OfflinePreferences(ref.read(prefsServiceProvider))),
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(8),
        ],
      );
      addTearDown(containerUser8.dispose);
      expect(prefs.getInt('daily_goal_8'), isNull);
      expect(containerUser8.read(userDailyGoalProvider), 20);
    },
  );

  testWidgets(
    'skill path displays daily goal and opens bottom sheet to select and save new goal',
    (tester) async {
      final prefs = await mount(
        tester,
        SkillPathScreen(subject: subject),
        saved: {'language': 'en'},
      );

      // Initially shows 10/20 XP
      expect(find.text('10/20 XP'), findsOneWidget);
      expect(find.text('DAILY GOAL'), findsOneWidget);

      // Tap the daily goal card to open bottom sheet
      await tester.tap(find.text('DAILY GOAL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Check options are displayed
      expect(find.text('Daily Goal'), findsOneWidget);
      expect(find.text('30 XP'), findsOneWidget);
      expect(find.text('Serious'), findsOneWidget);

      // Select 30 XP
      await tester.tap(find.text('30 XP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify persisted in SharedPreferences for user 7
      expect(prefs.getInt('daily_goal_7'), 30);

      // Verify UI updated to 10/30 XP
      expect(find.text('10/30 XP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'streak calendar marks active days with flame indicators and counter badge at 390x844',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StreakCalendarWidget(
                targetMonth: DateTime(2026, 10, 1),
                streakDays: 5,
                language: 'en',
                activity: const {
                  '2026-10-01': 20,
                  '2026-10-02': 15,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Streak Calendar'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'streak calendar handles null and empty activity gracefully without crashing',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Null activity in uzbek
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(darkColors),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: StreakCalendarWidget(
                activity: null,
                streakDays: 0,
                language: 'uz',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Faollik ma‘lumotlari'), findsOneWidget);
      expect(find.text('0 kun'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Empty activity map in russian
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(lightColors),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: StreakCalendarWidget(
                activity: {},
                streakDays: 0,
                language: 'ru',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Данных об активности'), findsOneWidget);
      expect(find.text('0 дн'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'placement test handles 404 with preparation message and back button without crashing',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final extras = FakeExtras(placementError404: true);
      await mount(
        tester,
        const SkillPracticeScreen(
          mode: PracticeMode.placement,
          subjectSlug: 'math',
        ),
        extras: extras,
        saved: {'language': 'en'},
      );

      expect(find.text('Still in preparation'), findsOneWidget);
      expect(
        find.text('Placement test for this subject is still in preparation.'),
        findsOneWidget,
      );
      expect(find.text('Back'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'placement test handles save failure with retry and only shows results after save succeeds',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final extras = FakeExtras(failPlacementSaveOnce: true);
      await mount(
        tester,
        const SkillPracticeScreen(
          mode: PracticeMode.placement,
          subjectSlug: 'math',
        ),
        extras: extras,
        saved: {'language': 'en'},
      );

      // 1. Select answer
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // 2. CHECK -> Continue
      await tester.tap(find.text('CHECK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Save failed: Results are not shown yet; Retry is available
      expect(find.text('Estimated level: 2-daraja'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      expect(extras.placementSaveCount, 1);

      // 3. Tap Retry -> save succeeds -> results appear
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));

      expect(extras.placementSaveCount, 2);
      expect(find.text('Estimated level: 2-daraja'), findsOneWidget);
      expect(find.text('1-daraja'), findsOneWidget);
      expect(find.text('2-daraja'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'placement test full flow with CHECK -> Continue and level breakdown at 390x844 without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final extras = FakeExtras();
      await mount(
        tester,
        const SkillPracticeScreen(
          mode: PracticeMode.placement,
          subjectSlug: 'math',
        ),
        extras: extras,
        saved: {'language': 'en'},
      );

      // Select option
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Tap CHECK
      await tester.tap(find.text('CHECK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));

      // Server level and breakdown displayed
      expect(extras.savedSubject, 'math');
      expect(find.text('Estimated level: 2-daraja'), findsOneWidget);
      expect(find.text('1-daraja'), findsOneWidget);
      expect(find.text('2-daraja'), findsOneWidget);
      expect(find.text('1/1'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'MascotImage renders all 5 poses correctly with expected assets',
    (tester) async {
      for (final pose in MascotPose.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MascotImage(pose: pose, size: 80, animate: false),
            ),
          ),
        );
        expect(find.byType(MascotImage), findsOneWidget);
        final img = tester.widget<Image>(find.byType(Image));
        final asset = img.image as AssetImage;
        expect(asset.assetName, pose.assetPath);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'skill path displays hello pose mascot above nodes',
    (tester) async {
      await mount(
        tester,
        SkillPathScreen(subject: subject),
        saved: {'language': 'uz'},
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is MascotImage && w.pose == MascotPose.hello,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'three wrong answers reappear at the end until corrected',
    (tester) async {
      final repository = FakeRepository(
        customQuestions: [
          for (var i = 1; i <= 3; i++)
            SkillQuestion(
              id: i,
              questionText: 'Q$i?',
              options: ['wrong$i', 'right$i'],
              correctAnswer: 'right$i',
              orderIndex: i - 1,
            ),
        ],
      );
      await mount(
        tester,
        SkillLessonScreen(lesson: lesson),
        repository: repository,
        saved: {PrefsKeys.language: 'en'},
      );

      Future<void> tap(String label) async {
        await tester.tap(find.text(label).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }

      // Miss all three first-pass questions.
      for (var i = 1; i <= 3; i++) {
        expect(find.text('Q$i?'), findsOneWidget);
        await tap('wrong$i');
        await tap('CHECK');
        expect(
          find.text('This question will appear again at the end'),
          findsOneWidget,
        );
        await tap('Continue');
      }

      // Review queue: three mistakes again.
      expect(find.text('REVIEW YOUR MISTAKES'), findsOneWidget);
      expect(repository.saved, isNull);
      for (var i = 1; i <= 3; i++) {
        expect(find.text('Q$i?'), findsOneWidget);
        await tap('right$i');
        await tap('CHECK');
        await tap('Continue');
      }

      expect(repository.saved, hasLength(3));
      expect(repository.saved!.every((r) => r.isCorrect == false), isTrue);
      expect(find.text('First-attempt accuracy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final case_ in [
    ('uz', 'TEKSHIRISH', 'Bu savol oxirida yana chiqadi'),
    ('ru', 'ПРОВЕРИТЬ', 'Этот вопрос появится снова в конце'),
    ('en', 'CHECK', 'This question will appear again at the end'),
  ]) {
    final lang = case_.$1;
    final check = case_.$2;
    final tip = case_.$3;
    testWidgets(
      'incorrect feedback tip is localized ($lang)',
      (tester) async {
        await mount(
          tester,
          SkillLessonScreen(lesson: lesson),
          language: lang,
        );
        expect(find.text(check), findsOneWidget);
        await tester.tap(find.text('3'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text(check));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(tip), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('looksLikeUntranslatedUzbek detects Cyrillic-less Russian UI content', () {
    expect(
      looksLikeUntranslatedUzbek(
        'Kvadrat tenglama ildizlarini toping',
        'ru',
      ),
      isTrue,
    );
    expect(
      looksLikeUntranslatedUzbek(
        'Найдите корни квадратного уравнения',
        'ru',
      ),
      isFalse,
    );
    expect(
      looksLikeUntranslatedUzbek('Anything', 'uz'),
      isFalse,
    );
  });
}

