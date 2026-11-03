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
              'test/fixtures/mathematics/grade1_part1_batch8.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    36: ['b', 'a', '5', '0', 'b', '6', '5', '6'],
    37: ['7', '5', '2', '7', 'a', '8', '3', 'b'],
    38: ['a', 'b', '5', '7', 'b', '6', 'b', '5'],
    39: ['7', '7', '7', 'a', 'b', '9', 'b', '3'],
    40: ['2', '8', '5', 'a', 'a', '8', 'b', '4'],
    41: ['a', '7', '6', '9', 'b', '5', 'b', '1'],
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
          return reply(200, data['completed_catalog']);
        }
        if (r.path.endsWith('/start')) {
          final n = int.parse(
            RegExp(r'math-1-1-(\d+)-r1').firstMatch(r.path)![1]!,
          );
          return reply(200, data['lessons'][n - 36]['initial']);
        }
        if (r.path.endsWith('/answers')) {
          final m = RegExp(
            r'math-1-1-(\d+)-r1-q(\d+)',
          ).firstMatch(r.data['question_id'] as String)!;
          final source =
              data['lessons'][int.parse(m[1]!) -
                      36]['feedback'][int.parse(m[2]!) - 1]
                  as MathJson;
          return reply(200, {...source, 'request_id': r.data['request_id']});
        }
        if (r.path.endsWith('/complete')) {
          final row = (data['lessons'] as List).firstWhere(
            (v) => r.path.contains(v['initial']['attempt_id'] as String),
          );
          return reply(200, row['result']);
        }
        throw StateError('Unexpected math request');
      });
  });
  tearDown(() => dio.close(force: true));

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

  test('all batch8 real public server DTOs satisfy client contract', () {
    final repository = MathRepository(dio);
    repository.checked(data['catalog'], 'catalog');
    for (final row in mathRows(data['lessons'])) {
      repository.checked(row['initial'], 'attempt');
      repository.checked(row['result'], 'result');
      for (final feedback in mathRows(row['feedback'])) {
        repository.checked(feedback, 'answer');
      }
    }
  });

  for (var n = 36; n <= 41; n++) {
    testWidgets(
      'lesson $n full flow at 320px with 200% text and reduced motion',
      (tester) async {
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
        final initial = data['lessons'][n - 36]['initial'] as MathJson;
        await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
        for (final _ in initial['content']['cards'] as List) {
          await tap(tester, find.text('Davom etish'));
        }
        await tap(tester, find.text('Birga yechamiz'));
        final questions = mathRows(initial['questions']);
        for (var i = 0; i < questions.length; i++) {
          final q = questions[i];
          final answer = keys[n]![i];
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
              final item = mathRows(
                q['items'],
              ).firstWhere((c) => c['id'] == id);
              await tap(
                tester,
                find.widgetWithText(ActionChip, item['label'] as String),
              );
            }
          } else {
            await tester.scrollUntilVisible(
              find.byType(TextField),
              160,
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
          requests.where((r) => r.path.endsWith('/answers')),
          hasLength(questions.length),
        );
        final submitted = requests
            .where((r) => r.path.endsWith('/answers'))
            .toList();
        for (var i = 0; i < questions.length; i++) {
          final field = questions[i]['response_kind'] == 'choice'
              ? 'choice_id'
              : questions[i]['response_kind'] == 'ordering'
              ? 'order'
              : 'value';
          expect(submitted[i].data['answer'][field], keys[n]![i]);
        }
      },
    );
  }

  Future<void> explorer(WidgetTester tester, String mode) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MathExplorer(mode: mode)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'swapping groups preserves all original shapes and their quantity',
    (tester) async {
      await explorer(tester, 'commutative');
      expect(find.text('3 + 2 = 5'), findsOneWidget);
      await tester.tap(find.text('O‘rinlarini almashtir'));
      await tester.pumpAndSettle();
      expect(find.text('2 + 3 = 5'), findsOneWidget);
      final shapes = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<MathShapePainter>()
          .toList();
      expect(shapes.where((p) => p.shape == 'circle'), hasLength(3));
      expect(shapes.where((p) => p.shape == 'square'), hasLength(2));
    },
  );
  testWidgets(
    'table cells use row and column headers and absent results are not zero',
    (tester) async {
      await explorer(tester, 'addition_table');
      await tester.tap(find.byKey(const ValueKey('math-table-4-3')));
      await tester.pumpAndSettle();
      expect(find.text('4-qator, 3-ustun: 4 + 3 = 7'), findsOneWidget);
      expect(find.byKey(const ValueKey('math-table-9-9')), findsNothing);
      expect(find.text('0'), findsNothing);
    },
  );
  testWidgets(
    'unknown subtrahend and family changes keep controls in their domain',
    (tester) async {
      await explorer(tester, 'missing_addend');
      tester.widget<Slider>(find.byType(Slider)).onChanged!(8);
      await tester.pumpAndSettle();
      await explorer(tester, 'missing_minuend');
      expect(tester.takeException(), isNull);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 3);
      await explorer(tester, 'missing_subtrahend');
      await tester.tap(find.text('Qanday topishni ko‘r'));
      await tester.pumpAndSettle();
      expect(find.text('8 − 3 = 5'), findsOneWidget);
      expect(find.textContaining('Tekshirish: 8 − 5 = 3.'), findsOneWidget);
    },
  );
  testWidgets('stepwise expression uses each intermediate result then resets', (
    tester,
  ) async {
    await explorer(tester, 'expression_steps');
    expect(find.text('4 + 2 − 1'), findsOneWidget);
    await tester.tap(find.text('Keyingi hisob'));
    await tester.pumpAndSettle();
    expect(find.text('6 − 1'), findsOneWidget);
    await tester.tap(find.text('Keyingi hisob'));
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
    await tester.tap(find.text('Boshidan hisoblash'));
    await tester.pumpAndSettle();
    expect(find.text('4 + 2 − 1'), findsOneWidget);
  });
}
