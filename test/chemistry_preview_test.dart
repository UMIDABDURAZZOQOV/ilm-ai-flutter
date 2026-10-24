// Public payloads captured from the real, isolated Chemistry API. No live HTTP.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/chemistry_preview.dart';
import 'package:ilm_ai_flutter/core/network/api_contract.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/chemistry/data/chemistry_repository.dart';
import 'package:ilm_ai_flutter/features/chemistry/presentation/chemistry_preview_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_feedback_panel.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_completion_view.dart';
import 'release_hardening_test.dart' show Adapter, reply;
import 'support/load_review_fonts.dart';

Json fixture(String name) =>
    jsonDecode(File('test/fixtures/chemistry_$name.json').readAsStringSync())
        as Json;
const _capture = Key('chemistry-review');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadReviewFonts);
  late Dio dio;
  late Json lesson, results, catalog;
  late List<RequestOptions> requests;
  final committed = <String, Json>{};
  bool lostAnswer = false, offline = false, expired = false;
  setUp(() {
    lesson = fixture('lesson');
    results = fixture('results');
    catalog = fixture('catalog');
    requests = [];
    committed.clear();
    lostAnswer = false;
    offline = false;
    expired = false;
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8897'))
      ..httpClientAdapter = Adapter((r) {
        requests.add(r);
        if (offline) {
          throw DioException(
            requestOptions: r,
            type: DioExceptionType.connectionError,
          );
        }
        if (r.path.endsWith('/catalog')) return reply(200, catalog);
        if (r.path.endsWith('/start')) {
          return expired
              ? reply(409, {'detail': 'attempt_expired'})
              : reply(200, {...lesson, 'answers': Map.of(committed)});
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
    int uid = 900003,
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
          chemistryRepositoryProvider.overrideWithValue(
            ChemistryRepository(dio),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(dark ? darkColors : lightColors),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: const RepaintBoundary(
              key: _capture,
              child: ChemistryPreviewScreen(),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return store;
  }

  Future<void> tapFinder(WidgetTester t, Finder f) async {
    await t.pumpAndSettle();
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String text) =>
      tapFinder(t, find.text(text).first);

  Future<void> begin(WidgetTester t) async {
    await tap(t, 'Darsni boshlash');
    for (var i = 0; i < 7; i++) {
      await tap(t, 'Davom etish');
    }
    await tap(t, 'Mashqlarga o‘tish');
  }

  void skip(int count) {
    final answers = results['answers'] as Map;
    for (final q in jsonRows(lesson['questions']).take(count)) {
      committed[q['key'] as String] = Map<String, dynamic>.from(
        answers[q['key']] as Map,
      );
    }
  }

  void useReviewedLesson(String name) {
    lesson = fixture('${name}_lesson');
    results = fixture('${name}_results');
    catalog['lessons'] = [
      {
        ...jsonRows(catalog['lessons']).first,
        'key': lesson['lesson_key'],
        'title': lesson['title'],
        'sequence': {
          'numeric': 6,
          'formula': 12,
          'equation': 15,
          'context': 18,
          'review': 19,
          'practical': 3,
          'water': 31,
          'concentration': 36,
        }[name]!,
        'source_refs': (lesson['content'] as Json)['source_refs'],
      },
    ];
  }

  Future<void> capture(WidgetTester t, String name) async {
    if (!const bool.fromEnvironment('CHEMISTRY_CAPTURE')) return;
    await t.pumpAndSettle();
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(_capture),
    );
    await t.runAsync(() async {
      final picture = await boundary.toImage(pixelRatio: 1);
      final bytes = (await picture.toByteData(format: ui.ImageByteFormat.png))!;
      final directory = Directory('build/chemistry-review')
        ..createSync(recursive: true);
      File(
        '${directory.path}/$name.png',
      ).writeAsBytesSync(bytes.buffer.asUint8List());
      picture.dispose();
    });
  }

  test('preview is disabled by default and permits only explicit loopback', () {
    expect(chemistryPreview, false);
    expect(chemistryPreviewAllowed('http://127.0.0.1:8897'), false);
    for (final u in ['http://127.0.0.1:8897', 'http://localhost:8897']) {
      expect(chemistryPreviewAllowed(u, enabled: true), true);
    }
    for (final u in [
      'https://ilm-ai.onrender.com',
      'http://192.168.1.2',
      'http://10.0.2.2',
      'https://user:secret@localhost',
      'http://localhost?token=x',
    ]) {
      expect(chemistryPreviewAllowed(u, enabled: true), false);
    }
    expect(
      ChemistryRepository.requestId(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
  test('public first paragraph has no private rubric or AI output', () {
    final raw = jsonEncode(lesson);
    for (final key in [
      'grading_spec',
      'expected',
      'aliases',
      'correct_answer',
      'verified_answer',
    ]) {
      expect(raw, isNot(contains('"$key"')));
    }
    expect(jsonRows(lesson['questions']).length, 12);
    expect(
      jsonRows(
        lesson['questions'],
      ).where((q) => q['response_kind'] == 'short_text').length,
      3,
    );
    expect(jsonRows((lesson['content'] as Json)['cards']).length, 8);
  });
  test('numeric API input has explicit units and no private grading data', () {
    final data = fixture('numeric_lesson');
    final repo = ChemistryRepository(dio);
    expect(repo.checked(data, 'attempt')['lesson_key'], 'chemistry-7-p04-r1');
    final q = jsonRows(
      data['questions'],
    ).firstWhere((q) => q['response_kind'] == 'numeric_value');
    expect(q['unit'], isA<String>());
    expect(jsonEncode(data), isNot(contains('"expected"')));
    q.remove('unit');
    data['questions'] = [q];
    expect(
      () => repo.checked(data, 'attempt'),
      throwsA(isA<InvalidApiResponseException>()),
    );
  });
  testWidgets(
    'numeric FRQ can submit a comma decimal using the common exercise flow',
    (t) async {
      useReviewedLesson('numeric');
      // Resume at the source-reviewed mass reference denominator question.
      for (final q in jsonRows(lesson['questions']).take(6)) {
        committed[q['key'] as String] = Map<String, dynamic>.from(
          (results['answers'] as Map)[q['key']] as Map,
        );
      }
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      expect(find.textContaining('FRQ'), findsOneWidget);
      await t.enterText(find.byType(TextField), '12,0');
      await t.pumpAndSettle();
      await tap(t, 'Tekshirish');
      final submitted = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((submitted.data as Map)['answer'], {'value': '12,0'});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  test(
    'repository fails closed on version, private keys and source mapping',
    () {
      final repo = ChemistryRepository(dio);
      expect(
        () => repo.checked({...lesson, 'assessment_version': 1}, 'attempt'),
        throwsA(isA<ApiCompatibilityException>()),
      );
      final bad = fixture('lesson');
      (bad['content'] as Map)['expected'] = 'secret';
      expect(
        () => repo.checked(bad, 'attempt'),
        throwsA(isA<InvalidApiResponseException>()),
      );
      final source = fixture('lesson');
      ((jsonRows((source['content'] as Json)['cards']).first['source_refs']
                      as List)
                  .first
              as Map)['regions'] =
          [];
      expect(
        () => repo.checked(source, 'attempt'),
        throwsA(isA<InvalidApiResponseException>()),
      );
    },
  );
  test(
    'real formula and equation payloads remain public and source linked',
    () {
      for (final name in ['formula', 'equation']) {
        final data = fixture('${name}_lesson');
        expect(ChemistryRepository(dio).checked(data, 'attempt'), isA<Map>());
        expect(
          jsonRows(
            data['questions'],
          ).any((q) => q['response_kind'] == 'chemical_$name'),
          isTrue,
        );
        expect(jsonEncode(data), isNot(contains('"grading_spec"')));
        expect(jsonEncode(data), isNot(contains('"expected"')));
      }
    },
  );
  for (final name in ['formula', 'equation']) {
    testWidgets('$name FRQ submits exact typed notation at200% text', (
      t,
    ) async {
      useReviewedLesson(name);
      skip(name == 'formula' ? 7 : 6);
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      final value = name == 'formula' ? 'P₂O₅' : 'O₂ + 2Mg → 2MgO';
      await t.enterText(find.byType(TextField), value);
      await t.pumpAndSettle();
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': value});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('a response for a different lesson cannot enter the exercise', (
    t,
  ) async {
    lesson = fixture('numeric_lesson');
    // The catalog/request still identifies paragraph01. Do not store or show a
    // mismatched lesson from an incompatible response under that draft key.
    await mount(t);
    await tap(t, 'Darsni boshlash');
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Nazariya 1/6'), findsNothing);
    expect(find.text('Nazariya 1/8'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('prior paragraph data retains its own source button and page', (
    t,
  ) async {
    useReviewedLesson('context');
    await mount(t, size: const Size(320, 568), scale: 2);
    await tap(t, 'Darsni boshlash');
    for (var i = 0; i < 4; i++) {
      await tap(t, 'Davom etish');
    }
    expect(find.textContaining('Manba: §10'), findsOneWidget);
    expect(find.textContaining('Manba: §15'), findsOneWidget);
    await t.ensureVisible(find.textContaining('Manba: §15'));
    await t.pumpAndSettle();
    await capture(t, 'context-source-groups');
    await tapFinder(t, find.textContaining('Manba: §10'));
    expect(find.textContaining('Kitobdagi bet: 34'), findsOneWidget);
    expect(find.textContaining('34 → PDF 18 · chap sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'chapter review source is named without a false paragraph or activity',
    (t) async {
      useReviewedLesson('review');
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      for (var i = 0; i < 4; i++) {
        await tap(t, 'Davom etish');
      }
      final source = find.textContaining('Manba: I bobga doir');
      expect(source, findsOneWidget);
      expect(find.textContaining('Amaliy null'), findsNothing);
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, 'review-source-kind');
      await tapFinder(t, source);
      expect(find.textContaining('47 → PDF 24 · o‘ng sahifa'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'practical source label is an activity rather than paragraph one',
    (t) async {
      useReviewedLesson('practical');
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      final source = find.textContaining('Manba: Amaliy 1');
      expect(source, findsOneWidget);
      expect(find.textContaining('Manba: §1'), findsNothing);
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, 'practical-source-kind');
      await tapFinder(t, source);
      expect(find.textContaining('Manba bo‘limi: Amaliy 1'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('water theory and original page remain readable at200% text', (
    t,
  ) async {
    useReviewedLesson('water');
    await mount(t, size: const Size(320, 568), scale: 2);
    await tap(t, 'Darsni boshlash');
    expect(find.text('Nazariya 1/10'), findsOneWidget);
    final source = find.textContaining('Manba: §27').first;
    await t.ensureVisible(source);
    await t.pumpAndSettle();
    await capture(t, 'water-theory-source');
    await tapFinder(t, source);
    expect(find.textContaining('80 → PDF 41 · chap sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('hydrate is a recognition MCQ with common source feedback', (
    t,
  ) async {
    useReviewedLesson('water');
    skip(3);
    await mount(t, size: const Size(320, 568), scale: 2, dark: true);
    await tap(t, 'Darsni boshlash');
    expect(find.byType(TextField), findsNothing);
    await tap(t, 'CuSO4·5H2O');
    await tap(t, 'Tekshirish');
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
    final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
    expect((request.data as Map)['answer'], {'choice_id': 'b'});
    expect(committed.values.last['is_correct'], true);
    final source = find.descendant(
      of: find.byType(LessonFeedbackPanel),
      matching: find.textContaining('Manba: §27'),
    );
    expect(source, findsOneWidget);
    await t.ensureVisible(source);
    await t.pumpAndSettle();
    await capture(t, 'water-hydrate-feedback');
    await tapFinder(t, source);
    expect(find.textContaining('82 → PDF 42 · chap sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('molar theory retains the prior molar-mass source at200%', (
    t,
  ) async {
    useReviewedLesson('concentration');
    await mount(t, size: const Size(320, 568), scale: 2);
    await tap(t, 'Darsni boshlash');
    for (var i = 0; i < 5; i++) {
      await tap(t, 'Davom etish');
    }
    expect(find.textContaining('Manba: §10'), findsOneWidget);
    expect(find.textContaining('Manba: §32'), findsOneWidget);
    await tapFinder(t, find.textContaining('Manba: §10'));
    expect(find.textContaining('34 → PDF 18 · chap sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('molar FRQ keeps its fixed unit and exact comma input at200%', (
    t,
  ) async {
    useReviewedLesson('concentration');
    skip(10);
    await mount(t, size: const Size(320, 568), scale: 2, dark: true);
    await tap(t, 'Darsni boshlash');
    expect(find.textContaining('mol/l'), findsWidgets);
    await t.enterText(find.byType(TextField), '0,4');
    await t.pumpAndSettle();
    await t.ensureVisible(find.textContaining('Birlik: mol/l'));
    await t.pumpAndSettle();
    await capture(t, 'molar-fixed-unit-input');
    await tap(t, 'Tekshirish');
    final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
    expect((request.data as Map)['answer'], {'value': '0,4'});
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
    final source = find.descendant(
      of: find.byType(LessonFeedbackPanel),
      matching: find.textContaining('Manba: §32'),
    );
    await t.ensureVisible(source);
    await t.pumpAndSettle();
    await capture(t, 'molar-source-feedback');
    await tapFinder(t, source);
    expect(find.textContaining('91 → PDF 46 · o‘ng sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('theory advances one card and sources resolve spread sides', (
    t,
  ) async {
    await mount(t);
    await tap(t, 'Darsni boshlash');
    expect(find.text('Nazariya 1/8'), findsOneWidget);
    expect(
      find.text(
        jsonRows((lesson['content'] as Json)['cards'])[1]['title'] as String,
      ),
      findsNothing,
    );
    await tap(t, 'Davom etish');
    expect(find.text('Nazariya 2/8'), findsOneWidget);
    final source = find.textContaining('Manba:').first;
    await t.ensureVisible(source);
    await t.tap(source);
    await t.pumpAndSettle();
    expect(find.text('kimyo_7_uzb.pdf'), findsOneWidget);
    expect(find.textContaining('→ PDF 3 · chap sahifa'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'completed lesson action accurately describes reopening on a new device',
    (t) async {
      (catalog['lessons'] as List).first['state'] = 'completed';
      await mount(t);
      expect(find.text('Darsni takrorlash'), findsOneWidget);
      await tap(t, 'Darsni takrorlash');
      expect(find.text('Nazariya 1/8'), findsOneWidget);
      expect(find.byType(LessonCompletionView), findsNothing);
    },
  );
  testWidgets('server MCQ feedback uses common panel and completion view', (
    t,
  ) async {
    await mount(t);
    await begin(t);
    await tap(
      t,
      jsonRows(jsonRows(lesson['questions']).first['options']).first['label']
          as String,
    );
    await tap(t, 'Tekshirish');
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
    expect(committed.values.first['is_correct'], false);
    final payload = requests.last.data as Map;
    expect(payload.keys.toSet(), {
      'assessment_version',
      'assessment_key',
      'answer',
    });
    expect((payload['answer'] as Map).keys.toSet(), {'choice_id'});
    await tap(t, 'Davom etish');
    expect(find.text('2/12 · MCQ'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('FRQ input is sent to server without client correctness or XP', (
    t,
  ) async {
    skip(9);
    await mount(t);
    await tap(t, 'Darsni boshlash');
    expect(find.text('10/12 · FRQ'), findsOneWidget);
    final field = find.byKey(const Key('chemistry-short-answer'));
    await t.ensureVisible(field);
    await t.enterText(field, '  KIMYO FANI. ');
    await tap(t, 'Tekshirish');
    final answer = requests.last.data as Map;
    expect(answer['answer'], {'value': '  KIMYO FANI. '});
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('lost answer freezes payload and retry is byte-equivalent', (
    t,
  ) async {
    skip(9);
    await mount(t);
    await tap(t, 'Darsni boshlash');
    final field = find.byKey(const Key('chemistry-short-answer'));
    await t.ensureVisible(field);
    await t.enterText(field, 'kimyo');
    lostAnswer = true;
    await tap(t, 'Tekshirish');
    expect(t.widget<TextField>(field).readOnly, true);
    final before = jsonEncode(requests.last.data);
    await tap(t, 'Qayta yuborish');
    expect(jsonEncode(requests.last.data), before);
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
  });
  testWidgets('saved text and request ID resume on same account only', (
    t,
  ) async {
    skip(9);
    final store = await mount(t);
    await tap(t, 'Darsni boshlash');
    final first = (requests.last.data as Map)['request_id'];
    final field = find.byKey(const Key('chemistry-short-answer'));
    await t.ensureVisible(field);
    await t.enterText(field, 'alkaloid');
    await t.pumpAndSettle();
    await t.pumpWidget(const SizedBox());
    await mount(t, prefs: store);
    await tap(t, 'Darsni boshlash');
    expect((requests.last.data as Map)['request_id'], first);
    expect(t.widget<TextField>(field).controller!.text, 'alkaloid');
    await t.pumpWidget(const SizedBox());
    await mount(t, prefs: store, uid: 900004);
    await tap(t, 'Darsni boshlash');
    expect((requests.last.data as Map)['request_id'], isNot(first));
    expect(t.widget<TextField>(field).controller!.text, isEmpty);
  });
  testWidgets('exit uses shared save dialog and returns to path', (t) async {
    await mount(t);
    await tap(t, 'Darsni boshlash');
    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    expect(find.text('Darsdan chiqasizmi?'), findsOneWidget);
    await tap(t, 'Saqlab chiqish');
    expect(find.text('Darsni boshlash'), findsOneWidget);
    await tap(t, 'Darsni boshlash');
    expect(find.text('Nazariya 1/8'), findsOneWidget);
  });
  testWidgets('expiry does not silently discard a saved attempt', (t) async {
    expired = true;
    await mount(t);
    await tap(t, 'Darsni boshlash');
    expect(find.textContaining('24 soatlik'), findsOneWidget);
    expect(find.text('Yangi urinish'), findsOneWidget);
    final old = (requests.last.data as Map)['request_id'];
    expired = false;
    await tap(t, 'Yangi urinish');
    expect((requests.last.data as Map)['request_id'], isNot(old));
  });
  testWidgets(
    'completed attempt uses common result and sourced answer review',
    (t) async {
      skip(12);
      lesson['result'] = results['result'];
      await mount(t);
      await tap(t, 'Darsni boshlash');
      expect(find.byType(LessonCompletionView), findsOneWidget);
      final result = t.widget<LessonCompletionView>(
        find.byType(LessonCompletionView),
      );
      expect(result.xp, 20);
      expect(result.correct, 11);
      result.onReview();
      await t.pumpAndSettle();
      expect(find.text('Javoblar'), findsOneWidget);
      expect(find.textContaining('Manba:'), findsWidgets);
      expect(t.takeException(), isNull);
    },
  );

  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'small and landscape 200% text $lang ${dark ? 'dark' : 'light'}',
        (t) async {
          skip(9);
          await mount(
            t,
            language: lang,
            dark: dark,
            scale: 2,
            size: const Size(320, 568),
          );
          await tap(
            t,
            lang == 'uz'
                ? 'Darsni boshlash'
                : lang == 'ru'
                ? 'Начать урок'
                : 'Start lesson',
          );
          final field = find.byKey(const Key('chemistry-short-answer'));
          await t.ensureVisible(field);
          await t.enterText(field, 'kimyo');
          await tap(
            t,
            lang == 'uz'
                ? 'Tekshirish'
                : lang == 'ru'
                ? 'Проверить'
                : 'Check',
          );
          expect(find.byType(LessonFeedbackPanel), findsOneWidget);
          expect(t.takeException(), isNull);
          t.view.physicalSize = const Size(640, 360);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  for (final dark in [false, true]) {
    testWidgets(
      'review captures ${dark ? 'dark' : 'light'} theory MCQ FRQ feedback and result',
      (t) async {
        final mode = dark ? 'dark' : 'light';
        final store = await mount(t, dark: dark);
        await tap(t, 'Darsni boshlash');
        await capture(t, 'theory-$mode');
        for (var i = 0; i < 7; i++) {
          await tap(t, 'Davom etish');
        }
        await tap(t, 'Mashqlarga o‘tish');
        await capture(t, 'mcq-$mode');
        await tap(
          t,
          jsonRows(
                jsonRows(lesson['questions']).first['options'],
              ).first['label']
              as String,
        );
        await tap(t, 'Tekshirish');
        await capture(t, 'feedback-$mode');
        skip(9);
        await t.pumpWidget(const SizedBox());
        await mount(t, dark: dark, prefs: store);
        await tap(t, 'Darsni boshlash');
        await capture(t, 'frq-$mode');
        skip(12);
        lesson['result'] = results['result'];
        await t.pumpWidget(const SizedBox());
        await mount(t, dark: dark, prefs: store);
        await tap(t, 'Darsni boshlash');
        await capture(t, 'result-$mode');
        expect(t.takeException(), isNull);
      },
    );
  }
}
