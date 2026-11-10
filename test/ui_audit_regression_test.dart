// UI-003..012: isolated presentation regressions, no live user/provider requests.
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/core/widgets/ilm_bottom_navigation.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/learning/presentation/assessment_practice_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/curriculum_learning_screen.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_achievements_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_path_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_feedback_panel.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_switch_sheet.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_grade_card.dart';
import 'support/capture_release_frame.dart';
import 'support/load_review_fonts.dart';

class _Achievements extends SkillExtrasRepository {
  _Achievements({this.empty = false, this.failures = 0, this.pending = false})
    : super(Dio(), 'uz');
  final bool empty, pending;
  int failures, calls = 0;
  @override
  Future<List<Achievement>> getAchievements(int userId) {
    calls++;
    if (pending) return Completer<List<Achievement>>().future;
    if (failures-- > 0) return Future.error(StateError('synthetic offline'));
    return Future.value(
      empty
          ? []
          : [
              for (final group in [
                'streak',
                'lessons',
                'perfect',
                'questions',
                'xp',
              ])
                Achievement(
                  id: group,
                  group: group,
                  target: 1000,
                  progress: 500,
                  earned: group == 'xp',
                ),
            ],
    );
  }
}

final _physics = SkillSubject(
  id: 2,
  slug: 'fizika',
  nameUz: 'Fizika',
  nameRu: 'Физика',
  nameEn: 'Physics',
  grades: const [6, 7, 8, 9, 10, 11],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('UIUX_CAPTURE')) await loadReviewFonts();
  });
  Future<GlobalKey> mount(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(320, 568),
    double scale = 2,
    bool dark = false,
    String lang = 'uz',
    _Achievements? achievements,
    SkillTreeResponse? practice,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({PrefsKeys.language: lang});
    final prefs = await PrefsService.create();
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(7),
          if (achievements != null)
            skillExtrasRepositoryProvider.overrideWithValue(achievements),
          if (practice != null) ...[
            selectedCurriculumGradeProvider(
              _physics.slug,
            ).overrideWith((_) => 6),
            assessmentPracticeProvider((
              _physics.slug,
              6,
            )).overrideWith((_) async => practice),
          ],
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(dark ? darkColors : lightColors),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: child,
          ),
        ),
      ),
    );
    await tester.pump();
    return key;
  }

  for (final lang in ['uz', 'ru', 'en']) {
    testWidgets('UI009 practice cards have independent spacing $lang', (
      tester,
    ) async {
      final tree = SkillTreeResponse(
        subject: _physics,
        user: GamificationSummary(xpTotal: 20, streakDays: 1),
        units: [
          SkillTreeUnit(
            id: 1,
            slug: 'review',
            titleUz: 'Review',
            titleRu: 'Review',
            titleEn: 'Review',
            orderIndex: 0,
            lessons: [
              for (var id = 1; id <= 2; id++)
                SkillTreeLesson(
                  id: id,
                  slug: 'review-$id',
                  titleUz: 'Lesson $id',
                  titleRu: 'Lesson $id',
                  titleEn: 'Lesson $id',
                  orderIndex: id,
                  xpReward: 10,
                  status: LessonStatus.completed,
                  stars: 3,
                ),
            ],
          ),
        ],
      );
      final key = await mount(
        tester,
        AssessmentPracticeScreen(subject: _physics, onOpenLearning: () {}),
        practice: tree,
        lang: lang,
        scale: 1,
        size: const Size(360, 800),
      );
      await tester.pumpAndSettle();
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(2));
      final first = tester.getRect(find.byType(ListTile).first);
      final second = tester.getRect(find.byType(ListTile).last);
      expect(second.top - first.bottom, greaterThanOrEqualTo(12));
      expect(tester.takeException(), isNull);
      await captureReleaseFrame(tester, key, 'practice-spacing-$lang');
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('UI003 normal achievements remain readable $lang', (
      tester,
    ) async {
      final key = await mount(
        tester,
        const SkillAchievementsScreen(),
        lang: lang,
        scale: 1,
        size: const Size(360, 800),
        achievements: _Achievements(),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('achievement_streak')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await captureReleaseFrame(tester, key, 'achievements-normal-$lang');
      await tester.pumpWidget(const SizedBox.shrink());
    });
    for (final dark in [false, true]) {
      for (final size in [const Size(320, 568), const Size(640, 240)]) {
        testWidgets(
          'UI003/008 achievements grow with 200% text $lang/$dark/$size',
          (tester) async {
            final key = await mount(
              tester,
              const SkillAchievementsScreen(),
              lang: lang,
              dark: dark,
              size: size,
              achievements: _Achievements(),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (final group in [
              'streak',
              'lessons',
              'perfect',
              'questions',
              'xp',
            ]) {
              final badge = find.byKey(ValueKey('achievement_$group'));
              await tester.ensureVisible(badge);
              await tester.pumpAndSettle();
              expect(badge.hitTestable(), findsOneWidget);
              expect(tester.takeException(), isNull);
            }
            await captureReleaseFrame(
              tester,
              key,
              'achievements-$lang-$dark-${size.width}',
            );
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
    testWidgets('UI006 achievements retry recovers $lang', (tester) async {
      final repo = _Achievements(failures: 1);
      final key = await mount(
        tester,
        const SkillAchievementsScreen(),
        lang: lang,
        achievements: repo,
      );
      await tester.pumpAndSettle();
      final retry = find.byType(FilledButton);
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      expect(retry.hitTestable(), findsOneWidget);
      await captureReleaseFrame(tester, key, 'achievement-retry-$lang');
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      expect(find.byKey(const ValueKey('achievement_streak')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('UI011 achievements explain empty state $lang', (tester) async {
      final key = await mount(
        tester,
        const SkillAchievementsScreen(),
        lang: lang,
        achievements: _Achievements(empty: true),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('0/0'), findsNothing);
      final title = lang == 'uz'
          ? 'Hozircha yutuqlar yo‘q'
          : lang == 'ru'
          ? 'Достижений пока нет'
          : 'No achievements yet';
      await tester.ensureVisible(find.text(title));
      expect(find.text(title).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureReleaseFrame(tester, key, 'achievement-empty-$lang');
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('UI005 locked feedback is visible above the switcher $lang', (
      tester,
    ) async {
      final key = await mount(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSubjectSwitcher(
                context,
                subjects: [_physics],
                language: lang,
                grade: 5,
                currentSubject: null,
              ),
              child: const Text('Fanlar'),
            ),
          ),
        ),
        lang: lang,
      );
      await tester.tap(find.text('Fanlar'));
      await tester.pumpAndSettle();
      final card = find.byType(SubjectGradeCard);
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final message = find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(SubjectGradeAvailability(_physics, 5).label(lang)),
      );
      expect(message.hitTestable(), findsOneWidget);
      expect(
        find.byType(SubjectGradeCard),
        findsOneWidget,
      ); // Still locked, no selection.
      expect(tester.takeException(), isNull);
      await captureReleaseFrame(tester, key, 'locked-message-$lang');
      await tester.pumpWidget(const SizedBox.shrink());
    });
    for (final correct in [false, true]) {
      testWidgets(
        'UI004 short feedback keeps help, explanation and continue reachable $lang/$correct',
        (tester) async {
          var helps = 0, next = 0;
          final key = await mount(
            tester,
            Scaffold(
              body: Column(
                children: [
                  const Expanded(
                    child: SingleChildScrollView(child: Text('Question')),
                  ),
                  LessonFeedbackPanel(
                    language: lang,
                    correct: correct,
                    correctAnswer: 'Reviewed answer',
                    explanation: 'Reviewed explanation',
                    help: TextButton(
                      onPressed: () => helps++,
                      child: const Text('AI explanation'),
                    ),
                    onContinue: () => next++,
                  ),
                ],
              ),
            ),
            size: const Size(640, 240),
            lang: lang,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Reviewed explanation'));
          await tester.pumpAndSettle();
          expect(
            find.text('Reviewed explanation').hitTestable(),
            findsOneWidget,
          );
          await tester.ensureVisible(find.text('AI explanation'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('AI explanation'));
          expect(helps, 1);
          await tester.ensureVisible(find.byType(Duo3DButton));
          await tester.pumpAndSettle();
          expect(find.byType(Duo3DButton).hitTestable(), findsOneWidget);
          await captureReleaseFrame(tester, key, 'feedback-$lang-$correct');
          await tester.tap(find.byType(Duo3DButton));
          expect(next, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
    testWidgets('UI010 large navigation keeps all whole labels visible $lang', (
      tester,
    ) async {
      final labels = lang == 'uz'
          ? ['O‘rganish', 'Mashq', 'Vazifalar', 'Liga', 'Profil']
          : lang == 'ru'
          ? ['Учиться', 'Практика', 'Задания', 'Лига', 'Профиль']
          : ['Learn', 'Practice', 'Quests', 'League', 'Profile'];
      var selected = -1;
      final key = await mount(
        tester,
        Scaffold(
          bottomNavigationBar: IlmBottomNavigation(
            index: 0,
            onChanged: (i) => selected = i,
            items: [
              for (final label in labels)
                IlmNavigationDestination(
                  icon: Icons.circle_outlined,
                  label: label,
                ),
            ],
          ),
        ),
        lang: lang,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(IlmBottomNavigation)).height,
        lessThanOrEqualTo(568 / 2),
        reason: 'Large labels must leave room for the learning page.',
      );
      for (var i = 0; i < labels.length; i++) {
        final text = find.text(labels[i]);
        expect(text.hitTestable(), findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.widget<Text>(text).maxLines, 1);
        if (i > 0) {
          await tester.tap(find.byKey(ValueKey('ilm-nav-$i')));
          expect(selected, i);
        }
      }
      expect(tester.takeException(), isNull);
      await captureReleaseFrame(tester, key, 'navigation-$lang');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('UI006 pending achievements reach retry after deadline', (
    tester,
  ) async {
    await mount(
      tester,
      const SkillAchievementsScreen(),
      achievements: _Achievements(pending: true),
    );
    await tester.pump(const Duration(seconds: 19));
    await tester.pumpAndSettle();
    expect(find.text('Yutuqlar yuklanmadi'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final completed in [false, true]) {
    testWidgets('UI012 completed=$completed reward copy follows repeat state', (
      tester,
    ) async {
      final lesson = SkillTreeLesson(
        id: 1,
        slug: 'review',
        titleUz: 'Review lesson',
        titleRu: 'Review lesson',
        titleEn: 'Review lesson',
        orderIndex: 0,
        xpReward: 10,
        status: completed ? LessonStatus.completed : LessonStatus.unlocked,
        stars: completed ? 3 : 0,
      );
      final key = await mount(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: LessonPopoverContent(
              lesson: lesson,
              language: 'uz',
              color: Colors.indigo,
              onStart: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+10 XP'), completed ? findsNothing : findsOneWidget);
      if (completed) expect(find.text('3/3 yulduz'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureReleaseFrame(tester, key, 'lesson-preview-$completed');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
