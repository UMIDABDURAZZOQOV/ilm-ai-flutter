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
              'test/fixtures/mathematics/grade1_part3_batch3.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    11: ['7', '42', 'b', '39', 'b', '25', '37', 'b'],
    14: ['a', '27', '21', '48', 'b', '46', '22', '37'],
    15: ['a', 'b', '5', '57', 'b', '42', '14', '4'],
    16: ['60', '70', '62', '42', 'b', '10', '27', '14'],
    17: ['14', '37', '23', '62', 'b', '11', '26', '11'],
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
  for (final n in keys.keys) {
    testWidgets('book3 source$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await part3(tester);
      final initial =
          data['lessons'][[11, 14, 15, 16, 17].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 11) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('III qism, 2024. PDF: 26–27. Bosma: 24–25.'),
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
      await tester.scrollUntilVisible(
        find.textContaining('avval oldingi kitob'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('avval oldingi kitob'), findsWidgets);
      expect(requests.where((r) => r.path.endsWith('/start')), isEmpty);
      locked = false;
      await tap(tester, find.byKey(const ValueKey('math-book-1-3')));
      await tester.tap(find.text('1-sinf · I qism').last);
      await tester.pumpAndSettle();
      await part3(tester);
      await tester.scrollUntilVisible(
        find.textContaining('Lokal sinov:'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Lokal sinov:'), findsWidgets);
      expect(find.textContaining('15 / 37'), findsOneWidget);
    },
  );
  testWidgets('route totals compare minutes without inventing distance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'problem_route_times'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final n in ['A', 'B', 'C']) {
      await tester.tap(find.widgetWithText(ChoiceChip, '$n yo‘l'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('comparison-route-time')), findsNothing);
      await tester.tap(find.text('Yo‘l vaqtini ochish'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('comparison-route-time')))
            .data,
        n == 'B'
            ? '4 + 7 = 11 minut'
            : n == 'A'
            ? '6 + 8 = 14 minut'
            : '5 + 9 = 14 minut',
      );
    }
    expect(find.textContaining('B tezroq; A va C teng'), findsOneWidget);
  });
  testWidgets('more/less uses the same reference and zero difference', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'comparison_more_less'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('24 + 3 = 27'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('24 − 3 = 21'), findsOneWidget);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(0);
    await tester.pumpAndSettle();
    expect(find.text('24 − 0 = 24'), findsOneWidget);
  });
  testWidgets(
    'several strict partitions remain valid while equal/reversed do not',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'comparison_partitions'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final n in [9, 10, 15]) {
        tester.widget<Slider>(find.byType(Slider)).onChanged!(n.toDouble());
        await tester.pumpAndSettle();
        expect(find.text('Ikkala shartga mos juftlik.'), findsOneWidget);
        expect(
          find.text('$n + ${16 - n} = 16; $n > ${16 - n}'),
          findsOneWidget,
        );
      }
      for (final n in [8, 7, 1]) {
        tester.widget<Slider>(find.byType(Slider)).onChanged!(n.toDouble());
        await tester.pumpAndSettle();
        expect(find.textContaining('shart bajarilmadi'), findsOneWidget);
      }
    },
  );
  testWidgets(
    'independent branches reset to50 and never accumulate previous result',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'comparison_independent_branches'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('50 + 10 = 60'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '+20 tarmoq'));
      await tester.pumpAndSettle();
      expect(find.text('50 + 20 = 70'), findsOneWidget);
      expect(find.text('60 + 20 = 80'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, '−40 tarmoq'));
      await tester.pumpAndSettle();
      expect(find.text('50 − 40 = 10'), findsOneWidget);
    },
  );
  testWidgets(
    'difference family keeps roles and resets all four relations after edit',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'comparison_difference_family'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final equation in [
        '23 + 14 = 37',
        '14 + 23 = 37',
        '37 − 23 = 14',
        '37 − 14 = 23',
      ]) {
        expect(find.text(equation), findsOneWidget);
        if (equation != '37 − 14 = 23') {
          await tester.tap(find.text('Keyingi bog‘lanish'));
          await tester.pumpAndSettle();
        }
      }
      tester.widget<Slider>(find.byType(Slider)).onChanged!(0);
      await tester.pumpAndSettle();
      expect(find.text('23 + 0 = 23'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
