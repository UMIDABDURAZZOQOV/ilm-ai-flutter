// Public fixtures captured from the actual isolated History API; no private keys.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/world_history_preview.dart';
import 'package:ilm_ai_flutter/core/network/api_contract.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/world_history/data/world_history_repository.dart';
import 'package:ilm_ai_flutter/features/world_history/presentation/world_history_preview_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_feedback_panel.dart';
import 'release_hardening_test.dart' show Adapter, reply;
import 'support/load_review_fonts.dart';

Json fixture(String name) =>
    jsonDecode(
          File('test/fixtures/world_history_$name.json').readAsStringSync(),
        )
        as Json;
const captureKey = Key('history-review');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadReviewFonts);
  late Dio dio;
  late Json lesson, results, catalog, grade7Catalog;
  late List<RequestOptions> requests;
  final committed = <String, Json>{};
  bool lostAnswer = false;
  setUp(() {
    lesson = fixture('lesson');
    results = fixture('results');
    catalog = fixture('catalog');
    grade7Catalog = fixture('grade7_catalog');
    requests = [];
    committed.clear();
    lostAnswer = false;
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8916'))
      // Real API fixtures can exceed Dio's isolate-decoding threshold. Keep
      // fixture decoding within the widget test's controlled async zone.
      ..transformer = SyncTransformer()
      ..httpClientAdapter = Adapter((r) {
        requests.add(r);
        if (r.path.endsWith('/catalog')) {
          final grade = r.queryParameters['grade'] as int;
          return reply(
            200,
            grade == 6
                ? catalog
                : grade == 7
                ? grade7Catalog
                : fixture('grade${grade}_catalog'),
          );
        }
        if (r.path.endsWith('/start')) {
          return reply(200, {...lesson, 'answers': Map.of(committed)});
        }
        if (r.path.endsWith('/answers')) {
          final key = (r.data as Map)['assessment_key'] as String;
          final value = Map<String, dynamic>.from(
            (results['answers'] as Map)[key] as Map,
          );
          committed[key] = value;
          if (lostAnswer) {
            lostAnswer = false;
            throw DioException(
              requestOptions: r,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return reply(200, value);
        }
        if (r.path.endsWith('/complete')) return reply(200, results['result']);
        throw StateError('Unexpected ${r.path}');
      });
  });
  tearDown(() => dio.close(force: true));

  Future<PrefsService> mount(
    WidgetTester t, {
    PrefsService? prefs,
    String language = 'uz',
    bool dark = false,
    double scale = 1,
    int uid = 900006,
    Size size = const Size(390, 844),
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    if (prefs == null) {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.language: language,
        PrefsKeys.themeMode: dark ? 'dark' : 'light',
      });
    }
    final store = prefs ?? await PrefsService.create();
    await t.pumpWidget(
      ProviderScope(
        key: ValueKey('$uid-$language-$dark-$scale'),
        overrides: [
          prefsServiceProvider.overrideWithValue(store),
          currentUserIdProvider.overrideWithValue(uid),
          worldHistoryRepositoryProvider.overrideWithValue(
            WorldHistoryRepository(dio),
          ),
        ],
        child: RepaintBoundary(
          key: captureKey,
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
            home: const WorldHistoryPreviewScreen(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return store;
  }

  Future<void> tapFinder(WidgetTester t, Finder finder) async {
    await t.pumpAndSettle();
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String text) =>
      tapFinder(t, find.text(text).first);
  Future<void> begin(WidgetTester t) async {
    await tap(t, 'Darsni boshlash');
    final cards = jsonRows((lesson['content'] as Json)['cards']);
    for (var i = 0; i < cards.length - 1; i++) {
      if (find.text('Davom etish').evaluate().isEmpty) return;
      await tap(t, 'Davom etish');
    }
    await tap(t, 'Mashqlarga o‘tish');
  }

  void skip(int count) {
    for (final q in jsonRows(lesson['questions']).take(count)) {
      committed[q['key'] as String] = Map<String, dynamic>.from(
        (results['answers'] as Map)[q['key']] as Map,
      );
    }
  }

  Future<void> capture(WidgetTester t, String name) async {
    if (!const bool.fromEnvironment('WORLD_HISTORY_CAPTURE')) return;
    await t.pumpAndSettle();
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final directory = Directory('build/world-history-review')
        ..createSync(recursive: true);
      File(
        '${directory.path}/$name.png',
      ).writeAsBytesSync(bytes.buffer.asUint8List());
      image.dispose();
    });
  }

  test(
    'preview gate requires explicit loopback and rejects remote origins',
    () {
      expect(worldHistoryPreview, false);
      expect(worldHistoryPreviewAllowed('http://127.0.0.1:8916'), false);
      expect(
        worldHistoryPreviewAllowed('http://127.0.0.1:8916', enabled: true),
        true,
      );
      for (final url in [
        'https://ilm-ai.onrender.com',
        'http://192.168.0.1',
        'http://localhost?token=x',
        'http://user:secret@localhost',
      ]) {
        expect(worldHistoryPreviewAllowed(url, enabled: true), false);
      }
    },
  );
  test('real public API fixtures pass and private keys fail', () {
    final repo = WorldHistoryRepository(dio);
    expect(repo.checked(catalog, 'catalog')['grade'], 6);
    expect(jsonRows(repo.checked(lesson, 'attempt')['questions']).length, 14);
    final bad = jsonDecode(jsonEncode(lesson)) as Json;
    (bad['questions'] as List).first['grading_spec'] = {'expected': 'b'};
    expect(
      () => repo.checked(bad, 'attempt'),
      throwsA(isA<InvalidApiResponseException>()),
    );
  });
  test('six-grade catalogue rejects unsupported or duplicate grades', () {
    final repo = WorldHistoryRepository(dio);
    for (final grades in [
      <int>[],
      [6, 6],
      [5, 6],
      [6, 12],
      [7],
    ]) {
      expect(
        () => repo.checked({...catalog, 'available_grades': grades}, 'catalog'),
        throwsA(isA<InvalidApiResponseException>()),
      );
    }
  });
  for (final dark in [false, true]) {
    testWidgets(
      'history path chapters and bibliography ${dark ? 'dark' : 'light'} at200%',
      (t) async {
        await mount(t, dark: dark, scale: 2, size: const Size(320, 568));
        expect(
          find.byKey(const ValueKey('world_history-grade-11')),
          findsOneWidget,
        );
        expect(find.text('46/46 dars mavjud.'), findsOneWidget);
        expect(find.byType(ExpansionTile), findsNWidgets(7));
        await capture(t, 'path-${dark ? 'dark' : 'light'}-200');
        await tapFinder(
          t,
          find.byKey(const ValueKey('history-bibliography-6')),
        );
        expect(find.textContaining('978-9943-382-89-3'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('changing grade keeps source-only pending catalogue explicit', (
    t,
  ) async {
    await mount(t);
    await tapFinder(t, find.byKey(const ValueKey('world_history-grade-8')));
    expect(requests.last.queryParameters['grade'], 8);
    expect(find.text('Jahon tarixi · 8-sinf'), findsWidgets);
    expect(find.text('Darsni boshlash'), findsNothing);
    expect(find.text('Dars tayyorlanmoqda'), findsWidgets);
    expect(t.takeException(), isNull);
  });
  testWidgets('finished grade6 can switch to the grade7 catalogue', (t) async {
    catalog = fixture('batch09_completed_catalog');
    expect(catalog['grade_content_complete'], true);
    expect(catalog['course_complete'], false);
    await mount(t);
    await tapFinder(t, find.byKey(const ValueKey('world_history-grade-7')));
    expect(requests.last.queryParameters['grade'], 7);
    expect(find.text('Jahon tarixi · 7-sinf'), findsWidgets);
    expect(find.text('15/44 dars mavjud.'), findsOneWidget);
    expect(find.text('Darsni boshlash'), findsWidgets);
    await tapFinder(
      t,
      find.byKey(const ValueKey('history-chapter-7-wh7-chapter03')),
    );
    expect(find.text('Dars tayyorlanmoqda'), findsWidgets);
    expect(t.takeException(), isNull);
  });
  testWidgets('source sheet shows real bibliography and no PDF image', (
    t,
  ) async {
    await mount(t);
    await tap(t, 'Darsni boshlash');
    await tapFinder(t, find.textContaining('Manba: Kirish').first);
    expect(find.textContaining('2017'), findsWidgets);
    expect(
      find.textContaining('qadimgi_dunyo_tarixi_6_uzb.pdf'),
      findsOneWidget,
    );
    expect(find.textContaining('Kitobdagi bet:'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'real wrong answer uses shared compact feedback without overflow',
    (t) async {
      await mount(t, size: const Size(320, 568), scale: 2, dark: true);
      await begin(t);
      await tap(t, 'Etnograf');
      await tap(t, 'Tekshirish');
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      await capture(t, 'feedback-dark-320-200');
      final explanation = find.text(
        'Arxeolog qadimgi manzilgohlarni qazib o‘rganadi.',
      );
      await t.ensureVisible(explanation);
      await t.pumpAndSettle();
      await capture(t, 'feedback-explanation-dark-320-200');
      expect(explanation, findsOneWidget);
      expect((requests.last.data as Map)['answer'], {'choice_id': 'a'});
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('FRQ drafts save and resume under account and API origin', (
    t,
  ) async {
    skip(10);
    final prefs = await mount(t);
    await begin(t);
    final field = find.byKey(const Key('world-history-short-answer'));
    await t.enterText(field, 'Antropolog');
    await t.pumpAndSettle();
    await tapFinder(t, find.byIcon(Icons.arrow_back));
    await tap(t, 'Saqlab chiqish');
    await tap(t, 'Darsni boshlash');
    expect(t.widget<TextField>(field).controller!.text, 'Antropolog');
    final rawPrefs = await SharedPreferences.getInstance();
    final prefix = rawPrefs.getKeys().where(
      (k) => k.startsWith('world_history_v2:'),
    );
    expect(prefix.length, 1);
    committed.clear();
    await mount(t, prefs: prefs, uid: 900007);
    await tap(t, 'Darsni boshlash');
    expect(find.byKey(const Key('world-history-short-answer')), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'lost submission retries same request without client grading flags',
    (t) async {
      skip(10);
      await mount(t);
      await begin(t);
      await t.enterText(
        find.byKey(const Key('world-history-short-answer')),
        'Antropolog',
      );
      lostAnswer = true;
      await tap(t, 'Tekshirish');
      await tap(t, 'Qayta yuborish');
      final sends = requests.where((r) => r.path.endsWith('/answers')).toList();
      expect(sends.length, 2);
      expect(sends[0].data, sends[1].data);
      expect((sends.last.data as Map).keys.toSet(), {
        'assessment_version',
        'assessment_key',
        'answer',
      });
    },
  );
  testWidgets('ungraded reflection precedes authoritative completion and XP', (
    t,
  ) async {
    skip(14);
    await mount(t);
    await begin(t);
    expect(find.text('Dalillarni solishtiring'), findsOneWidget);
    expect(find.textContaining('Avtomatik ball berilmaydi.'), findsOneWidget);
    await capture(t, 'reflection');
    await tap(t, 'Natijani saqlash');
    expect(requests.last.path, endsWith('/complete'));
    expect((requests.last.data as Map).keys.toSet(), {'assessment_version'});
    expect(find.textContaining('20'), findsWidgets);
    expect(t.takeException(), isNull);
  });
  for (final language in ['ru', 'en']) {
    testWidgets('$language interface keeps original reviewed Uzbek content', (
      t,
    ) async {
      await mount(t, language: language);
      await tap(t, language == 'ru' ? 'Начать урок' : 'Start lesson');
      expect(find.text('Kursga kirish'), findsOneWidget);
      expect(
        find.text(
          language == 'ru' ? 'Язык урока: узбекский' : 'Lesson language: Uzbek',
        ),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  }
  Future<void> openGrade7(WidgetTester t) async {
    await tapFinder(t, find.byKey(const ValueKey('world_history-grade-7')));
    final unit = jsonRows(
      grade7Catalog['source_units'],
    ).firstWhere((u) => u['title'] == lesson['title']);
    final chapter = unit['chapter_id'];
    if (chapter != 'wh7-chapter01') {
      await tapFinder(t, find.byKey(ValueKey('history-chapter-7-$chapter')));
    }
    final item = find
        .ancestor(
          of: find.text(lesson['title'] as String),
          matching: find.byType(Column),
        )
        .first;
    await tapFinder(
      t,
      find.descendant(of: item, matching: find.text('Darsni takrorlash')),
    );
  }

  for (var number = 1; number <= 15; number++) {
    void selectGrade7Lesson() {
      final suffix = number.toString().padLeft(2, '0');
      lesson = fixture('g7_p${suffix}_lesson');
      results = fixture('g7_p${suffix}_results');
      grade7Catalog = fixture(
        number >= 11
            ? 'batch12_grade7_completed_catalog'
            : number >= 6
            ? 'batch11_grade7_completed_catalog'
            : 'batch10_grade7_completed_catalog',
      );
    }

    testWidgets('grade7 paragraph$number theory and MCQ at200%', (t) async {
      selectGrade7Lesson();
      await mount(t, size: const Size(320, 568), scale: 2, dark: number.isEven);
      await openGrade7(t);
      expect(find.text('Jahon tarixi · 7-sinf'), findsWidgets);
      await capture(t, 'grade7-paragraph$number-theory-200');
      final cards = jsonRows((lesson['content'] as Json)['cards']);
      for (var i = 0; i < cards.length - 1; i++) {
        await tap(t, 'Davom etish');
      }
      await tap(t, 'Mashqlarga o‘tish');
      final q = jsonRows(lesson['questions']).first;
      final answer = (results['answers'] as Map)[q['key']] as Map;
      await tap(t, answer['correct_answer'] as String);
      await tap(t, 'Tekshirish');
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      await capture(t, 'grade7-paragraph$number-feedback-200');
      expect(t.takeException(), isNull);
    });
    testWidgets('grade7 paragraph$number FRQ uses its own snapshot', (t) async {
      selectGrade7Lesson();
      final questions = jsonRows(lesson['questions']);
      final firstFrq = questions.indexWhere(
        (q) => q['response_kind'] == 'short_text',
      );
      skip(firstFrq);
      await mount(t);
      await openGrade7(t);
      final q = questions[firstFrq];
      final answer = (results['answers'] as Map)[q['key']] as Map;
      await capture(t, 'grade7-paragraph$number-frq-resume');
      await t.scrollUntilVisible(
        find.byKey(const Key('world-history-short-answer')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await t.enterText(
        find.byKey(const Key('world-history-short-answer')),
        answer['correct_answer'] as String,
      );
      await tap(t, 'Tekshirish');
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      expect((requests.last.data as Map)['answer'], {
        'value': answer['correct_answer'],
      });
      expect(
        (requests.last.data as Map)['assessment_key'],
        startsWith('world-history-7-'),
      );
      expect(t.takeException(), isNull);
    });
    if (number == 1) {
      testWidgets('grade7 introduction retains its own bibliography', (
        t,
      ) async {
        selectGrade7Lesson();
        await mount(t, size: const Size(320, 568), scale: 2);
        await openGrade7(t);
        await tapFinder(t, find.textContaining('Manba: Kirish').first);
        expect(find.textContaining('jahon_tarixi_7_uzb.pdf'), findsOneWidget);
        expect(find.textContaining('Salimov'), findsWidgets);
        await capture(t, 'grade7-introduction-source-200');
        expect(t.takeException(), isNull);
      });
    }
    if (number == 5) {
      testWidgets(
        'grade7 draft survives remount without using a grade6 request',
        (t) async {
          selectGrade7Lesson();
          final questions = jsonRows(lesson['questions']);
          skip(questions.indexWhere((q) => q['response_kind'] == 'short_text'));
          final prefs = await mount(t);
          await openGrade7(t);
          await t.scrollUntilVisible(
            find.byKey(const Key('world-history-short-answer')),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await t.enterText(
            find.byKey(const Key('world-history-short-answer')),
            'Genrix I',
          );
          await t.pumpAndSettle();
          final first = requests.lastWhere((r) => r.path.endsWith('/start'));
          await t.pumpWidget(const SizedBox.shrink());
          await mount(t, prefs: prefs);
          await openGrade7(t);
          final last = requests.lastWhere((r) => r.path.endsWith('/start'));
          expect(
            (first.data as Map)['request_id'],
            (last.data as Map)['request_id'],
          );
          expect(last.path, contains('world-history-7-p05-r1'));
          final input = t.widget<TextField>(
            find.byKey(const Key('world-history-short-answer')),
          );
          expect(input.controller!.text, 'Genrix I');
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  for (var number = 2; number <= 46; number++) {
    void selectParagraph() {
      final suffix = number.toString().padLeft(2, '0');
      lesson = fixture('p${suffix}_lesson');
      results = fixture('p${suffix}_results');
      catalog = fixture(
        number >= 42
            ? 'batch09_completed_catalog'
            : number >= 37
            ? 'batch08_completed_catalog'
            : number >= 32
            ? 'batch07_completed_catalog'
            : number >= 27
            ? 'batch06_completed_catalog'
            : number >= 22
            ? 'batch05_completed_catalog'
            : number >= 17
            ? 'batch04_completed_catalog'
            : number >= 12
            ? 'batch03_completed_catalog'
            : number >= 7
            ? 'batch02_completed_catalog'
            : 'batch01_completed_catalog',
      );
    }

    Future<void> openParagraph(WidgetTester t) async {
      final unit = jsonRows(
        catalog['source_units'],
      ).singleWhere((u) => u['sequence'] == number);
      final chapter = unit['chapter_id'];
      if (chapter != jsonRows(catalog['chapters']).first['id']) {
        await tapFinder(t, find.byKey(ValueKey('history-chapter-6-$chapter')));
      }
      final item = find
          .ancestor(
            of: find.text(lesson['title'] as String),
            matching: find.byType(Column),
          )
          .first;
      await tapFinder(
        t,
        find.descendant(of: item, matching: find.text('Darsni takrorlash')),
      );
    }

    if (number >= 45) {
      testWidgets(
        'ancillary unit$number keeps its real title and source page',
        (t) async {
          selectParagraph();
          await mount(t, size: const Size(320, 568), scale: 2);
          await openParagraph(t);
          final title = number == 45 ? 'Xulosa' : 'Yakuniy takrorlash';
          expect(find.textContaining('§$number'), findsNothing);
          await tapFinder(t, find.textContaining('Manba: $title').first);
          expect(
            find.textContaining('qadimgi_dunyo_tarixi_6_uzb.pdf'),
            findsOneWidget,
          );
          expect(find.textContaining('Kitobdagi bet:'), findsOneWidget);
          await capture(t, 'unit$number-source-200');
          expect(t.takeException(), isNull);
        },
      );
    }

    testWidgets('real paragraph$number theory and MCQ at200%', (t) async {
      selectParagraph();
      await mount(t, size: const Size(320, 568), scale: 2, dark: number.isEven);
      await openParagraph(t);
      await capture(t, 'paragraph$number-theory-200');
      final cards = jsonRows((lesson['content'] as Json)['cards']);
      for (var i = 0; i < cards.length - 1; i++) {
        await tap(t, 'Davom etish');
      }
      await tap(t, 'Mashqlarga o‘tish');
      final q = jsonRows(lesson['questions']).first;
      final answer = (results['answers'] as Map)[q['key']] as Map;
      await tap(t, answer['correct_answer'] as String);
      await tap(t, 'Tekshirish');
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      await capture(t, 'paragraph$number-feedback-200');
      expect(t.takeException(), isNull);
    });
    testWidgets('real paragraph$number objective FRQ keeps server-owned key', (
      t,
    ) async {
      selectParagraph();
      final questions = jsonRows(lesson['questions']);
      final firstFrq = questions.indexWhere(
        (q) => q['response_kind'] == 'short_text',
      );
      skip(firstFrq);
      await mount(t);
      await openParagraph(t);
      final q = questions[firstFrq];
      final answer = (results['answers'] as Map)[q['key']] as Map;
      await capture(t, 'paragraph$number-frq-resume');
      await t.scrollUntilVisible(
        find.byKey(const Key('world-history-short-answer')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const Key('world-history-short-answer')),
        answer['correct_answer'] as String,
      );
      await tap(t, 'Tekshirish');
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      final body = requests.last.data as Map;
      expect(body['answer'], {'value': answer['correct_answer']});
      expect(body.keys.toSet(), {
        'assessment_version',
        'assessment_key',
        'answer',
      });
      expect(t.takeException(), isNull);
    });
  }
}
