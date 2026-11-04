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
              'test/fixtures/mathematics/grade1_part3_batch6.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    31: ['b', '7', '2', '12', 'b', '28', '14', 'a'],
    32: ['10', '14', '1', '10', 'b', '16', '24', '7'],
    33: ['40', '27', '3', '6', 'b', '16', '93', 'a'],
    34: [
      '4',
      'a',
      '43',
      '22',
      'b',
      '13',
      ['b', 'c', 'a'],
      '21',
    ],
    35: ['b', '9', '8', 'a', 'b', '12', '2', '8'],
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
          data['lessons'][[31, 32, 33, 34, 35].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 31) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('III qism, 2024. PDF: 56–57. Bosma: 54–55.'),
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
      expect(find.textContaining('30 / 37'), findsOneWidget);
    },
  );
  testWidgets(
    'segment comparison preserves equality and reversed larger segment',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'measurement_segments'),
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
              .widget<Text>(find.byKey(const ValueKey('units-segment-gap')))
              .data,
          n == 1
              ? '5 − 1 = 4cm'
              : n == 5
              ? '5 − 5 = 0cm'
              : '10 − 5 = 5cm',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('decimetre conversion and mode range reset preserve remainders', (
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

    await show('measurement_dm_cm_conversion');
    expect(find.text('27 cm = 2 dm 7 cm'), findsOneWidget);
    for (final row in {
      99: '99 cm = 9 dm 9 cm',
      90: '90 cm = 9 dm 0 cm',
      0: '0 cm = 0 dm 0 cm',
    }.entries) {
      tester.widget<Slider>(find.byType(Slider)).onChanged!(row.key.toDouble());
      await tester.pumpAndSettle();
      expect(find.text(row.value), findsOneWidget);
    }
    tester.widget<Slider>(find.byType(Slider)).onChanged!(99);
    await tester.pumpAndSettle();
    await show('measurement_decimetre_intro');
    expect(tester.widget<Slider>(find.byType(Slider)).value, 14);
    expect(find.text('14 cm = 1 dm 4 cm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'rectangle model also permits a square without changing its side unit',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'measurement_rectangles'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester.widget<Slider>(find.byType(Slider)).onChanged!(3);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('ikkala model ham 3 cmli kvadrat'),
        findsOneWidget,
      );
      tester.widget<Slider>(find.byType(Slider)).onChanged!(2);
      await tester.pumpAndSettle();
      expect(find.textContaining('ikki turli yon uzunligi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'balance changes the selected known weight and evaluates both directions',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExplorer(mode: 'measurement_mass_balance'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final row in {
        0: 'O‘ng tomon og‘irroq.',
        8: 'Massalar teng. Qo‘shilgan tosh 8 kg.',
        9: 'Chap tomon og‘irroq.',
      }.entries) {
        tester.widget<Slider>(find.byType(Slider)).onChanged!(
          row.key.toDouble(),
        );
        await tester.pumpAndSettle();
        expect(find.text(row.value), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
