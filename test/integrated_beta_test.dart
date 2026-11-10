import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/network/mobile_api.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/learning/presentation/assessment_lesson_screen.dart';
import 'package:ilm_ai_flutter/features/learning/data/assessment_repository.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/duo_onboarding_screen.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/application/lesson_entry.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_home_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_grade_card.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_feedback_panel.dart';
import 'package:ilm_ai_flutter/features/study_help/study_help.dart';
import 'package:ilm_ai_flutter/features/chemistry/presentation/chemistry_display_text.dart';
import 'package:ilm_ai_flutter/features/world_history/presentation/world_history_display_text.dart';
import 'release_hardening_test.dart' show Adapter, reply;
import 'support/capture_release_frame.dart';
import 'support/load_review_fonts.dart';

typedef Json = Map<String, dynamic>;
Json fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Json;

class _LoggedOut extends AuthController {
  @override
  Future<StoredTokens?> build() async => null;
}

const presets = [
  (
    slug: 'fizika',
    grade: 6,
    lesson: 'physics_lesson6',
    result: 'physics_result6',
    catalog: 'physics_catalog',
  ),
  (
    slug: 'kimyo',
    grade: 7,
    lesson: 'chemistry_lesson',
    result: 'chemistry_results',
    catalog: 'chemistry_catalog',
  ),
  (
    slug: 'jahon_tarixi',
    grade: 6,
    lesson: 'world_history_lesson',
    result: 'world_history_results',
    catalog: 'world_history_catalog',
  ),
  (
    slug: 'ozbekiston_tarixi',
    grade: 7,
    lesson: 'uzbekistan_history/lesson1',
    result: 'uzbekistan_history/result',
    catalog: 'uzbekistan_history/catalog7',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('UIUX_CAPTURE')) await loadReviewFonts();
  });
  final helpPath = reviewedMobileRelease
      ? '/mobile/study-help'
      : '/beta/study-help';
  if (!reviewedLearning) {
    test(
      'normal build keeps the integrated beta disabled',
      () => expect(integratedBetaRequested, isFalse),
    );
    return;
  }
  if (integratedBeta) {
    test(
      'beta origin rejects production, LAN, credentials and mismatched host',
      () {
        requireBetaConfiguration('http://127.0.0.1:8930');
        expect(
          isBetaOrigin(Uri.parse('http://127.0.0.1:8930/beta/skills/subjects')),
          isTrue,
        );
        for (final uri in [
          'https://ilm-ai-backend-256x.onrender.com',
          'http://192.168.1.2:8930',
          'http://127.0.0.1:8925',
          'http://secret@127.0.0.1:8930',
        ]) {
          expect(isBetaOrigin(Uri.parse(uri)), isFalse);
        }
        expect(mobileAppScheme, 'ilmai-beta');
      },
    );
  }
  test(
    'reviewed skills API uses its isolated namespace without preview endpoints',
    () async {
      final dio = Dio(BaseOptions(baseUrl: betaApiOrigin));
      RequestOptions? captured;
      dio.interceptors.add(MobileApiInterceptor());
      dio.httpClientAdapter = Adapter((options) {
        captured = options;
        return reply(200, []);
      });
      await dio.get('/skills/subjects');
      expect(
        captured!.path,
        reviewedMobileRelease
            ? '/mobile/skills/subjects'
            : '/beta/skills/subjects',
      );
      dio.close();
    },
  );

  testWidgets(
    'onboarding keeps all subjects visible and locks unavailable grades',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();
      final names = [
        'Biologiya',
        'Fizika',
        'Kimyo',
        'O‘zbekiston tarixi',
        'Jahon tarixi',
        'Matematika',
        'Ona tili',
      ];
      final slugs = [
        'biologiya',
        'fizika',
        'kimyo',
        'ozbekiston_tarixi',
        'jahon_tarixi',
        'matematika',
        'ona_tili',
      ];
      final grades = [
        [5, 6, 7, 8, 9, 10, 11],
        [6, 7, 8, 9, 10, 11],
        [7, 8, 9, 10, 11],
        [7, 8, 9, 10, 11],
        [6, 7, 8, 9, 10, 11],
        <int>[],
        <int>[],
      ];
      final subjects = [
        for (var i = 0; i < names.length; i++)
          SkillSubject(
            id: i + 1,
            slug: slugs[i],
            nameUz: names[i],
            nameRu: names[i],
            nameEn: names[i],
            available: i < 5,
            grades: grades[i],
          ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(_LoggedOut.new),
            subjectCatalogProvider.overrideWith((ref) async => subjects),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in names) {
        expect(find.text(name), findsOneWidget);
      }
      expect(
        tester
            .widget<SubjectGradeCard>(
              find.byKey(const ValueKey('onboarding_matematika')),
            )
            .canStudy,
        isFalse,
      );
      for (var grade = 5; grade <= 11; grade++) {
        await tester.ensureVisible(find.text('$grade-sinf'));
        await tester.tap(find.text('$grade-sinf'));
        await tester.pumpAndSettle();
        for (final item in subjects) {
          expect(find.text(item.nameUz), findsOneWidget);
          expect(
            tester
                .widget<SubjectGradeCard>(
                  find.byKey(ValueKey('onboarding_${item.slug}')),
                )
                .canStudy,
            item.available && item.grades.contains(grade),
          );
        }
        if (grade == 5) {
          await tester.ensureVisible(find.text('Kimyo'));
          await tester.tap(find.text('Kimyo'));
          await tester.pump();
          expect(find.byType(SnackBar), findsOneWidget);
          expect(
            tester
                .widget<Duo3DButton>(
                  find.byKey(const ValueKey('onboarding_continue_btn')),
                )
                .onPressed,
            isNull,
          );
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final preset in presets) {
    late Dio dio;
    late Json lesson, result;
    late Map<String, Json> committed;
    late List<RequestOptions> requests;
    bool loseNextAnswer = false;
    bool rejectNextAnswer = false;
    Completer<ResponseBody>? delayedAnswer;
    bool completedNode = false;
    void setup({
      bool onlyFrq = false,
      bool completed = false,
      bool? checkedCorrect,
    }) {
      completedNode = completed;
      lesson = fixture(preset.lesson);
      final content = lesson['content'] as Json;
      lesson['content'] = {
        ...content,
        'formulas': content['formulas'] ?? [],
        'examples': content['examples'] ?? [],
        'reflections': content['reflections'] ?? [],
      };
      if (onlyFrq) {
        lesson['questions'] = [
          (lesson['questions'] as List).firstWhere(
            (q) => q['response_kind'] != 'concept_selection',
          ),
        ];
      }
      result = fixture(preset.result);
      committed = {};
      requests = [];
      loseNextAnswer = false;
      rejectNextAnswer = false;
      delayedAnswer = null;
      dio = Dio(BaseOptions(baseUrl: betaApiOrigin));
      // Dio otherwise moves these large history catalogues to a real isolate,
      // which cannot finish while the widget test advances its fake clock.
      dio.transformer = SyncTransformer();
      dio.httpClientAdapter = Adapter((request) {
        requests.add(request);
        if (request.path.endsWith('/catalog')) {
          return reply(200, fixture(preset.catalog));
        }
        if (request.path.endsWith('/start')) {
          final first =
              requests.where((r) => r.path.endsWith('/start')).length == 1;
          return reply(200, {
            ...lesson,
            'answers': Map.of(committed),
            if (completedNode && first)
              'result': {
                ...(result['result'] ?? result) as Map,
                'stars': 3,
                'elapsed_seconds': 20,
              },
          });
        }
        if (request.path.endsWith('/answers')) {
          if (rejectNextAnswer) {
            rejectNextAnswer = false;
            return reply(422, {
              'detail': {
                'code': 'answer_required',
                'feedback': 'Synthetic required fields',
              },
            });
          }
          final key = (request.data as Map)['assessment_key'] as String;
          // UI transport contract only; real answer correctness is exercised
          // against all five unchanged graders in test_integrated_beta.py.
          final responses = preset.slug == 'ozbekiston_tarixi'
              ? fixture('uzbekistan_history/feedback42')['responses'] as Map
              : result['answers'] as Map;
          final feedback = Map<String, dynamic>.from(
            (responses[key] ?? responses.values.first) as Map,
          )..['assessment_key'] = key;
          if (checkedCorrect != null) {
            feedback['is_correct'] = checkedCorrect;
            // This fixture tests UI states, not grading. Keep its synthetic
            // status prose consistent with the forced correct/wrong state.
            feedback['feedback'] = checkedCorrect
                ? 'Sinov: javob mos keldi.'
                : 'Sinov: javob mos kelmadi. Tekshirilgan yechimni ko‘ring.';
          }
          committed[key] = feedback;
          if (loseNextAnswer) {
            loseNextAnswer = false;
            throw DioException(
              requestOptions: request,
              type: DioExceptionType.receiveTimeout,
            );
          }
          final waiting = delayedAnswer;
          if (waiting != null) {
            delayedAnswer = null;
            return waiting.future;
          }
          return reply(200, feedback);
        }
        if (request.path.endsWith('/complete')) {
          return reply(200, {
            ...(result['result'] ?? result) as Map,
            'stars': 3,
            'elapsed_seconds': 20,
          });
        }
        if (request.path == helpPath) {
          final data = request.data as Map;
          return reply(200, {
            ...data,
            'mode': 'reviewed_evidence',
            'answered': true,
            'provider_status': 'unconfigured',
            'title': 'Izoh',
            'source_refs': [],
            'evidence': [
              {
                'text': 'Tekshirilgan izoh',
                'source_refs': [
                  {
                    'book_title': 'Hidden textbook',
                    'printed_pages': [9],
                  },
                ],
              },
            ],
          });
        }
        return reply(404, {'detail': 'unexpected_endpoint'});
      });
    }

    SkillTreeLesson descriptor() => SkillTreeLesson(
      id: -1,
      slug: lesson['lesson_key'] as String,
      assessmentKey: lesson['lesson_key'] as String,
      assessmentSubject: preset.slug,
      grade: preset.grade,
      titleUz: lesson['title'] as String,
      titleRu: lesson['title'] as String,
      titleEn: lesson['title'] as String,
      orderIndex: 1,
      xpReward: 10,
      status: completedNode ? LessonStatus.completed : LessonStatus.unlocked,
      stars: 0,
    );
    final captureKey = GlobalKey();
    Future<PrefsService> mount(
      WidgetTester tester, {
      double scale = 1,
      PrefsService? store,
    }) async {
      if (const bool.fromEnvironment('UIUX_CAPTURE')) {
        tester.view.physicalSize = const Size(720, 1600);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }
      if (store == null) SharedPreferences.setMockInitialValues({});
      final prefs = store ?? await PrefsService.create();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue(900777),
            dioProvider.overrideWithValue(dio),
          ],
          child: RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(lightColors),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: AssessmentLessonScreen(lesson: descriptor()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return prefs;
    }

    String display(String text) => preset.slug == 'kimyo'
        ? chemistryDisplayText(text)
        : preset.slug == 'jahon_tarixi'
        ? worldHistoryDisplayText(text)
        : text;
    List<Json> teaching() {
      final c = lesson['content'] as Json;
      return [
        for (final key in ['cards', 'formulas', 'examples', 'reflections'])
          for (final item in c[key] as List)
            Map<String, dynamic>.from(item as Map),
      ];
    }

    Future<void> action(WidgetTester tester) async {
      final button = find.byType(Duo3DButton).last;
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Future<void> exercises(WidgetTester tester) async {
      for (var i = 0; i < teaching().length; i++) {
        await action(tester);
      }
    }

    testWidgets(
      '${preset.slug} saving an unfinished answer refreshes the retained home entry',
      (tester) async {
        setup(onlyFrq: true);
        dio.options.baseUrl = apiBaseUrl;
        SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
        final prefs = await PrefsService.create();
        final container = ProviderContainer(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue(900777),
            dioProvider.overrideWithValue(dio),
          ],
        );
        addTearDown(container.dispose);
        final homeEntry = lessonEntryProvider(descriptor());
        final subscription = container.listen(homeEntry, (_, _) {});
        addTearDown(subscription.close);
        expect(container.read(homeEntry).state, LessonEntryState.start);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: buildAppTheme(lightColors),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => AssessmentLessonScreen(
                          // A separate descriptor instance matches real routing.
                          lesson: descriptor(),
                        ),
                      ),
                    ),
                    child: const Text('Open QA lesson'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open QA lesson'));
        await tester.pumpAndSettle();
        await exercises(tester);
        final editor = find.byType(TextField).first;
        await tester.ensureVisible(editor);
        await tester.enterText(editor, 'saved-qa-draft');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        final requestCount = requests.length;
        await tester.tap(find.byTooltip('Yopish'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Saqlab chiqish'));
        await tester.pumpAndSettle();
        expect(find.text('Open QA lesson'), findsOneWidget);
        final refreshed = container.read(homeEntry);
        expect(refreshed.state, LessonEntryState.resume);
        expect(refreshed.theory, isFalse);
        expect(refreshed.position, 1);
        expect(refreshed.total, 1);
        expect(requests.length, requestCount);
        expect(committed, isEmpty);
        expect(requests.where((r) => r.path.endsWith('/answers')), isEmpty);
        expect(
          prefs.getString(
            AssessmentRepository.storageKey(
              apiBaseUrl,
              900777,
              preset.slug,
              lesson['lesson_key'] as String,
            ),
          ),
          contains('saved-qa-draft'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '${preset.slug} pending answer shows waiting state and blocks duplicate taps',
      (tester) async {
        setup(checkedCorrect: true);
        lesson['questions'] = [
          (lesson['questions'] as List).firstWhere(
            (q) => q['response_kind'] == 'concept_selection',
          ),
        ];
        await mount(tester);
        await exercises(tester);
        final choice = find.byType(DuoChoiceCard).first;
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        final waiting = Completer<ResponseBody>();
        delayedAnswer = waiting;
        final button = find.byType(Duo3DButton).last;
        await tester.tap(button);
        for (var frame = 0; frame < 6; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(
          find.byKey(const ValueKey('assessment_action_loading')),
          findsOneWidget,
        );
        expect(tester.widget<Duo3DButton>(button).onPressed, isNull);
        expect(find.text('Qayta yuborish'), findsNothing);
        expect(requests.where((r) => r.path.endsWith('/answers')).length, 1);
        await tester.tap(button, warnIfMissed: false);
        await tester.pump();
        expect(requests.where((r) => r.path.endsWith('/answers')).length, 1);
        waiting.complete(reply(200, committed.values.single));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('assessment_action_loading')),
          findsNothing,
        );
        expect(find.byType(LessonFeedbackPanel), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        dio.close();
      },
    );

    for (final errorLanguage in ['uz', 'ru', 'en']) {
      testWidgets(
        '${preset.slug}/$errorLanguage reveals ungraded input error after IME closes and keeps draft editable',
        (tester) async {
          setup(onlyFrq: true, checkedCorrect: true);
          SharedPreferences.setMockInitialValues({
            PrefsKeys.language: errorLanguage,
          });
          final preferences = await PrefsService.create();
          await mount(tester, store: preferences);
          final requiredMessage = switch (errorLanguage) {
            'ru' => 'Заполните поля ответа и проверьте снова.',
            'en' => 'Complete the answer fields and check again.',
            _ => 'Javob maydonlarini to‘ldiring va qayta tekshiring.',
          };
          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          await exercises(tester);
          final field = preset.slug == 'fizika'
              ? find.byKey(const Key('physics-formula'))
              : find.byType(TextField).first;
          await tester.ensureVisible(field);
          final draftText = preset.slug == 'fizika' ? 'x/2' : 'botanika';
          await tester.enterText(field, draftText);
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          await tester.pumpAndSettle();
          rejectNextAnswer = true;
          await action(tester);
          expect(committed, isEmpty);
          expect(find.byType(LessonFeedbackPanel), findsNothing);
          expect(find.byType(StudyHelpButton), findsNothing);
          expect(
            tester
                .widget<EditableText>(
                  find.descendant(
                    of: field,
                    matching: find.byType(EditableText),
                  ),
                )
                .controller
                .text,
            draftText,
          );

          // Reproduce Android's late editor anchoring while its IME is closing,
          // after the validation response has already rendered above the field.
          await tester.ensureVisible(field);
          await tester.pumpAndSettle();
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          expect(find.text(requiredMessage).hitTestable(), findsOneWidget);

          // Once revealed, opening the editor again must not yank it back to the
          // error panel. The original answer remains repairable, not graded.
          await tester.ensureVisible(field);
          await tester.enterText(field, draftText);
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          await tester.pumpAndSettle();
          final editable = find.descendant(
            of: field,
            matching: find.byType(EditableText),
          );
          // A TextFormField includes long helper text. Check the actual input
          // area, not the centre of its whole decoration/helper container.
          await tester.ensureVisible(editable);
          await tester.pumpAndSettle();
          expect(editable.hitTestable(), findsOneWidget);
          if (preset.slug == 'fizika') {
            for (final input in [
              ('physics-value', '2'),
              ('physics-unit', 'cm'),
            ]) {
              final editor = find.byKey(Key(input.$1));
              await tester.ensureVisible(editor);
              await tester.enterText(editor, input.$2);
            }
          }
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          await action(tester);
          expect(committed.length, 1);
          expect(requests.where((r) => r.path.endsWith('/answers')).length, 2);
          expect(find.byType(LessonFeedbackPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          dio.close();
        },
      );
    }

    for (final frq in [false, true]) {
      for (final correct in [false, true]) {
        testWidgets(
          '${preset.slug} ${frq ? "FRQ" : "MCQ"} correct=$correct help only after grading',
          (tester) async {
            setup(onlyFrq: frq, checkedCorrect: correct);
            if (!frq) {
              lesson['questions'] = (lesson['questions'] as List)
                  .where((q) => q['response_kind'] == 'concept_selection')
                  .toList();
            }
            await mount(tester);
            await captureReleaseFrame(
              tester,
              captureKey,
              '${preset.slug}-${frq ? "frq" : "mcq"}-$correct-theory',
            );
            expect(find.byType(StudyHelpButton), findsNothing);
            await exercises(tester);
            await captureReleaseFrame(
              tester,
              captureKey,
              '${preset.slug}-${frq ? "frq" : "mcq"}-$correct-before',
            );
            expect(
              find.byKey(const ValueKey('question_study_help')),
              findsNothing,
            );
            expect(find.textContaining('Manba:'), findsNothing);
            if (!frq) {
              final choice = find.byType(DuoChoiceCard).first;
              await tester.ensureVisible(choice);
              await tester.tap(choice);
            } else if (preset.slug == 'fizika') {
              for (final entry in [
                ('physics-formula', 'x/2'),
                ('physics-value', '2'),
                ('physics-unit', 'cm'),
              ]) {
                final field = find.byKey(Key(entry.$1));
                await tester.ensureVisible(field);
                await tester.enterText(field, entry.$2);
              }
            } else {
              final field = find.byType(TextField).first;
              await tester.ensureVisible(field);
              await tester.enterText(field, 'botanika');
            }
            expect(requests.where((r) => r.path == helpPath), isEmpty);
            await action(tester);
            final panel = tester.widget<LessonFeedbackPanel>(
              find.byType(LessonFeedbackPanel),
            );
            expect(panel.correct, correct);
            await captureReleaseFrame(
              tester,
              captureKey,
              '${preset.slug}-${frq ? "frq" : "mcq"}-$correct-after',
            );
            expect(
              find.byKey(const ValueKey('question_study_help')),
              findsOneWidget,
            );
            expect(find.byType(StudyHelpSheet), findsNothing);
            await tester.tap(find.byKey(const ValueKey('question_study_help')));
            await tester.pumpAndSettle();
            expect(find.text('Tekshirilgan izoh'), findsOneWidget);
            await captureReleaseFrame(
              tester,
              captureKey,
              '${preset.slug}-${frq ? "frq" : "mcq"}-$correct-fallback',
            );
            expect(find.textContaining('Hidden textbook'), findsNothing);
            expect(find.textContaining('Manba:'), findsNothing);
            expect(requests.where((r) => r.path == helpPath).length, 1);
            await tester.tap(find.byIcon(Icons.close).last);
            await tester.pumpAndSettle();
            await action(tester);
            expect(find.byType(StudyHelpSheet), findsNothing);
            expect(
              find.byKey(const ValueKey('question_study_help')),
              findsNothing,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            dio.close();
          },
        );
      }
    }
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '${preset.slug} preserves every teaching page and enters exercises at ${scale}x',
        (tester) async {
          setup();
          await tester.binding.setSurfaceSize(const Size(360, 740));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await mount(tester, scale: scale);
          expect(requests.where((r) => r.path.endsWith('/catalog')), isEmpty);
          for (final page in teaching()) {
            expect(find.text(display(page['title'] as String)), findsOneWidget);
            await action(tester);
            expect(tester.takeException(), isNull);
          }
          expect(
            find.text(
              display((lesson['questions'] as List).first['prompt'] as String),
            ),
            findsOneWidget,
          );
          expect(
            requests.any(
              (r) => r.path.startsWith('/preview') || r.path.startsWith('/qa'),
            ),
            isFalse,
          );
          expect(
            find.byKey(const ValueKey('question_study_help')),
            findsNothing,
          );
          await tester.pumpWidget(const SizedBox());
          dio.close();
        },
      );
      testWidgets(
        '${preset.slug} real FRQ editor stores input and shows common feedback at ${scale}x',
        (tester) async {
          setup(onlyFrq: true);
          await tester.binding.setSurfaceSize(const Size(360, 740));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await mount(tester, scale: scale);
          await exercises(tester);
          expect(
            find.byKey(const ValueKey('question_study_help')),
            findsNothing,
          );
          if (preset.slug == 'fizika') {
            for (final entry in [
              ('physics-formula', 'x/2'),
              ('physics-value', '2'),
              ('physics-unit', 'cm'),
            ]) {
              final field = find.byKey(Key(entry.$1));
              await tester.ensureVisible(field);
              await tester.enterText(field, entry.$2);
            }
          } else {
            final field = find.byType(TextField).first;
            await tester.ensureVisible(field);
            await tester.enterText(field, 'botanika');
          }
          await action(tester);
          expect(find.byType(LessonFeedbackPanel), findsOneWidget);
          expect(
            find.byKey(const ValueKey('question_study_help')),
            findsOneWidget,
          );
          expect(requests.where((r) => r.path.endsWith('/answers')).length, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          dio.close();
        },
      );
    }
    testWidgets(
      '${preset.slug} resumes the exact teaching page after widget restart',
      (tester) async {
        setup();
        final prefs = await mount(tester);
        await action(tester);
        await action(tester);
        final title = display(teaching()[2]['title'] as String);
        expect(find.text(title), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await mount(tester, store: prefs);
        expect(find.text(title), findsOneWidget);
        expect(
          requests
              .where((r) => r.path.endsWith('/start'))
              .map((r) => (r.data as Map)['request_id'])
              .toSet()
              .length,
          1,
        );
        await tester.pumpWidget(const SizedBox());
        dio.close();
      },
    );
    testWidgets(
      '${preset.slug} completed path starts a fresh review, not an old result',
      (tester) async {
        setup(completed: true);
        await mount(tester);
        expect(
          find.text(display(teaching().first['title'] as String)),
          findsOneWidget,
        );
        final starts = requests
            .where((r) => r.path.endsWith('/start'))
            .toList();
        expect(starts.length, 2);
        expect(
          (starts.first.data as Map)['request_id'],
          isNot((starts.last.data as Map)['request_id']),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        dio.close();
      },
    );
  }
}
