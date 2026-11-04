import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/mathematics/data/math_repository.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_models.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_preview_screen.dart';
import 'release_hardening_test.dart' show Adapter, reply;

void main() {
  final data =
      jsonDecode(
            File(
              'test/fixtures/mathematics/grade1_part4_batch1.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    112: ['7', '3', '26', '10', 'b', '17', '8', '15'],
    113: [
      '6',
      '8',
      '5',
      '16',
      'a',
      '9',
      ['a', 'b', 'c', 'd'],
      '9',
    ],
    114: ['8', '5', '34', '4', 'b', '11', '9', 'a'],
    115: ['3', '4', '9', '5', 'b', '15', '12', 'a'],
    116: ['3', '5', '6', '61', 'b', '4', '17', 'b'],
  };
  late Dio dio;
  late List<RequestOptions> requests;
  bool catalogOffline = false, locked = false;
  setUp(() {
    requests = [];
    catalogOffline = false;
    locked = false;
    SharedPreferences.setMockInitialValues({});
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8892'))
      ..transformer = SyncTransformer()
      ..httpClientAdapter = Adapter((r) {
        requests.add(r);
        if (r.path.endsWith('/catalog')) {
          final part = r.queryParameters['part'] ?? 1;
          if (part == 4 && catalogOffline) {
            throw DioException(
              requestOptions: r,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return reply(
            200,
            part == 1
                ? data['catalog1']
                : part == 2
                ? data['catalog2']
                : part == 3
                ? data['catalog3']
                : locked
                ? data['strict_catalog']
                : data['completed_catalog'],
          );
        }
        if (r.path.endsWith('/start')) {
          final row = mathRows(data['lessons']).firstWhere(
            (v) => r.path.contains(v['initial']['lesson_key'] as String),
          );
          return reply(200, row['initial']);
        }
        if (r.path.endsWith('/answers')) {
          final feedback = mathRows(data['lessons'])
              .expand((v) => mathRows(v['feedback']))
              .firstWhere((v) => v['question_id'] == r.data['question_id']);
          return reply(200, {...feedback, 'request_id': r.data['request_id']});
        }
        if (r.path.endsWith('/complete')) {
          final row = mathRows(data['lessons']).firstWhere(
            (v) => r.path.contains(v['initial']['attempt_id'] as String),
          );
          return reply(200, row['result']);
        }
        throw StateError('Unexpected math request');
      });
  });
  tearDown(() => dio.close(force: true));
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(lightColors),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: MathPreviewScreen(
          repository: MathRepository(dio),
          preferences: await PrefsService.create(),
          userId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      160,
      maxScrolls: 200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> part4(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('math-book-1-1')));
    await tester.tap(find.text('1-sinf · IV qism').last);
    await tester.pumpAndSettle();
  }

  test(
    'all four books and explicit server QA metadata satisfy client contract',
    () {
      final repo = MathRepository(dio);
      for (final c in [
        'catalog1',
        'catalog2',
        'catalog3',
        'catalog4',
        'completed_catalog',
        'locked_catalog',
      ]) {
        repo.checked(data[c], 'catalog');
      }
      for (final row in mathRows(data['lessons'])) {
        repo.checked(row['initial'], 'attempt');
        repo.checked(row['result'], 'result');
        for (final f in mathRows(row['feedback'])) {
          repo.checked(f, 'answer');
        }
      }
    },
  );
  for (final n in keys.keys) {
    testWidgets('book4 source$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await part4(tester);
      final initial =
          data['lessons'][[112, 113, 114, 115, 116].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 112) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('IV qism, 2023. PDF: 5–6. Bosma: 4–5.'),
          findsOneWidget,
        );
      }
      for (final _ in initial['content']['cards'] as List) {
        await tap(tester, find.text('Davom etish'));
      }
      await tap(tester, find.text('Birga yechamiz'));
      final questions = mathRows(initial['questions']);
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i], answer = keys[n]![i];
        if (q['response_kind'] == 'choice') {
          final option = mathRows(
            q['choices'],
          ).firstWhere((c) => c['id'] == answer);
          await tap(
            tester,
            find.widgetWithText(ChoiceChip, option['label'] as String),
          );
        } else if (q['response_kind'] == 'ordering') {
          for (final id in answer as List) {
            final item = mathRows(q['items']).firstWhere((v) => v['id'] == id);
            await tap(
              tester,
              find.widgetWithText(ActionChip, item['label'] as String),
            );
          }
        } else {
          await tester.scrollUntilVisible(
            find.byType(TextField),
            160,
            maxScrolls: 100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), answer as String);
          await tester.pumpAndSettle();
        }
        await tap(tester, find.text('Tekshirish'));
        expect(find.text('Topding!'), findsOneWidget);
        await tap(tester, find.text('Davom etish'));
      }
      await tap(tester, find.text('Natijani saqlash'));
      expect(find.text('Mashq yakunlandi!'), findsOneWidget);
      expect(
        requests
            .lastWhere((r) => r.path.endsWith('/catalog'))
            .queryParameters['part'],
        4,
      );
      final submitted = requests
          .where((r) => r.path.endsWith('/answers'))
          .toList();
      expect(submitted, hasLength(8));
      for (var i = 0; i < questions.length; i++) {
        final field =
            {
              'choice': 'choice_id',
              'ordering': 'order',
            }[questions[i]['response_kind']] ??
            'value';
        expect(submitted[i].data['answer'][field], keys[n]![i]);
      }
    });
  }
  testWidgets(
    'IV preview shows explicit schedule gap and strict mode remains locked',
    (tester) async {
      locked = true;
      await pump(tester);
      await part4(tester);
      await tester.scrollUntilVisible(
        find.textContaining('avval oldingi kitob'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('avval oldingi kitob'), findsWidgets);
      expect(requests.where((r) => r.path.endsWith('/start')), isEmpty);
      expect(
        data['catalog4']['source_gap_bridge']['schedule_only_rows_not_completed'],
        5,
      );
      expect(
        data['catalog4']['source_gap_bridge']['earlier_source_gap']['missing_source_numbers'],
        [74],
      );
      expect(data['completed_catalog']['course_ready'], false);
      expect(data['completed_catalog']['previous_book_complete'], false);
    },
  );

  Future<void> model(WidgetTester tester, String mode) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(child: MathExplorer(mode: mode)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> change(WidgetTester tester, String key, double value) async {
    tester.widget<Slider>(find.byKey(ValueKey(key))).onChanged!(value);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('ruler keeps intervals distinct from shifted endpoint labels', (
    tester,
  ) async {
    await model(tester, 'geometry_ruler_interval');
    expect(find.text('A: 2 cm; B: 9 cm; AB: 7 cm'), findsOneWidget);
    await change(tester, 'geometry-origin', 4);
    await change(tester, 'geometry-length', 8);
    expect(find.text('A: 4 cm; B: 12 cm; AB: 8 cm'), findsOneWidget);
    await change(tester, 'geometry-origin', 0);
    await change(tester, 'geometry-length', 1);
    expect(find.text('A: 0 cm; B: 1 cm; AB: 1 cm'), findsOneWidget);
  });
  testWidgets(
    'construction checks actual interval and resets bounded state on mode change',
    (tester) async {
      await model(tester, 'geometry_construct_segment');
      await change(tester, 'geometry-origin', 4);
      await change(tester, 'geometry-target', 8);
      await change(tester, 'geometry-endpoint', 12);
      expect(find.text('Berilgan 8 cm uzunlik hosil bo‘ldi.'), findsOneWidget);
      await change(tester, 'geometry-endpoint', 4);
      expect(
        find.text('Hozir 0 cm; kerakli 8 cm. B belgisini tekshiring.'),
        findsOneWidget,
      );
      await model(tester, 'geometry_segment_partition');
      await model(tester, 'geometry_construct_segment');
      expect(find.text('A: 2 cm; B: 6 cm; AB: 4 cm'), findsOneWidget);
      expect(
        tester
            .widget<Slider>(find.byKey(const ValueKey('geometry-target')))
            .value,
        7,
      );
    },
  );
  testWidgets('interior split preserves whole at both permitted extremes', (
    tester,
  ) async {
    await model(tester, 'geometry_segment_partition');
    await change(tester, 'geometry-cut', 1);
    expect(find.text('AC: 1 cm; CB: 11 cm; AB: 12 cm'), findsOneWidget);
    await change(tester, 'geometry-cut', 11);
    expect(find.text('AC: 11 cm; CB: 1 cm; AB: 12 cm'), findsOneWidget);
  });
  testWidgets(
    'bending fixed polyline links preserves sum rather than endpoint chord',
    (tester) async {
      await model(tester, 'geometry_polyline_length');
      expect(find.text('3 + 4 + 2 = 9 cm'), findsOneWidget);
      await change(tester, 'geometry-first-link', 6);
      await tap(tester, find.byKey(const ValueKey('geometry-bend')));
      expect(find.text('6 + 4 + 2 = 12 cm'), findsOneWidget);
      await change(tester, 'geometry-first-link', 1);
      expect(find.text('1 + 4 + 2 = 7 cm'), findsOneWidget);
      expect(find.textContaining('3 bo‘g‘in, 4 uch'), findsOneWidget);
    },
  );
  testWidgets(
    'polygon closing adds only the missing edge and rotation keeps counts',
    (tester) async {
      await model(tester, 'geometry_polygon_boundary');
      for (var n = 3; n <= 6; n++) {
        await change(tester, 'geometry-vertices', n.toDouble());
        expect(find.text('$n uch; $n tomon; yopiq'), findsOneWidget);
      }
      await tap(tester, find.byKey(const ValueKey('geometry-close')));
      expect(find.text('6 uch; 5 bo‘g‘in; ochiq'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('geometry-rotate')));
      expect(find.text('6 uch; 5 bo‘g‘in; ochiq'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('geometry-close')));
      expect(find.text('6 uch; 6 tomon; yopiq'), findsOneWidget);
      expect(
        requests.where(
          (r) => r.path.endsWith('/answers') || r.path.endsWith('/complete'),
        ),
        isEmpty,
      );
    },
  );
}
