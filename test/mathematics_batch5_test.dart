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
              'test/fixtures/mathematics/grade1_part1_batch5.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    21: ['1', '2', '4', '6', 'b', '6', 'a', '6'],
    22: ['2', '3', 'a', '3', 'b', '7', '5', 'c'],
    23: ['5', '8', '4', 'a', 'b', '3', 'b', '5'],
    24: ['2', '3', 'c', '8', 'a', '8', '1', 'a'],
    25: ['0', '3', '4', '0', 'b', '0', '0', 'a'],
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
          return reply(200, data['lessons'][n - 21]['initial']);
        }
        if (r.path.endsWith('/answers')) {
          final m = RegExp(
            r'math-1-1-(\d+)-r1-q(\d+)',
          ).firstMatch(r.data['question_id'] as String)!;
          final source =
              data['lessons'][int.parse(m[1]!) -
                      21]['feedback'][int.parse(m[2]!) - 1]
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
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  test('all batch5 real public server DTOs satisfy client contract', () {
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

  for (var n = 21; n <= 25; n++) {
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
        final initial = data['lessons'][n - 21]['initial'] as MathJson;
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

  testWidgets(
    'empty is an explicit zero and taking all never yields a negative quantity',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: MathExplorer(mode: 'zero')),
          ),
        ),
      );
      await tester.tap(find.text('Hammasini ol'));
      await tester.pumpAndSettle();
      expect(find.text('Qutida: 0 ta doira'), findsOneWidget);
      expect(find.text('Bo‘sh: 0 ta'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Bittasini ol'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Bittasini qo‘sh'));
      await tester.pumpAndSettle();
      expect(find.text('Qutida: 1 ta doira'), findsOneWidget);
    },
  );
  testWidgets(
    'nine-object composition wraps without overflow at 320px and 200% text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'compose_nine'),
            ),
          ),
        ),
      );
      final slider = find.byType(Slider);
      await tester.scrollUntilVisible(
        slider,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      tester.widget<Slider>(slider).onChanged!(8);
      await tester.pumpAndSettle();
      expect(find.text('A qism: 8 ta'), findsOneWidget);
      expect(find.text('B qism: 1 ta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
