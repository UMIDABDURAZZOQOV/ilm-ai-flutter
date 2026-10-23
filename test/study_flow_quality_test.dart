import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/skills/application/lesson_entry.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_completion_view.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/learning_journey_widgets.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/study_start_sheet.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_path_screen.dart';
import 'subject_experience_test.dart' as fixture;
import 'support/load_review_fonts.dart';

SkillTreeUnit _unit(String status) => SkillTreeUnit(
  id: 1,
  slug: 'unit',
  titleUz: 'Birinchi bo‘lim',
  titleRu: 'Первый раздел',
  titleEn: 'First unit',
  orderIndex: 0,
  lessons: [],
  examStatus: status,
  coverageComplete: status != 'locked',
);

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double scale = 2,
  Size size = const Size(320, 568),
  GlobalKey? frameKey,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(dark ? darkColors : lightColors),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: frameKey,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadReviewFonts);
  testWidgets('lazy row semantics excludes its section heading and progress', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _mount(
      tester,
      ListView.builder(
        itemCount: 1,
        itemBuilder: (context, index) => Column(
          children: [
            const LearningUnitHeader(
              title: 'Section heading',
              language: 'en',
              completed: 1,
              total: 4,
              coverageComplete: true,
            ),
            LearningJourneyTile(
              title: 'Lesson',
              stateLabel: 'START',
              semanticLabel: 'Lesson. Ready',
              onTap: () {},
              locked: false,
              completed: false,
              current: true,
            ),
          ],
        ),
      ),
      scale: 1,
    );
    final node = tester.getSemantics(find.byType(LearningJourneyTile));
    expect(node.getSemanticsData().label, 'Lesson. Ready');
    expect(
      node.rect.height,
      tester.getSize(find.byType(LearningJourneyTile)).height,
    );
    expect(find.semantics.byLabel('Lesson. Ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
    await _mount(
      tester,
      const LearningUnitHeader(
        title: 'Empty unit',
        language: 'en',
        completed: 0,
        total: 0,
        coverageComplete: false,
      ),
      scale: 1,
    );
    expect(find.textContaining('0/0'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      find.text('More lessons in this unit are in preparation.'),
      findsOneWidget,
    );
  });
  testWidgets('English streak uses singular day on home and completion', (
    tester,
  ) async {
    await _mount(
      tester,
      LessonCompletionView(
        language: 'en',
        title: 'Lesson complete',
        lessonTitle: 'Lesson',
        xp: 20,
        correct: 9,
        total: 12,
        stars: 2,
        streakDays: 1,
        elapsed: const Duration(minutes: 3),
        onReview: () {},
        onBack: () {},
      ),
    );
    expect(find.text('Your streak: 1 day'), findsOneWidget);
    await _mount(
      tester,
      SingleChildScrollView(
        child: LearningContinueCard(
          language: 'en',
          title: 'Lesson',
          todayXp: 10,
          goalXp: 20,
          onGoal: () {},
          summary: GamificationSummary(xpTotal: 10, streakDays: 1),
        ),
      ),
    );
    expect(find.text('Streak: 1 day'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unknown server checkpoint status stays locked', (tester) async {
    var starts = 0;
    await _mount(
      tester,
      CheckpointPopoverContent(
        unit: _unit('unknown'),
        language: 'en',
        onStart: () => starts++,
      ),
    );
    final sheet = tester.widget<StudyStartSheet>(find.byType(StudyStartSheet));
    expect(sheet.locked, true);
    expect(sheet.actionLabel, 'LOCKED');
    await tester.ensureVisible(find.text('LOCKED'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LOCKED'));
    expect(starts, 0);
    expect(tester.takeException(), isNull);
  });
  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      for (final status in ['locked', 'unlocked', 'passed']) {
        testWidgets('checkpoint $lang/$dark/$status 320dp/200%', (
          tester,
        ) async {
          var starts = 0;
          await _mount(
            tester,
            CheckpointPopoverContent(
              unit: _unit(status),
              language: lang,
              onStart: () => starts++,
            ),
            dark: dark,
          );
          final button = find.byType(FilledButton);
          // The shared branded button uses InkWell; its label remains readable.
          final label = lang == 'uz'
              ? (status == 'locked'
                    ? 'QULFLANGAN'
                    : status == 'passed'
                    ? 'SINOVNI TAKRORLASH'
                    : 'SINOVNI BOSHLASH')
              : lang == 'ru'
              ? (status == 'locked'
                    ? 'ЗАБЛОКИРОВАНО'
                    : status == 'passed'
                    ? 'ПОВТОРИТЬ ПРОВЕРКУ'
                    : 'НАЧАТЬ ПРОВЕРКУ')
              : status == 'locked'
              ? 'LOCKED'
              : status == 'passed'
              ? 'REVIEW CHECKPOINT'
              : 'START CHECKPOINT';
          expect(button, findsNothing);
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(starts, status == 'locked' ? 0 : 1);
          expect(tester.takeException(), isNull);
        });
      }
      for (final state in [
        LessonEntryState.start,
        LessonEntryState.resume,
        LessonEntryState.expired,
      ]) {
        testWidgets('lesson sheet $lang/$dark/$state landscape/200%', (
          tester,
        ) async {
          var starts = 0;
          final entry = LessonEntry(state, position: 5, total: 12);
          await _mount(
            tester,
            LessonPopoverContent(
              lesson: fixture.lesson,
              unitTitle: 'Long section / Bo‘lim / Раздел',
              language: lang,
              color: BrandPalette.indigo,
              entry: entry,
              onStart: () => starts++,
            ),
            dark: dark,
            size: const Size(640, 360),
          );
          await tester.ensureVisible(find.text(entry.action(lang)));
          await tester.pumpAndSettle();
          await tester.tap(find.text(entry.action(lang)));
          await tester.pumpAndSettle();
          expect(starts, 1);
          expect(tester.takeException(), isNull);
        });
      }
      for (final size in [const Size(320, 568), const Size(640, 360)]) {
        testWidgets('completion $lang/$dark/$size 200% preserves both actions', (
          tester,
        ) async {
          var reviews = 0, backs = 0;
          await _mount(
            tester,
            LessonCompletionView(
              language: lang,
              title: 'Lesson complete / Dars tugadi / Урок завершён',
              lessonTitle:
                  'A long lesson title / Uzun dars nomi / Длинное название урока',
              xp: 20,
              correct: 9,
              total: 12,
              stars: 2,
              streakDays: 3,
              elapsed: const Duration(minutes: 3, seconds: 17),
              onReview: () => reviews++,
              onBack: () => backs++,
            ),
            dark: dark,
            size: size,
          );
          expect(find.text('+20'), findsOneWidget);
          expect(find.text('9/12'), findsOneWidget);
          expect(find.text('75%'), findsOneWidget);
          expect(find.text('3:17'), findsOneWidget);
          final back = lang == 'uz'
              ? 'Dars yo‘liga qaytish'
              : lang == 'ru'
              ? 'К учебному пути'
              : 'Back to learning path';
          final review = lang == 'uz'
              ? 'Javoblarni ko‘rish'
              : lang == 'ru'
              ? 'Посмотреть ответы'
              : 'Review answers';
          await tester.ensureVisible(find.text(back));
          await tester.pumpAndSettle();
          await tester.tap(find.text(back));
          await tester.ensureVisible(find.text(review));
          await tester.pumpAndSettle();
          await tester.tap(find.text(review));
          await tester.pumpAndSettle();
          expect(backs, 1);
          expect(reviews, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  for (final dark in [false, true]) {
    testWidgets('study flow golden ${dark ? 'dark' : 'light'}', (tester) async {
      final key = GlobalKey();
      await _mount(
        tester,
        LessonCompletionView(
          language: 'ru',
          title: 'Урок завершён!',
          lessonTitle: 'Biologiya – hayot haqidagi fan',
          xp: 20,
          correct: 9,
          total: 12,
          stars: 2,
          streakDays: 3,
          elapsed: const Duration(minutes: 3, seconds: 17),
          onReview: () {},
          onBack: () {},
        ),
        frameKey: key,
        dark: dark,
        scale: 1,
        size: const Size(360, 800),
      );
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(key),
        matchesGoldenFile(
          'goldens/lesson_completion_${dark ? 'dark' : 'light'}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
