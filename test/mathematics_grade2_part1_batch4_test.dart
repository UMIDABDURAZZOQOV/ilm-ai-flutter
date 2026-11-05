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
              'test/fixtures/mathematics/grade2_part1_batch4.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    16: ['60', '10', '40', '80', 'b', '30', '44', '55'],
    17: ['36', '10', '60', '16', 'a', '33', '37', '24'],
    18: ['34', '6', '19', '84', 'b', '32', '22', '40'],
    19: ['42', '65', '15', '14', 'b', 'I', 'a', '48'],
    20: ['42', '1', '2', '33', 'b', '45', '23', 'a'],
    21: ['51', '1', '35', '28', 'b', '63', '26', '85'],
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
    'all five books and the source-gap metadata satisfy client contract',
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
    testWidgets('grade2 source$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await grade2(tester);
      final initial =
          data['lessons'][[16, 17, 18, 19, 20, 21].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 16) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('I qism, 2023. PDF: 35–36. Bosma: 34–35.'),
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
      expect(find.text('Hozir mavjud darslar: 21 / 44.'), findsOneWidget);
      expect(
        find.textContaining('ayrim manba sahifalari yetishmaydi'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('math-2-1-25-r1')), findsNothing);
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
    'more than ten ones keep leftover units across all source models',
    (tester) async {
      await model(tester, 'two_digit_cross_tens_addition');
      expect(find.text('3 o‘nlik, 12 birlik'), findsOneWidget);
      for (final pair in [
        ('35 + 7', 42),
        ('48 + 6', 54),
        ('67 + 8', 75),
        ('79 + 9', 88),
      ]) {
        await tap(tester, find.widgetWithText(ChoiceChip, pair.$1));
        expect(find.text('Qadam: 1 / 4'), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          expect(find.text('Modeldagi jami: ${pair.$2}'), findsOneWidget);
          await tap(tester, find.byKey(const ValueKey('regroup-next')));
        }
        expect(
          find.text('${pair.$2 ~/ 10} o‘nlik, ${pair.$2 % 10} birlik'),
          findsOneWidget,
        );
      }
      expect(find.text('8 o‘nlik, 8 birlik'), findsOneWidget);
      await model(tester, 'round_tens_addition');
      expect(find.text('2 o‘nlik, 10 birlik'), findsOneWidget);
      expect(requests.where((r) => r.path.endsWith('/complete')), isEmpty);
    },
  );
  testWidgets(
    'round minus two digit removes both tens and units after exchange',
    (tester) async {
      await model(tester, 'two_digit_regroup_subtraction');
      expect(find.text('5 o‘nlik, 0 birlik'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('regroup-next')));
      expect(find.text('4 o‘nlik, 10 birlik'), findsOneWidget);
      expect(find.text('Modeldagi jami: 50'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('regroup-next')));
      expect(find.text('2 o‘nlik, 7 birlik'), findsOneWidget);
      expect(find.text('Modeldagi jami: 27'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('regroup-back')));
      expect(find.text('4 o‘nlik, 10 birlik'), findsOneWidget);
      for (final pair in [('70 − 26', 44), ('90 − 42', 48)]) {
        await tap(tester, find.widgetWithText(ChoiceChip, pair.$1));
        for (var i = 0; i < 3; i++) {
          await tap(tester, find.byKey(const ValueKey('regroup-next')));
        }
        expect(find.text('Modeldagi jami: ${pair.$2}'), findsOneWidget);
      }
    },
  );
}
