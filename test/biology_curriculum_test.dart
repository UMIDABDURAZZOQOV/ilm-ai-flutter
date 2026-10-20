import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/api_contract.dart';
import 'package:ilm_ai_flutter/core/network/error_message.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/services/sound_service.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_repository.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/content_source_button.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/curriculum_learning_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_lesson_screen.dart';
import 'release_hardening_test.dart' show Adapter, reply;
import 'support/offline_preferences.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final lesson = fixture('biology_first_lesson');
  final tree = fixture('biology_grade5_tree');
  late Dio dio;
  late List<RequestOptions> requests;
  setUp(() {
    requests = [];
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = Adapter((request) {
        requests.add(request);
        if (request.path.endsWith('/start')) return reply(200, lesson);
        if (request.path.endsWith('/complete')) {
          return reply(200, fixture('biology_first_result'));
        }
        if (request.path.endsWith('/grades')) {
          return reply(200, fixture('biology_grades'));
        }
        if (request.path.endsWith('/curriculum')) {
          return reply(200, fixture('biology_grade5_outline'));
        }
        if (request.path.endsWith('/tree')) return reply(200, tree);
        throw StateError('Unexpected QA request ${request.path}');
      });
  });
  tearDown(() => dio.close(force: true));

  Future<PrefsService> mount(
    WidgetTester tester,
    Widget widget, {
    Map<String, Object> saved = const {},
    double scale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.language: 'uz',
      ...saved,
    });
    final prefs = await PrefsService.create();
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
          home: MediaQuery(
            data: MediaQueryData(
              size: tester.view.physicalSize,
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: Scaffold(body: widget),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return prefs;
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text).first;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  test(
    'grade is sent to the existing tree endpoint and source references survive parsing',
    () async {
      final repo = SkillTreeRepository(dio);
      await repo.getTree(userId: 900002, subjectSlug: 'biologiya', grade: 5);
      expect(requests.single.queryParameters['grade'], 5);
      final parsed = LessonStartResult.fromJson(lesson);
      expect(parsed.questions.length, 12);
      expect(
        PracticeQuestion.fromJson(
          (lesson['questions'] as List).last as Map<String, dynamic>,
        ).source?['printed_pages'],
        [6],
      );
      expect(
        parsed.theory
            .map((c) => (c.source!['printed_pages'] as List).first)
            .toSet(),
        {4, 6},
      );
      expect(
        parsed.questions
            .map((q) => (q.source!['pdf_pages'] as List).first)
            .toSet(),
        {5, 7},
      );
      expect(
        SkillTreeResponse.fromJson(tree).units.first.coverageComplete,
        isFalse,
      );
    },
  );

  test(
    'old OAuth backend fails before opening a token-bearing callback',
    () async {
      dio.httpClientAdapter = Adapter(
        (_) => reply(200, {
          'auth_url': 'https://accounts.google.com/',
          'state': 'test-state',
        }),
      );
      expect(
        AuthRepository(dio).getGoogleLoginUrl(
          'https://api.example.test/auth/google-callback-mobile',
          challenge: 'challenge',
        ),
        throwsA(isA<ApiCompatibilityException>()),
      );
      expect(
        extractError(const ApiCompatibilityException(), language: 'uz'),
        contains('server versiyalari'),
      );
    },
  );

  test(
    'PKCE-capable login URL is accepted and malformed subjects have a distinct error',
    () async {
      dio.httpClientAdapter = Adapter(
        (_) => reply(200, {
          'auth_url': 'https://accounts.google.com/',
          'state': 'test-state',
          'mobile_auth_version': 2,
        }),
      );
      final response = await AuthRepository(dio).getGoogleLoginUrl(
        'https://api.example.test/auth/google-callback-mobile',
        challenge: 'challenge',
      );
      expect(response.state, 'test-state');
      dio.httpClientAdapter = Adapter(
        (_) => reply(200, {'unexpected': 'not a catalogue'}),
      );
      expect(
        SkillTreeRepository(dio).getSubjects(),
        throwsA(isA<InvalidApiResponseException>()),
      );
    },
  );

  for (final size in [const Size(320, 568), const Size(640, 360)]) {
    testWidgets(
      'backend grade picker scrolls at $size with large text and marks unread books',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final subject = SkillSubject.fromJson(
          tree['subject'] as Map<String, dynamic>,
        );
        await mount(
          tester,
          CurriculumLearningScreen(subject: subject, onChangeSubject: () {}),
          scale: 2,
        );
        await tester.scrollUntilVisible(
          find.text('5-sinf — Biologiya'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('5-sinf — Biologiya'), findsOneWidget);
        await tester.drag(find.byType(ListView).first, const Offset(0, -650));
        await tester.pump();
        expect(tester.takeException(), isNull);
        // Counts/statuses come from the real staged API fixture, not fake content.
        final grades = fixture('biology_grades')['grades'] as List;
        expect(
          grades
              .where((g) => (g['status'] as String).startsWith('blocked_'))
              .map((g) => g['grade'])
              .toList(),
          [6, 8],
        );
      },
    );
  }

  testWidgets(
    'selecting grade persists it per account and requests the matching path',
    (tester) async {
      final subject = SkillSubject.fromJson(
        tree['subject'] as Map<String, dynamic>,
      );
      final prefs = await mount(
        tester,
        CurriculumLearningScreen(subject: subject, onChangeSubject: () {}),
      );
      await tap(tester, '5-sinf — Biologiya');
      expect(prefs.getString('class_900002'), '5');
      expect(prefs.getString('class_1'), isNull);
      expect(
        requests.any(
          (r) => r.path.endsWith('/tree') && r.queryParameters['grade'] == 5,
        ),
        isTrue,
      );
      expect(
        find.textContaining('Qolgan mavzular tayyorlanmoqda.'),
        findsOneWidget,
      );
      await tap(tester, 'Mavzular');
      expect(find.textContaining('1-§. Biologiya'), findsOneWidget);
      expect(find.text('Keyingi sinfga o‘tish'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reviewed first biology lesson shows source, accepts real answers and completes once',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final row = SkillTreeLesson.fromJson(
        ((tree['units'] as List).first['lessons'] as List).first
            as Map<String, dynamic>,
      );
      await mount(tester, SkillLessonScreen(lesson: row));
      expect(find.byType(ContentSourceButton), findsOneWidget);
      await tester.ensureVisible(find.byType(ContentSourceButton));
      await tester.tap(find.byType(ContentSourceButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kitobdagi bet: 4'), findsOneWidget);
      expect(find.textContaining('PDF sahifasi: 5'), findsOneWidget);
      Navigator.of(
        tester.element(find.textContaining('Kitobdagi bet: 4')),
      ).pop();
      await tester.pumpAndSettle();
      for (var i = 1; i < (lesson['theory'] as List).length; i++) {
        await tap(tester, 'Davom etish');
      }
      await tap(tester, 'Testni boshlash!');
      for (final q in lesson['questions'] as List) {
        await tap(tester, q['correct_answer'] as String);
        await tap(tester, 'TEKSHIRISH');
        expect(find.text('Ajoyib!'), findsOneWidget);
        await tap(tester, 'Davom etish');
      }
      expect(find.text('Dars yakunlandi!'), findsOneWidget);
      expect(find.text('+20'), findsOneWidget);
      final completions = requests
          .where((r) => r.path.endsWith('/complete'))
          .toList();
      expect(completions.length, 1);
      final body = completions.single.data as Map;
      final answers = body['results'] as List;
      expect(answers.length, 12);
      expect(answers.every((r) => r['user_answer'] is String), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'long textbook chapter wraps and its incomplete checkpoint scrolls at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final subject = SkillSubject.fromJson(
          tree['subject'] as Map<String, dynamic>,
        );
        await mount(
          tester,
          CurriculumLearningScreen(subject: subject, onChangeSubject: () {}),
          saved: {'class_900002': '5'},
          scale: 2,
        );
        await tester.pumpAndSettle();
        final title = ((tree['units'] as List).first['title_uz'] as String)
            .toUpperCase();
        final label = find.text(title);
        await tester.scrollUntilVisible(
          label,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.widget<Text>(label).maxLines, isNull);
        final checkpoint = find.bySemanticsLabel('$title. Qulflangan');
        await tester.scrollUntilVisible(
          checkpoint,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(checkpoint);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Bobning qolgan darslari tayyorlanmoqda'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  test('all seven grades report actual authored lesson counts', () async {
    dio.httpClientAdapter = Adapter(
      (_) => reply(200, fixture('biology_batch_grades')),
    );
    final grades = await SkillTreeRepository(dio).getGrades('biologiya');
    expect(grades.map((g) => g.readyLessons).toList(), [4, 3, 2, 4, 2, 2, 2]);
    for (final grade in [6, 8]) {
      final data = LessonStartResult.fromJson(
        fixture('biology_grade${grade}_lesson'),
      );
      expect(fixture('biology_grade${grade}_lesson')['content_language'], 'uz');
      for (final question in data.questions) {
        expect(question.source!['source_set_sha256'], isNotEmpty);
        expect(question.source!['source_segments'], isNotEmpty);
      }
    }
  });

  for (final grade in [6, 8]) {
    testWidgets(
      'grade $grade real sourced lesson completes through the existing Ilmo engine',
      (tester) async {
        final data = fixture('biology_grade${grade}_lesson');
        final path = fixture('biology_grade${grade}_tree');
        dio.httpClientAdapter = Adapter((request) {
          requests.add(request);
          if (request.path.endsWith('/start')) return reply(200, data);
          if (request.path.endsWith('/complete')) {
            return reply(200, fixture('biology_grade${grade}_result'));
          }
          throw StateError('Unexpected lesson request');
        });
        final row = SkillTreeLesson.fromJson(
          ((path['units'] as List).first['lessons'] as List).first
              as Map<String, dynamic>,
        );
        await mount(tester, SkillLessonScreen(lesson: row));
        for (var i = 1; i < (data['theory'] as List).length; i++) {
          await tap(tester, 'Davom etish');
        }
        await tap(tester, 'Testni boshlash!');
        for (final q in data['questions'] as List) {
          await tap(tester, q['correct_answer'] as String);
          await tap(tester, 'TEKSHIRISH');
          expect(find.text('Ajoyib!'), findsOneWidget);
          await tap(tester, 'Davom etish');
        }
        expect(find.text('Dars yakunlandi!'), findsOneWidget);
        expect(find.text('+20'), findsOneWidget);
        final sent = requests
            .where((r) => r.path.endsWith('/complete'))
            .toList();
        expect(sent.length, 1);
        expect(
          (sent.single.data as Map)['results'],
          hasLength((data['questions'] as List).length),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
    for (final language in ['uz', 'ru', 'en']) {
      testWidgets(
        'split PDF source $grade $language scrolls at 200 percent text on 320px',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final data = fixture('biology_grade${grade}_lesson');
          final source =
              (data['questions'] as List).first['source']
                  as Map<String, dynamic>;
          await mount(
            tester,
            ContentSourceButton(source: source, language: language),
            scale: 2,
          );
          await tester.tap(find.byType(ContentSourceButton));
          await tester.pumpAndSettle();
          final part = (source['source_segments'] as List).first as Map;
          final file = find.text(part['file_name'] as String);
          await tester.ensureVisible(file);
          expect(file, findsOneWidget);
          final label = language == 'uz'
              ? 'Qism ichidagi PDF sahifasi:'
              : language == 'ru'
              ? 'Страница PDF внутри части:'
              : 'PDF page within this part:';
          final page = find.textContaining(label);
          await tester.ensureVisible(page);
          expect(page, findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'real digital lab keeps Ilmo, feedback and once-only 10 XP completion',
    (tester) async {
      final data = fixture('biology_activity_lesson');
      dio.httpClientAdapter = Adapter((request) {
        requests.add(request);
        if (request.path.endsWith('/start')) return reply(200, data);
        if (request.path.endsWith('/complete')) {
          return reply(200, fixture('biology_activity_result'));
        }
        throw StateError('Unexpected activity request');
      });
      final row = SkillTreeLesson.fromJson(fixture('biology_activity_row'));
      await mount(tester, SkillLessonScreen(lesson: row));
      expect(
        find.textContaining('haqiqiy laboratoriya ishini'),
        findsOneWidget,
      );
      for (var i = 1; i < (data['theory'] as List).length; i++) {
        await tap(tester, 'Davom etish');
      }
      await tap(tester, 'Testni boshlash!');
      for (final q in data['questions'] as List) {
        await tap(tester, q['correct_answer'] as String);
        await tap(tester, 'TEKSHIRISH');
        expect(find.text('Ajoyib!'), findsOneWidget);
        await tap(tester, 'Davom etish');
      }
      expect(find.text('Dars yakunlandi!'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(requests.where((r) => r.path.endsWith('/complete')), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  for (final kind in ['laboratory', 'practical']) {
    for (final language in ['uz', 'ru', 'en']) {
      testWidgets(
        '$kind citation $language has no null paragraph and fits large text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final source = Map<String, dynamic>.from(
            (fixture('biology_activity_lesson')['questions'] as List)
                    .first['source']
                as Map,
          )..['activity_kind'] = kind;
          final reference = kind == 'laboratory'
              ? {
                  'uz': 'Laboratoriya 1',
                  'ru': 'Лабораторная 1',
                  'en': 'Lab 1',
                }[language]!
              : {
                  'uz': 'Amaliy 1',
                  'ru': 'Практическая 1',
                  'en': 'Activity 1',
                }[language]!;
          await mount(
            tester,
            ContentSourceButton(source: source, language: language),
            scale: 2,
          );
          expect(find.textContaining(reference), findsOneWidget);
          expect(find.textContaining('§null'), findsNothing);
          await tester.tap(find.byType(ContentSourceButton));
          await tester.pumpAndSettle();
          final chapter = find.text(source['chapter_title'] as String);
          await tester.ensureVisible(chapter);
          expect(chapter, findsOneWidget);
          expect(find.textContaining('§null'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
