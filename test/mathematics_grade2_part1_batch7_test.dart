import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/mathematics/data/math_repository.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_preview_screen.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_models.dart';
import 'release_hardening_test.dart' show Adapter, reply;

void main() {
  final data =
      jsonDecode(
            File(
              'test/fixtures/mathematics/grade2_part1_batch7.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    32: ['35', '35', '50', '67', 'b', '66', '36', 'yigindi'],
    33: ['14', '6', '36', '28', 'a', '35', '46', '73'],
    34: ['16', '16', '54', '24', 'c', '69', '20', '20'],
    35: ['45', '38', '10', '38', 'b', '46', '34', '33'],
    36: ['59', '31', '81', '65', 'b', '48', '2', 'ha'],
  };
  late Dio dio;
  late List<RequestOptions> requests;
  setUp(() {
    requests = [];
    SharedPreferences.setMockInitialValues({});
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8892'))
      ..transformer = SyncTransformer()
      ..httpClientAdapter = Adapter((r) {
        requests.add(r);
        if (r.path.endsWith('/catalog')) {
          return reply(
            200,
            r.queryParameters['grade'] == 2
                ? data['completed_catalog']
                : data['catalog1'],
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

  Future<void> grade2(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('math-book-1-1')));
    await tester.tap(find.text('2-sinf · I qism').last);
    await tester.pumpAndSettle();
  }

  test(
    'within-book gap DTOs and all five lesson responses satisfy client contract',
    () {
      final repo = MathRepository(dio);
      for (final c in [
        'catalog1',
        'strict_catalog',
        'available_catalog',
        'revoked_catalog',
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
    testWidgets('grade2 path$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await grade2(tester);
      final initial =
          data['lessons'][[32, 33, 34, 35, 36].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 32) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('I qism, 2023. PDF: 65–66. Bosma: 66–67.'),
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
        1,
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
    'grade choice exposes only authored lessons and a clear missing-source notice',
    (tester) async {
      await pump(tester);
      await grade2(tester);
      expect(find.text('Hozir mavjud darslar: 35 / 44.'), findsOneWidget);
      expect(
        find.textContaining('25-mavzuning bosma 54–55-sahifalari yo‘q'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<dynamic>('math-2-1-26-r1')),
        findsNothing,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<dynamic>('math-2-1-25-r1')),
        160,
        maxScrolls: 100,
        scrollable: find.byType(Scrollable).first,
      );
      final subtitle =
          tester
                  .widget<ListTile>(
                    find.byKey(const ValueKey<dynamic>('math-2-1-25-r1')),
                  )
                  .subtitle
              as Text;
      expect(subtitle.data, '24-mavzu');

      final catalogRows = mathRows(data['completed_catalog']['lessons']);
      expect(catalogRows.any((l) => l['source_number'] == 25), isFalse);
      expect(catalogRows.any((l) => l['key'] == 'math-2-1-26-r1'), isFalse);
      expect(
        catalogRows.firstWhere(
          (l) => l['key'] == 'math-2-1-25-r1',
        )['source_number'],
        24,
      );

      expect(
        requests
            .lastWhere((r) => r.path.endsWith('/catalog'))
            .queryParameters['grade'],
        2,
      );
      expect(tester.takeException(), isNull);
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

  testWidgets(
    'nonround borrow retains original units and conserves value at exchange',
    (tester) async {
      await model(tester, 'two_digit_nonround_subtraction');
      expect(find.text('4 o‘nlik, 3 birlik'), findsOneWidget);
      expect(find.text('Modeldagi jami: 43'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('regroup-next')));
      expect(find.text('3 o‘nlik, 13 birlik'), findsOneWidget);
      expect(find.text('Modeldagi jami: 43'), findsOneWidget);
      expect(find.text('43 = 30 + 13'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('regroup-next')));
      expect(find.text('3 o‘nlik, 6 birlik'), findsOneWidget);
      expect(find.text('Modeldagi jami: 36'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('regroup-back')));
      expect(find.text('3 o‘nlik, 13 birlik'), findsOneWidget);
      for (final pair in [('52 − 8', 44), ('74 − 9', 65)]) {
        await tap(tester, find.widgetWithText(ChoiceChip, pair.$1));
        expect(find.text('Qadam: 1 / 4'), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tap(tester, find.byKey(const ValueKey('regroup-next')));
        }
        expect(find.text('Modeldagi jami: ${pair.$2}'), findsOneWidget);
      }
      await model(tester, 'two_digit_regroup_subtraction');
      expect(find.text('5 o‘nlik, 0 birlik'), findsOneWidget);
      expect(requests.where((r) => r.path.endsWith('/complete')), isEmpty);
    },
  );
  test(
    'source-gap notice never certifies a missing lesson or another course',
    () {
      final repo = MathRepository(dio);
      final catalog = data['available_catalog'] as Map;
      final bridge = catalog['source_sequence_gap_bridge'] as Map;
      for (final bad in [
        {'missing_topic_completed': true},
        {
          'missing_source_numbers': [24],
        },
        {
          'missing_path_sequences': [25],
        },
        {
          'missing_printed_pages': [55, 56],
        },
        {'book_id': 'math-uz-g1-p2'},
        {'completed_predecessor_lessons': 24},
      ]) {
        expect(
          () => repo.checked({
            ...catalog,
            'source_sequence_gap_bridge': {...bridge, ...bad},
          }, 'catalog'),
          throwsFormatException,
        );
      }
      expect(
        () => repo.checked({...catalog, 'grade': 1}, 'catalog'),
        throwsFormatException,
      );
      expect(
        () => repo.checked({...catalog, 'course_ready': true}, 'catalog'),
        throwsFormatException,
      );
      expect(
        () => repo.checked({...catalog, 'publication': 'published'}, 'catalog'),
        throwsFormatException,
      );
      expect(
        mathRows(data['strict_catalog']['lessons']).last['state'],
        'locked',
      );
      expect(
        mathRows(data['available_catalog']['lessons'])[25]['key'],
        'math-2-1-27-r1',
      );
      expect(
        mathRows(data['available_catalog']['lessons'])[25]['source_number'],
        26,
      );
      expect(
        mathRows(data['available_catalog']['lessons'])[30]['state'],
        'available',
      );
      expect(data['revoked_catalog']['source_sequence_gap_bridge'], isNull);
    },
  );
  test('malformed within-book gap cannot crash a resumed attempt notice', () {
    final repo = MathRepository(dio);
    final attempt = data['lessons'][0]['initial'] as Map;
    expect(
      () => repo.checked({
        ...attempt,
        'source_sequence_gap_bridge': {'message': 1},
      }, 'attempt'),
      throwsFormatException,
    );
    expect(
      () =>
          repo.checked({...attempt, 'lesson_key': 'math-1-1-1-r1'}, 'attempt'),
      throwsFormatException,
    );
  });
}
