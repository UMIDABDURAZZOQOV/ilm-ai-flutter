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
              'test/fixtures/mathematics/grade1_part3_batch4.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    18: [
      'b',
      '4',
      '4',
      '3',
      'b',
      '5',
      ['b', 'a', 'c'],
      '14',
    ],
    19: ['28', '13', 'a', 'a', 'b', '25', '36', 'b'],
    20: ['b', '2', 'a', '15', 'a', '22', '7', '30'],
    21: [
      ['b', 'a', 'c'],
      '9',
      '24',
      'b',
      'a',
      '55',
      '43',
      'b',
    ],
    22: ['13', '3', '10', '5', 'b', '25', '50', '2'],
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
          data['lessons'][[18, 19, 20, 21, 22].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 18) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('III qism, 2024. PDF: 36–37. Bosma: 34–35.'),
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
      expect(find.textContaining('20 / 37'), findsOneWidget);
    },
  );
  testWidgets('two count sliders handle equality, reversal and both zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'comparison_count_gap'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('15 − 11 = 4'), findsOneWidget);
    tester
        .widget<Slider>(find.byKey(const ValueKey('application-count-0')))
        .onChanged!(0);
    tester
        .widget<Slider>(find.byKey(const ValueKey('application-count-1')))
        .onChanged!(0);
    await tester.pumpAndSettle();
    expect(find.text('0 − 0 = 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester
        .widget<Slider>(find.byKey(const ValueKey('application-count-0')))
        .onChanged!(20);
    tester
        .widget<Slider>(find.byKey(const ValueKey('application-count-1')))
        .onChanged!(1);
    await tester.pumpAndSettle();
    expect(find.text('20 − 1 = 19'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('dataset selects only named columns including two zeros', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'comparison_dataset'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('28 − 15 = 13'), findsOneWidget);
    tester
        .widget<DropdownButton<int>>(
          find.byKey(const ValueKey('application-column-0')),
        )
        .onChanged!(2);
    tester
        .widget<DropdownButton<int>>(
          find.byKey(const ValueKey('application-column-1')),
        )
        .onChanged!(3);
    await tester.pumpAndSettle();
    expect(find.text('0 − 0 = 0'), findsOneWidget);
    expect(find.text('Tanlangan ikki ustun teng.'), findsOneWidget);
  });
  testWidgets('original star counters count7/9/7 and preserve equal groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'comparison_picture_counts'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in ['A', 'B', 'C']) {
      await tester.tap(find.widgetWithText(ChoiceChip, '$name karta'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsNWidgets(name == 'B' ? 9 : 7));
      await tester.tap(find.text('Sanoqni tekshirish'));
      await tester.pumpAndSettle();
      expect(
        find.text('$name: ${name == 'B' ? 9 : 7} ta belgi'),
        findsOneWidget,
      );
    }
    expect(find.textContaining('A va C da 7 tadan'), findsOneWidget);
  });
  testWidgets('same symbol binds both operands through edits and commutation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'comparison_same_symbol'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('6 + 2 < 6 + 4'), findsOneWidget);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(0);
    await tester.pumpAndSettle();
    expect(find.text('0 + 2 < 0 + 4'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Teng'));
    await tester.pumpAndSettle();
    expect(find.text('0 + 10 = 10 + 0'), findsOneWidget);
  });
  testWidgets(
    'compound steps finish only after both stages; shape constraints all apply',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'compound_linked_steps'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final paths = {
        'Uch qism': ['5 + 2 + 6', '7 + 6', '13'],
        'Bir xil farq': ['24 − 21 = ?', '24 − 21 = 3', '13 − 3 = 10'],
        'Qavs': ['(24 + 13) − 12', '37 − 12', '25'],
      };
      for (final row in paths.entries) {
        await tester.tap(find.widgetWithText(ChoiceChip, row.key));
        await tester.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          expect(find.text(row.value[i]), findsOneWidget);
          if (i < 2) {
            await tester.tap(find.text('Keyingi qadam'));
            await tester.pumpAndSettle();
          }
        }
      }
      await tester.tap(find.widgetWithText(ChoiceChip, 'Shakllar'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Doira qo‘shish'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Ikkala bog‘lanish bajarildi.'), findsNothing);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Kvadrat qo‘shish'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Ikkala bog‘lanish bajarildi.'), findsOneWidget);
      await tester.tap(find.text('Doira qo‘shish'));
      await tester.pumpAndSettle();
      expect(find.text('Ikkala bog‘lanish bajarildi.'), findsNothing);
      await tester.tap(find.text('Qaytadan'));
      await tester.pumpAndSettle();
      expect(find.text('Doira 3 ta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
