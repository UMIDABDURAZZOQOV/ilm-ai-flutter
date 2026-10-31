import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/duo_onboarding_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/content_source_button.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/learning_journey_widgets.dart';
import 'package:ilm_ai_flutter/features/study_help/study_help.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/core/services/sound_service.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/curriculum_learning_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_lesson_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_feedback_panel.dart';
import 'support/offline_preferences.dart';
import 'biology_curriculum_test.dart' show fixture;
import 'release_hardening_test.dart' show Adapter, reply;
import 'study_help_test.dart' show DeferredHelp, evidence;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (!integratedBeta) {
    test(
      'UI policy applies to the opt-in Beta',
      () => expect(integratedBetaRequested, false),
    );
    return;
  }

  Future<void> mountBiology(WidgetTester tester, Widget child) async {
    SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
    final prefs = await PrefsService.create();
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8930'));
    dio.httpClientAdapter = Adapter((r) {
      if (r.path.endsWith('/start')) {
        return reply(200, fixture('biology_first_lesson'));
      }
      if (r.path.endsWith('/grades')) {
        return reply(200, fixture('biology_grades'));
      }
      if (r.path.endsWith('/curriculum')) {
        return reply(200, fixture('biology_grade5_outline'));
      }
      if (r.path.endsWith('/tree')) {
        return reply(200, fixture('biology_grade5_tree'));
      }
      return reply(404, {});
    });
    addTearDown(() => dio.close(force: true));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(900002),
          learningPreferencesProvider.overrideWithValue(
            OfflinePreferences(prefs),
          ),
          skillTreeRepositoryProvider.overrideWithValue(
            SkillTreeRepository(dio),
          ),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'grade picker, learning path and outline show no counts, AI entry or page locators',
    (tester) async {
      final subject = SkillSubject.fromJson(
        fixture('biology_grade5_tree')['subject'] as Map<String, dynamic>,
      );
      await mountBiology(
        tester,
        CurriculumLearningScreen(subject: subject, onChangeSubject: () {}),
      );
      expect(find.textContaining('Tayyor darslar:'), findsNothing);
      await tester.ensureVisible(find.text('5-sinf — Biologiya'));
      await tester.tap(find.text('5-sinf — Biologiya'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tayyor darslar:'), findsNothing);
      expect(find.byType(StudyHelpButton), findsNothing);
      expect(
        find.byKey(const ValueKey('quick_subject_switch')),
        findsOneWidget,
      );
      await tester.tap(find.text('Mavzular'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1-§. Biologiya'), findsOneWidget);
      expect(find.textContaining('bet ·'), findsNothing);
      expect(find.byType(StudyHelpButton), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final correct in [false, true]) {
    testWidgets(
      'Biology MCQ correct=$correct help only after the existing check',
      (tester) async {
        final tree = SkillTreeResponse.fromJson(fixture('biology_grade5_tree'));
        await mountBiology(
          tester,
          SkillLessonScreen(lesson: tree.units.first.lessons.first),
        );
        for (final _ in fixture('biology_first_lesson')['theory'] as List) {
          expect(find.textContaining('Manba:'), findsNothing);
          expect(find.byType(StudyHelpButton), findsNothing);
          await tester.tap(find.byType(Duo3DButton).last);
          await tester.pumpAndSettle();
        }
        expect(find.byType(StudyHelpButton), findsNothing);
        final options =
            fixture('biology_first_lesson')['questions'][0]['options'] as List;
        final choice = find.text(options[correct ? 0 : 1] as String);
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Duo3DButton).last);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<LessonFeedbackPanel>(find.byType(LessonFeedbackPanel))
              .correct,
          correct,
        );
        expect(
          find.byKey(const ValueKey('question_study_help')),
          findsOneWidget,
        );
        expect(find.byType(StudyHelpSheet), findsNothing);
        await tester.tap(find.byType(Duo3DButton).last);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('question_study_help')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('unchecked or incomplete context cannot open help', (
    tester,
  ) async {
    for (final context in [
      const StudyHelpContext(subject: 'kimyo', grade: 7),
      const StudyHelpContext(subject: 'kimyo', grade: 7, checked: true),
      const StudyHelpContext(
        subject: 'kimyo',
        attemptId: 'owned',
        questionKey: 'q',
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyHelpButton(contextData: context, language: 'uz'),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('question_study_help')), findsNothing);
      expect(find.byType(StudyHelpSheet), findsNothing);
    }
  });

  testWidgets(
    'changing question closes the old explanation and cancels request',
    (tester) async {
      final dio = Dio();
      final repository = DeferredHelp(dio);
      final question = StateProvider((ref) => 'q');
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue(1),
          studyHelpRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => StudyHelpButton(
                  contextData: StudyHelpContext(
                    subject: 'kimyo',
                    grade: 7,
                    attemptId: 'owned',
                    questionKey: ref.watch(question),
                    checked: true,
                  ),
                  language: 'uz',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('question_study_help')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(repository.cancellation, isNotNull);
      container.read(question.notifier).state = 'next';
      await tester.pumpAndSettle();
      expect(find.byType(StudyHelpSheet), findsNothing);
      expect(repository.cancellation!.isCancelled, isTrue);
      repository.result.complete(evidence());
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      dio.close();
    },
  );

  testWidgets('bibliography hidden, progress kept without total count', (
    tester,
  ) async {
    final source = {
      'book_title': 'Private textbook',
      'authors': ['Author'],
      'printed_pages': [5],
      'pdf_pages': [6],
    };
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(lightColors),
        home: Scaffold(
          body: Column(
            children: [
              ContentSourceButton(source: source, language: 'uz'),
              const LearningUnitHeader(
                title: 'Bob',
                language: 'uz',
                completed: 2,
                total: 25,
                coverageComplete: true,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.textContaining('Private textbook'), findsNothing);
    expect(find.textContaining('Manba:'), findsNothing);
    expect(find.textContaining('/25'), findsNothing);
    expect(find.text('Bajarilgan darslar: 2'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      2 / 25,
    );
    expect(source['book_title'], 'Private textbook');
  });

  testWidgets(
    'textbook notice belongs to first onboarding and stays hidden after completion/restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();
      Future<ProviderContainer> mount() async {
        final container = ProviderContainer(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue(null),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildAppTheme(lightColors),
              home: const DuoOnboardingScreen(initialStep: 1),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return container;
      }

      var container = await mount();
      expect(
        find.text(
          "Barcha o'quv mavzulari maktab darsliklari asosida tayyorlangan.",
        ),
        findsOneWidget,
      );
      container.read(onboardingCompleteProvider.notifier).complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('onboarding_textbook_notice')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      container = await mount();
      expect(container.read(onboardingCompleteProvider), true);
      expect(
        find.byKey(const ValueKey('onboarding_textbook_notice')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );
}
