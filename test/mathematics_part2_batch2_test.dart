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
              'test/fixtures/mathematics/grade1_part2_batch2.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    47: ['17', '6', '18', 'b', 'a', '18', '17', '14'],
    48: ['20', '2', '0', 'a', 'b', '20', '6', '19'],
    49: [
      'a',
      'b',
      ['b', 'c', 'a'],
      'c',
      'b',
      '18',
      'a',
      'c',
    ],
    50: ['b', '9', '13', '15', 'b', '8', '12', '13'],
    51: [
      '9',
      '3',
      '6',
      ['a', 'b', 'c'],
      'b',
      '14',
      '14',
      'b',
    ],
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
          if (part == 2 && catalogOffline) {
            throw DioException(
              requestOptions: r,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return reply(
            200,
            part == 1
                ? data['catalog1']
                : locked
                ? data['locked_catalog']
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

  Future<void> part2(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('math-book-1-1')));
    await tester.tap(find.text('1-sinf · II qism').last);
    await tester.pumpAndSettle();
  }

  test('both books and all new public DTOs satisfy client contract', () {
    final repo = MathRepository(dio);
    for (final c in [
      'catalog1',
      'catalog2',
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
  });
  for (var n = 47; n <= 51; n++) {
    testWidgets('book2 source$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await part2(tester);
      final initial = data['lessons'][n - 47]['initial'] as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 47) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('II qism, 2023. PDF: 15–16. Bosma: 14–15.'),
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
        2,
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
    'comparison uses tens before units and keeps equality meaningful',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'compare_place_value_20'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<Slider>(find.byKey(const ValueKey('compare-Chap')))
          .onChanged!(20);
      tester
          .widget<Slider>(find.byKey(const ValueKey('compare-O‘ng')))
          .onChanged!(19);
      await tester.pumpAndSettle();
      expect(find.text('20 > 19'), findsOneWidget);
      expect(find.textContaining('O‘nliklar har xil: 2 va 1'), findsOneWidget);
      tester
          .widget<Slider>(find.byKey(const ValueKey('compare-O‘ng')))
          .onChanged!(20);
      await tester.pumpAndSettle();
      expect(find.text('20 = 20'), findsOneWidget);
    },
  );
  testWidgets('bracket grouping changes the actual path and resets safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'brackets_single'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('15 − (3 + 4)'), findsOneWidget);
    await tester.tap(find.text('Keyingi qadam'));
    await tester.pumpAndSettle();
    expect(find.text('15 − 7'), findsOneWidget);
    await tester.tap(find.text('Keyingi qadam'));
    await tester.pumpAndSettle();
    expect(find.text('8'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('15 − 3 + 4'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Keyingi qadam'));
      await tester.pumpAndSettle();
    }
    expect(find.text('16'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'brackets_double'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('(7 + 2) − (6 − 3)'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Keyingi qadam'));
      await tester.pumpAndSettle();
    }
    expect(find.text('6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
