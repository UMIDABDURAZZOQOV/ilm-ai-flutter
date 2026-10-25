import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show SemanticsAction;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/physics_preview.dart';
import 'package:ilm_ai_flutter/core/network/api_contract.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/physics/data/physics_repository.dart';
import 'package:ilm_ai_flutter/features/physics/presentation/physics_preview_screen.dart';
import 'package:ilm_ai_flutter/features/physics/presentation/physics_answer_editor.dart';
import 'release_hardening_test.dart' show Adapter, reply;

Json fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Json;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late List<RequestOptions> requests;
  late Json lesson, results;
  bool offline = false, lostAnswer = false, lostComplete = false;
  bool multipleGrades = false;
  final committed = <String, Json>{};
  setUp(() {
    requests = [];
    committed.clear();
    offline = false;
    lostAnswer = false;
    lostComplete = false;
    multipleGrades = false;
    lesson = fixture('physics_lesson6');
    results = fixture('physics_result6');
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'))
      ..httpClientAdapter = Adapter((request) {
        requests.add(request);
        if (offline) {
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          );
        }
        if (request.path.endsWith('/catalog')) {
          if (multipleGrades) {
            final grade = request.queryParameters['grade'] as int;
            return reply(200, {
              ...fixture('physics_catalog'),
              'grade': grade,
              'available_grades': [6, 7],
              if (grade == 7) 'lessons': <Json>[],
              'book': {
                'grade': grade,
                'title': 'Fizika. $grade-sinf uchun darslik',
                'authors': [
                  grade == 7 ? 'P. Q. Habibullayev' : 'N. Sh. Turdiyev',
                ],
                'publisher': grade == 7
                    ? 'O‘zbekiston milliy ensiklopediyasi'
                    : 'Niso Poligraf',
                'year': 2017,
              },
            });
          }
          return reply(200, fixture('physics_catalog'));
        }
        if (request.path.endsWith('/start')) {
          return reply(200, {...lesson, 'answers': Map.of(committed)});
        }
        if (request.path.endsWith('/answers')) {
          final data = Map<String, dynamic>.from(request.data as Map),
              key = data['assessment_key'] as String;
          final response = Map<String, dynamic>.from(
            (results['answers'] as Map)[key] as Map,
          );
          committed[key] = response;
          if (lostAnswer) {
            lostAnswer = false;
            throw DioException(
              requestOptions: request,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return reply(200, response);
        }
        if (request.path.endsWith('/complete')) {
          if (lostComplete) {
            lostComplete = false;
            throw DioException(
              requestOptions: request,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return reply(200, results['result']);
        }
        throw StateError('Unexpected request ${request.path}');
      });
  });
  tearDown(() => dio.close(force: true));

  Future<PrefsService> mount(
    WidgetTester tester, {
    double scale = 1,
    Widget? child,
    PrefsService? prefs,
    int uid = 900002,
  }) async {
    if (prefs == null) SharedPreferences.setMockInitialValues({});
    final store = prefs ?? await PrefsService.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsServiceProvider.overrideWithValue(store),
          currentUserIdProvider.overrideWithValue(uid),
          physicsRepositoryProvider.overrideWithValue(PhysicsRepository(dio)),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child ?? const PhysicsPreviewScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return store;
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text).first;
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, {int n = 6}) async {
    final finder = find.text('§$n. ${lesson['title']}');
    await tester.ensureVisible(finder);
    await tester.pump();
    final card = find.ancestor(of: finder, matching: find.byType(Card)).first;
    final button = find.descendant(
      of: card,
      matching: find.text('Qayta ko‘rish'),
    );
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> begin(WidgetTester tester) async {
    await open(tester);
    await tap(tester, 'Mashqlarga o‘tish');
  }

  Future<void> choose(WidgetTester tester, int q, int option) async {
    final data = jsonRows(lesson['questions'])[q];
    await tap(tester, jsonRows(data['options'])[option]['label'] as String);
    await tap(tester, 'Tekshirish');
    await tap(tester, 'Davom etish');
  }

  Future<void> enter(
    WidgetTester tester,
    String formula,
    String value,
    String unit,
  ) async {
    for (final pair in [
      ('physics-formula', formula),
      ('physics-value', value),
      ('physics-unit', unit),
    ]) {
      final field = find.byKey(Key(pair.$1));
      await tester.ensureVisible(field);
      await tester.pump();
      await tester.enterText(field, pair.$2);
    }
    await tester.pump();
  }

  test('preview requires an explicit flag and a local/private API host', () {
    expect(physicsPreview, false);
    expect(physicsPreviewAllowed('http://127.0.0.1:8000'), false);
    for (final url in [
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000',
      'http://192.168.1.5:8000',
      'http://172.16.0.2:8000',
    ]) {
      expect(physicsPreviewAllowed(url, enabled: true), true);
    }
    for (final url in [
      'https://ilm-ai.onrender.com',
      'http://172.32.0.1',
      'http://192.168.1.999',
      'http://local.example',
      'https://user:secret@localhost',
    ]) {
      expect(physicsPreviewAllowed(url, enabled: true), false);
    }
    expect(
      PhysicsRepository.requestId(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  testWidgets('grade selection requests its own catalog and bibliography', (
    tester,
  ) async {
    multipleGrades = true;
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, scale: 2);
    final picker = find.byKey(const ValueKey('physics-grade-6'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('7-sinf').last);
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['grade'], 7);
    expect(find.text('Fizika • 7-sinf'), findsOneWidget);
    expect(find.textContaining('P. Q. Habibullayev'), findsOneWidget);
    expect(find.textContaining('N. Sh. Turdiyev'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('v2 fixtures contain no rubric or private expected answer', () {
    final content = jsonEncode(lesson);
    for (final key in [
      'grading_spec',
      'expected_si',
      'expected_choice',
      'expected_order',
      'equivalents',
      'abs_tol_si',
    ]) {
      expect(content, isNot(contains('"$key"')));
    }
    expect(lesson['assessment_version'], 2);
    expect(jsonRows(lesson['questions']).length, 7);
    expect(jsonRows((lesson['content'] as Json)['formulas']).length, 2);
  });

  test(
    'repository rejects unsupported response version and never sends correctness/XP',
    () async {
      dio.httpClientAdapter = Adapter(
        (request) => reply(200, {'assessment_version': 1}),
      );
      final repo = PhysicsRepository(dio);
      expect(
        () => repo.start('key', PhysicsRepository.requestId(), CancelToken()),
        throwsA(isA<ApiCompatibilityException>()),
      );
    },
  );

  testWidgets(
    'conceptual lesson shows sourced cards and no invented formula editor',
    (tester) async {
      lesson = fixture('physics_lesson1');
      results = fixture('physics_result1');
      await mount(tester);
      await open(tester, n: 1);
      expect(find.text('Tabiatdagi o‘zgarishlar'), findsOneWidget);
      expect(find.byKey(const Key('physics-formula')), findsNothing);
      await tap(tester, 'Manba sahifalari');
      expect(find.textContaining('PDF sahifalari: 3, 4'), findsOneWidget);
      await tap(tester, 'Yopish');
      await tap(tester, 'Mashqlarga o‘tish');
      expect(
        find.text(
          'Velosipedning yo‘lda yurishida qaysi hodisa bevosita kuzatiladi?',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('physics-formula')), findsNothing);
      await choose(tester, 0, 0);
      expect(committed.length, 1);
    },
  );

  testWidgets(
    'numeric answer includes formula number and unit; full lesson result is server authoritative',
    (tester) async {
      await mount(tester);
      await begin(tester);
      await choose(tester, 0, 0);
      await choose(tester, 1, 1);
      await enter(tester, 'y=x*100', '170', 'cm');
      await tap(tester, 'Tekshirish');
      expect(find.text('To‘g‘ri!'), findsOneWidget);
      final sent =
          requests.lastWhere((r) => r.path.endsWith('/answers')).data as Map;
      expect(sent['answer'], {
        'formula': 'y=x*100',
        'value': '170',
        'unit': 'cm',
      });
      expect(sent.keys, isNot(contains('is_correct')));
      expect(sent.keys, isNot(contains('xp')));
      await tap(tester, 'Davom etish');
      await enter(tester, 'x/1000', '0,46', 'm');
      await tap(tester, 'Tekshirish');
      await tap(tester, 'Davom etish');
      await choose(tester, 4, 0);
      await choose(tester, 5, 1);
      await choose(tester, 6, 2);
      lostComplete = true;
      await tap(tester, 'Natijani saqlash');
      expect(find.textContaining('So‘rov vaqti tugadi'), findsOneWidget);
      await tap(tester, 'Natijani saqlash');
      expect(find.text('Dars yakunlandi!'), findsOneWidget);
      expect(find.textContaining('+10 XP'), findsOneWidget);
      final calls = requests
          .where((r) => r.path.endsWith('/complete'))
          .toList();
      expect(calls.length, 2);
      expect(calls[0].data, calls[1].data);
      expect(calls[0].path, calls[1].path);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lost answer response freezes exact payload through retry and duplicate tap',
    (tester) async {
      await mount(tester);
      await begin(tester);
      await choose(tester, 0, 0);
      await choose(tester, 1, 1);
      await enter(tester, '100*x', '170', 'cm');
      lostAnswer = true;
      await tap(tester, 'Tekshirish');
      expect(find.textContaining('So‘rov vaqti tugadi'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('physics-value')))
            .enabled,
        false,
      );
      final old = requests.lastWhere((r) => r.path.endsWith('/answers'));
      await tap(tester, 'Qayta yuborish');
      final retry = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect(retry.data, old.data);
      expect(retry.path, old.path);
      expect(find.text('To‘g‘ri!'), findsOneWidget);
    },
  );

  testWidgets(
    'restart restores request ID, draft and already committed answer after lost response',
    (tester) async {
      final prefs = await mount(tester);
      await begin(tester);
      await choose(tester, 0, 0);
      await choose(tester, 1, 1);
      await enter(tester, 'x*100', '170', 'cm');
      final request = requests.lastWhere((r) => r.path.endsWith('/start')).data;
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await mount(tester, prefs: prefs);
      await open(tester);
      expect(
        requests.lastWhere((r) => r.path.endsWith('/start')).data,
        request,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('physics-value')))
            .controller!
            .text,
        '170',
      );
      lostAnswer = true;
      await tap(tester, 'Tekshirish');
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await mount(tester, prefs: prefs);
      await open(tester);
      // Server committed question 3: resume at question 4, without replaying its feedback under question 4.
      expect(find.textContaining('Detal uzunligini metrda'), findsOneWidget);
      expect(find.text('Qayta yuborish'), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('physics-value')))
            .enabled,
        true,
      );
    },
  );

  testWidgets('offline catalog retry and dispose during request do not throw', (
    tester,
  ) async {
    offline = true;
    await mount(tester);
    expect(find.textContaining('Internetga ulanib'), findsOneWidget);
    offline = false;
    await tap(tester, 'Qayta urinish');
    expect(find.text('6-sinf • §1–7'), findsOneWidget);
    final pending = Completer<ResponseBody>();
    dio.httpClientAdapter = Adapter((_) => pending.future);
    final button = find.text('Qayta ko‘rish').first;
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    pending.complete(reply(200, lesson));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(640, 320)]) {
    testWidgets(
      'FRQ and long feedback fit $size with large text and Reduce Motion',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester, scale: 2);
        await begin(tester);
        await choose(tester, 0, 0);
        await choose(tester, 1, 1);
        await enter(tester, '100*x', '170', 'cm');
        await tap(tester, 'Tekshirish');
        await tester.ensureVisible(find.text('Davom etish'));
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'ordering uses explicit sequence input without deriving the answer locally',
    (tester) async {
      final q = jsonRows(fixture('physics_lesson5')['questions'])[1];
      Json? draft;
      await mount(
        tester,
        child: Scaffold(
          body: SingleChildScrollView(
            child: PhysicsAnswerEditor(
              question: q,
              draft: const {},
              enabled: true,
              onChanged: (d) => draft = d,
            ),
          ),
        ),
      );
      for (final label in ['Kuzatish', 'Gipoteza', 'Tajriba', 'Xulosa']) {
        await tap(tester, label);
      }
      expect(draft, {
        'order': ['s3', 's4', 's2', 's1'],
      });
      await tap(tester, 'Tartibni tozalash');
      expect(draft, {'order': <String>[]});
    },
  );
  test(
    'malformed v2 response is rejected before building an incomplete screen',
    () async {
      dio.httpClientAdapter = Adapter(
        (_) => reply(200, {'assessment_version': 2}),
      );
      expect(
        () => PhysicsRepository(dio).catalog(CancelToken()),
        throwsA(isA<InvalidApiResponseException>()),
      );
    },
  );

  testWidgets('double tap sends one answer while server request is pending', (
    tester,
  ) async {
    await mount(tester);
    await begin(tester);
    await tap(
      tester,
      jsonRows(jsonRows(lesson['questions'])[0]['options'])[0]['label']
          as String,
    );
    final original = dio.httpClientAdapter as Adapter;
    final pending = Completer<ResponseBody>();
    dio.httpClientAdapter = Adapter((request) {
      if (request.path.endsWith('/answers')) {
        requests.add(request);
        return pending.future;
      }
      return original.handle(request);
    });
    final button = find.text('Tekshirish');
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(requests.where((r) => r.path.endsWith('/answers')).length, 1);
    final key = jsonRows(lesson['questions'])[0]['key'];
    pending.complete(reply(200, (results['answers'] as Map)[key]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('To‘g‘ri!'), findsOneWidget);
  });

  testWidgets(
    'format feedback allows editing; account switch cannot restore another draft',
    (tester) async {
      final prefs = await mount(tester);
      await begin(tester);
      await choose(tester, 0, 0);
      await choose(tester, 1, 1);
      await enter(tester, '100*x', 'not-a-number', 'cm');
      final original = dio.httpClientAdapter as Adapter;
      var reject = true;
      dio.httpClientAdapter = Adapter((request) {
        if (request.path.endsWith('/answers') && reject) {
          reject = false;
          return reply(422, {
            'detail': {
              'code': 'invalid_expression',
              'feedback': 'Ifodani tekshir: faqat son va amallar yoz.',
            },
          });
        }
        return original.handle(request);
      });
      await tap(tester, 'Tekshirish');
      expect(find.textContaining('Ifodani tekshir'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('physics-value')))
            .enabled,
        true,
      );
      final old = requests.lastWhere((r) => r.path.endsWith('/start')).data;
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      committed.clear();
      await mount(tester, prefs: prefs, uid: 900003);
      await open(tester);
      expect(
        requests.lastWhere((r) => r.path.endsWith('/start')).data,
        isNot(old),
      );
      expect(find.text('Mashqlarga o‘tish'), findsOneWidget);
      await tap(tester, 'Mashqlarga o‘tish');
      await choose(tester, 0, 0);
      await choose(tester, 1, 1);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('physics-value')))
            .controller!
            .text,
        isEmpty,
      );
    },
  );
  testWidgets(
    'new sourced FRQs use quantity-specific units on a small large-text screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final questions = jsonRows(fixture('physics_batch2_frq')['questions']);
      for (final unit in [
        'kg/m3',
        'cm3',
        'g',
        'mm/s',
        'N',
        'Pa',
        'm2',
        's',
        'J',
        'W',
        'N*m',
        '%',
        'mV',
        'dptr',
        'Hz',
        'km',
      ]) {
        final q = questions.firstWhere(
          (q) => (q['unit_choices'] as List).contains(unit),
        );
        Json? edited;
        await mount(
          tester,
          scale: 2,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: PhysicsAnswerEditor(
                key: ValueKey(unit),
                question: q,
                draft: const {},
                enabled: true,
                onChanged: (v) => edited = v,
              ),
            ),
          ),
        );
        final chip = find.widgetWithText(ActionChip, unit);
        await tester.ensureVisible(chip);
        await tester.pump();
        await tester.tap(chip);
        await tester.pump();
        expect(edited?['unit'], unit);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'Physics action buttons expose an explicit label and accessibility tap',
    (tester) async {
      final handle = tester.ensureSemantics();
      await mount(tester);
      await open(tester);
      await tester.ensureVisible(find.text('Mashqlarga o‘tish'));
      await tester.pumpAndSettle();
      final target = find.bySemanticsLabel('Mashqlarga o‘tish');
      expect(target, findsOneWidget);
      expect(
        tester
            .getSemantics(target)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      handle.dispose();
    },
  );
  testWidgets(
    'grade7 public FRQs preserve independently entered drafts at 200 percent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final questions = jsonRows(fixture('physics_grade7_frq')['questions']);
      expect(questions, hasLength(112));
      for (final question in questions) {
        Json? edited;
        await mount(
          tester,
          scale: 2,
          child: Scaffold(
            body: SingleChildScrollView(
              child: PhysicsAnswerEditor(
                key: ValueKey(question['key']),
                question: question,
                draft: const {},
                enabled: true,
                onChanged: (v) => edited = v,
              ),
            ),
          ),
        );
        await enter(
          tester,
          'learner_formula',
          '-1,25',
          question['suggested_unit'] as String,
        );
        expect(edited?['formula'], 'learner_formula');
        expect(edited?['value'], '-1,25');
        expect(edited?['unit'], question['suggested_unit']);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'FRQ inputs have accessible labels and Android-sized tap targets',
    (tester) async {
      final semantics = tester.ensureSemantics();

      final question = jsonRows(lesson['questions'])[2];
      await mount(
        tester,
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: PhysicsAnswerEditor(
              question: question,
              draft: const {},
              enabled: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Formula')), findsWidgets);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    },
  );
}
