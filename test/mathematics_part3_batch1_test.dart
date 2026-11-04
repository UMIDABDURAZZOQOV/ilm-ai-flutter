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
              'test/fixtures/mathematics/grade1_part3_batch1.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    1: ['b', 'a', '17', 'a', 'b', '17', '18', 'c'],
    2: [
      ['a', 'b', 'c', 'd'],
      '37',
      'b',
      '47',
      'b',
      '62',
      '65',
      'b',
    ],
    3: [
      'b',
      '56',
      '76',
      '22',
      'a',
      '22',
      'a',
      ['a', 'b', 'c', 'd', 'e'],
    ],
    4: ['b', 'a', '37', 'b', 'a', '33', '18', '23'],
    5: [
      '12',
      '11',
      'a',
      ['a', 'b', 'c'],
      'b',
      '57',
      '9',
      '22',
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
          if (part == 3 && catalogOffline) {
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

  Future<void> part3(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('math-book-1-1')));
    await tester.tap(find.text('1-sinf · III qism').last);
    await tester.pumpAndSettle();
  }

  test(
    'all three books and explicit server QA metadata satisfy client contract',
    () {
      final repo = MathRepository(dio);
      for (final c in [
        'catalog1',
        'catalog2',
        'catalog3',
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
  for (var n = 1; n <= 5; n++) {
    testWidgets('book3 source$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await part3(tester);
      final initial = data['lessons'][n - 1]['initial'] as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 1) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('III qism, 2024. PDF: 6–7. Bosma: 4–5.'),
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
        3,
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
    'source bridge remains explicit and normal strict mode stays locked',
    (tester) async {
      locked = true;
      await pump(tester);
      await part3(tester);
      expect(find.textContaining('avval oldingi kitob'), findsWidgets);
      expect(requests.where((r) => r.path.endsWith('/start')), isEmpty);
      locked = false;
      await tap(tester, find.byKey(const ValueKey('math-book-1-3')));
      await tester.tap(find.text('1-sinf · I qism').last);
      await tester.pumpAndSettle();
      await part3(tester);
      expect(find.textContaining('Lokal sinov:'), findsWidgets);
      expect(find.textContaining('5 / 37'), findsOneWidget);
    },
  );
  testWidgets('story roles and representations preserve the same facts', (
    tester,
  ) async {
    Future<void> show(String mode) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: MathExplorer(mode: mode)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show('problem_parts');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Savol'));
    await tester.pumpAndSettle();
    expect(find.text('Jami nechta rasm bor?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Javob'));
    await tester.pumpAndSettle();
    expect(find.text('17 ta rasm'), findsOneWidget);
    await show('problem_representations');
    for (final name in ['Qisqa yozuv', 'Sxema', 'Belgili rasm']) {
      await tester.tap(find.widgetWithText(ChoiceChip, name));
      await tester.pumpAndSettle();
      expect(find.textContaining('Jami 37 ta karta'), findsOneWidget);
    }
    expect(find.text('13 ta karta'), findsOneWidget);
    expect(find.text('24 ta karta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('branch executes once at45 and whole-part accepts zero/full', (
    tester,
  ) async {
    Future<void> show(String mode) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: MathExplorer(mode: mode)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show('problem_algorithm');
    tester.widget<Slider>(find.byType(Slider)).onChanged!(45);
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Keyingi qadam'));
      await tester.pumpAndSettle();
    }
    expect(find.text('45 + 20 = 65'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Keyingi qadam'),
          )
          .onPressed,
      isNull,
    );
    tester.widget<Slider>(find.byType(Slider)).onChanged!(73);
    await tester.pumpAndSettle();
    expect(find.text('73 sonini tekshiramiz'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Keyingi qadam'));
      await tester.pumpAndSettle();
    }
    expect(find.text('73 − 11 = 62'), findsOneWidget);
    await show('problem_part_whole');
    for (final k in [0, 76]) {
      tester.widget<Slider>(find.byType(Slider)).onChanged!(k.toDouble());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hisobni ochish'));
      await tester.pumpAndSettle();
      expect(find.text('76 − $k = ${76 - k}'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('table sums only the selected column before comparison', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'problem_table_totals'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('A oldinda'), findsNothing);
    await tester.tap(find.text('Ustun jamini ochish'));
    await tester.pumpAndSettle();
    expect(find.text('A:4 + 5 + 3 = 12'), findsOneWidget);
    expect(find.textContaining('A oldinda'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'B ustuni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ustun jamini ochish'));
    await tester.pumpAndSettle();
    expect(find.text('B:3 + 4 + 4 = 11'), findsOneWidget);
    expect(find.textContaining('A oldinda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
