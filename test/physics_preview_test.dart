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
              'available_grades': [6, 7, 8, 9, 10],
              if (grade >= 7) 'lessons': <Json>[],
              'book': grade >= 8
                  ? fixture('physics_grade${grade}_book')
                  : {
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

  testWidgets(
    'grade8 selection uses source bibliography and its own API query',
    (tester) async {
      multipleGrades = true;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, scale: 2);
      final picker = find.byKey(const ValueKey('physics-grade-6'));
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('8-sinf').last);
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['grade'], 8);
      final book = fixture('physics_grade8_book');
      expect(
        find.textContaining((book['authors'] as List).first as String),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'grade9 selection uses source bibliography and its own API query',
    (tester) async {
      multipleGrades = true;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, scale: 2);
      final picker = find.byKey(const ValueKey('physics-grade-6'));
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('9-sinf').last);
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['grade'], 9);
      final book = fixture('physics_grade9_book');
      expect(
        find.textContaining((book['authors'] as List).first as String),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'grade10 selection uses source bibliography and its own API query',
    (tester) async {
      multipleGrades = true;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, scale: 2);
      final picker = find.byKey(const ValueKey('physics-grade-6'));
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('10-sinf').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('10-sinf').last);
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['grade'], 10);
      final book = fixture('physics_grade10_book');
      expect(
        find.textContaining((book['authors'] as List).first as String),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
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
  testWidgets(
    'four Carnot stages fit large text and preserve explicit learner order',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final question = fixture('physics_grade9_carnot_order');
      Json? draft;
      await mount(
        tester,
        scale: 2,
        child: Scaffold(
          body: SingleChildScrollView(
            child: PhysicsAnswerEditor(
              question: question,
              draft: const {},
              enabled: true,
              onChanged: (d) => draft = d,
            ),
          ),
        ),
      );
      for (final label in [
        'Th da izotermik kengayish',
        'Adiabatik kengayib Tc gacha sovish',
        'Tc da izotermik siqilish',
        'Adiabatik siqilib Th ga qaytish',
      ]) {
        await tap(tester, label);
      }
      expect(draft, {
        'order': ['s2', 's4', 's1', 's3'],
      });
      expect(tester.takeException(), isNull);
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
      expect(questions, hasLength(133));
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
  testWidgets('grade8 public FRQ and root notation drafts fit large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final questions = jsonRows(fixture('physics_grade8_frq')['questions']);
    expect(questions, hasLength(134));
    for (final question in questions) {
      Json? edited;
      final isRoot = question['key'] == 'physics-8-section-4-r1:q5';
      final isHeatRoot = question['key'] == 'physics-8-section-34-r1:q9';
      final formula = isRoot
          ? 'sqrt(F*r^2/k)'
          : (isHeatRoot ? 'sqrt(Q/(R*t))' : 'learner_formula');
      final value = isRoot ? '4' : (isHeatRoot ? '2' : '-1,25');
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
      await enter(tester, formula, value, question['suggested_unit'] as String);
      expect(edited?['formula'], formula);
      expect(edited?['value'], value);
      expect(edited?['unit'], question['suggested_unit']);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('grade9 public physics FRQ drafts fit large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final questions = jsonRows(fixture('physics_grade9_frq')['questions']);
    expect(questions, hasLength(205));
    for (final question in questions) {
      Json? edited;
      final draft = <String, (String, String)>{
        'physics-9-section-5-r1:q6': ('sqrt(3*p/rho)', '600'),
        'physics-9-section-7-r1:q5': ('sqrt(3*k*T/m0)', '643.4'),
        'physics-9-section-7-r1:q6': ('sqrt(3*R*T/M)', '499.3'),
        'physics-9-section-15-r1:q6': ('3*nu*R*(T2-T1)/2', '-3739.5'),
        'physics-9-section-16-r1:q9': ('A/p', '-0.004'),
        'physics-9-section-19-r1:q6': ('m*c*(T2-T1)', '-8400'),
        'physics-9-section-27-r1:q7': ('1-Tc/Th', '0,5'),
        'physics-9-section-30-r1:q7': ('eta*rho*V*q*v/s', '16100'),
        'physics-9-section-32-r1:q5': ('2*sigma/(rho*g*r)', '0.0149'),
        'physics-9-section-34-r1:q5': ('(F2-F1)/(2*l)', '0.073'),
        'physics-9-section-36-r1:q8': ('E*eps', '100000000'),
        'physics-9-section-39-r1:q8': ('-lam*m', '-66800'),
        'physics-9-section-40-r1:q7': ('-r*m', '-46000'),
        'physics-9-section-41-r1:q8': ('phi*rhoSat', '0.0138'),
        'physics-9-section-45-r1:q5': ('alpha', '35'),
        'physics-9-section-45-r1:q10': ('n1*sina/n2', '0.6'),
        'physics-9-section-50-r1:q5': ('1/F', '-5'),
        'physics-9-section-51-r1:q6': ('F*d/(d-F)', '-0.2'),
        'physics-9-section-53-r1:q7': ('3/(F1+F2+F3)', '5'),
      }[question['key']];
      final formula = draft?.$1 ?? 'learner_formula';
      final value = draft?.$2 ?? '-1,25';
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
      await enter(tester, formula, value, question['suggested_unit'] as String);
      expect(edited?['formula'], formula);
      expect(edited?['value'], value);
      expect(edited?['unit'], question['suggested_unit']);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('grade10 signed angular and vertical drafts fit large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final questions = jsonRows(fixture('physics_grade10_frq')['questions']);
    expect(questions, hasLength(136));
    for (final question in questions) {
      Json? edited;
      final draft = <String, (String, String)>{
        'physics-10-section-2-r1:q5': ('v1+v2', '-2'),
        'physics-10-section-6-r1:q5': ('sqrt(2*h/g)', '1.73'),
        'physics-10-section-7-r1:q6': ('v0*sinA-g*t', '-8'),
        'physics-10-section-10-r1:q6': ('-m*A', '-6'),
        'physics-10-section-11-r1:q6': ('T1*sqrt((r/R)^3)', '40000'),
        'physics-10-section-13-r1:q5': ('(Ft-Ff)/m', '-2'),
        'physics-10-section-14-r1:q9': ('1/(1+mu*cotA)', '72.73'),
        'physics-10-section-15-r1:q7': ('P*h/(F*s)', '66.67'),
        'physics-10-section-16-r1:q6': ('((m1-m2)*v1+2*m2*v2)/(m1+m2)', '-2'),
        'physics-10-section-18-r1:q6': ('F1*l1-F2*l2', '-2'),
        'physics-10-section-22-r1:q6': ('-omega^2*x', '-0.48'),
        'physics-10-section-23-r1:q6': ('2*p*sqrt(m/k)', '0.628'),
        'physics-10-section-24-r1:q7': ('4*p^2*l/T^2', '9.8596'),
        'physics-10-section-26-r1:q7': ('Lw*nu', '60'),
        'physics-10-section-27-r1:q7': ('Q-A', '-400'),
        'physics-10-section-28-r1:q9': ('1-Qc/Qh', '0.375'),
        'physics-10-section-30-r1:q6': ('q1+q2', '-4e-9'),
        'physics-10-section-30-r1:q10': ('sqrt(Ex^2+Ey^2)', '5000'),
        'physics-10-section-32-r1:q6': ('k*q/(eps*r)', '-30'),
        'physics-10-section-33-r1:q7': ('q*Ex*dx', '-0.0003'),
        'physics-10-section-34-r1:q9': ('e0*eps*E^2/2', '0.0000177'),
        'physics-10-section-35-r1:q6': ('1/R', '0.004'),
        'physics-10-section-20-r1:q8': ('sqrt(2*g*h+2*m*g/(rho*S))', '2.24'),
        'physics-10-section-3-r1:q5': ('v0-g*t', '-10'),
        'physics-10-section-3-r1:q11': ('sqrt(v0^2+2*g*h)', '20'),
        'physics-10-section-4-r1:q7': ('(omega-omega0)/t', '-2'),
        'physics-10-section-4-r1:q10': ('beta*R', '-2'),
      }[question['key']];
      final formula = draft?.$1 ?? 'learner_formula';
      final value = draft?.$2 ?? '1,25';
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
      await enter(tester, formula, value, question['suggested_unit'] as String);
      expect(edited?['formula'], formula);
      expect(edited?['value'], value);
      expect(edited?['unit'], question['suggested_unit']);
      expect(tester.takeException(), isNull);
    }
  });

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
