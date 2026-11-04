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
              'test/fixtures/mathematics/grade1_part3_batch5.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    23: ['b', '34', '8', 'b', 'b', '21', '7', 'b'],
    24: ['b', '6', 'c', '5', 'b', '6', '4', '4'],
    25: ['17', '30', 'b', 'a', 'b', '27', '34', '3'],
    26: ['b', 'a', 'c', '5', 'b', '43', '8', '26'],
    30: ['a', '5', 'b', '5', 'b', '5', '4', 'a'],
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
          data['lessons'][[23, 24, 25, 26, 30].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 23) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('III qism, 2024. PDF: 46–47. Bosma: 44–45.'),
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
      expect(find.textContaining('25 / 37'), findsOneWidget);
    },
  );
  testWidgets(
    'missing data remains unknown until an explicit condition is chosen',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'problem_missing_information'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ma’lumot yetarli emas.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('reasoning-completed-total')),
        findsNothing,
      );
      tester
          .widget<DropdownButton<int>>(
            find.byKey(const ValueKey('reasoning-missing-choice')),
          )
          .onChanged!(12);
      await tester.pumpAndSettle();
      expect(find.text('9 + 12 = 21'), findsOneWidget);
      tester
          .widget<DropdownButton<int>>(
            find.byKey(const ValueKey('reasoning-missing-choice')),
          )
          .onChanged!(20);
      await tester.pumpAndSettle();
      expect(find.text('9 + 20 = 29'), findsOneWidget);
      await tester.tap(find.text('Yuqoridan ko‘rinish va kub soni'));
      await tester.pumpAndSettle();
      expect(find.textContaining('hammasi 4 kub'), findsOneWidget);
    },
  );
  testWidgets(
    'unordered pair builder rejects identical and reversed duplicates',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'problem_unordered_pairs'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> pair(int a, int b) async {
        tester
            .widget<DropdownButton<int>>(
              find.byKey(const ValueKey('reasoning-pair-0')),
            )
            .onChanged!(a);
        tester
            .widget<DropdownButton<int>>(
              find.byKey(const ValueKey('reasoning-pair-1')),
            )
            .onChanged!(b);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tanlovni qo‘shish'));
        await tester.pumpAndSettle();
      }

      await pair(0, 1);
      await pair(1, 0);
      expect(find.text('Turli juftliklar: 1'), findsOneWidget);
      await pair(0, 0);
      expect(find.text('Ikki karta turli bo‘lsin.'), findsOneWidget);
      for (final p in [
        [0, 1],
        [0, 2],
        [0, 3],
        [1, 2],
        [1, 3],
        [2, 3],
      ]) {
        await pair(p[0], p[1]);
      }
      expect(find.text('Turli juftliklar: 6'), findsOneWidget);
    },
  );
  testWidgets('related part is intermediate and total has both parts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'problem_related_total'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keyingi qadam'));
    await tester.pumpAndSettle();
    expect(find.text('Ikkinchi: 13 + 4 = 17'), findsOneWidget);
    await tester.tap(find.text('Keyingi qadam'));
    await tester.pumpAndSettle();
    expect(find.text('Jami: 13 + 17 = 30'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Keyingi qadam'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Jami: 13 + 9 = 22'), findsOneWidget);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(0);
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Keyingi qadam'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Jami: 13 + 13 = 26'), findsOneWidget);
  });
  testWidgets(
    'relative weekday steps wrap through Monday and reset after edit',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'problem_weekday_reasoning'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButton<int>>(
            find.byKey(const ValueKey('reasoning-tomorrow')),
          )
          .onChanged!(0);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reasoning-day-step')))
            .data,
        'Ertaga Dushanba',
      );
      await tester.tap(find.text('Bir kun orqaga'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reasoning-day-step')))
            .data,
        'Bugun Yakshanba',
      );
      await tester.tap(find.text('Bir kun orqaga'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reasoning-day-step')))
            .data,
        'Kecha Shanba',
      );
      tester
          .widget<DropdownButton<int>>(
            find.byKey(const ValueKey('reasoning-tomorrow')),
          )
          .onChanged!(5);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reasoning-day-step')))
            .data,
        'Ertaga Shanba',
      );
    },
  );
  testWidgets('centimetre model counts intervals not number of tick labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'measurement_centimetre'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final n in [1, 5, 10]) {
      tester.widget<Slider>(find.byType(Slider)).onChanged!(n.toDouble());
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reasoning-cm-result')))
            .data,
        '0 → $n cm: $n ta 1 cm oraliq',
      );
      expect(tester.takeException(), isNull);
    }
  });
}
