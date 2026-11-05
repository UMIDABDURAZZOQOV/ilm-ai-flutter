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
              'test/fixtures/mathematics/grade1_part4_batch5.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    133: ['13', '20', '60', '9', 'b', '25', '4', '18'],
    134: ['15', '6', '15', '15', 'b', '18', '62', 'b'],
    135: ['4', '26', '29', '5', 'b', '4', 'a', 'b'],
    136: ['4', '9', '50', '90', 'a', 'XLIII', '60', '21'],
    137: ['15', '17', '23', '17', 'b', '14', '26', '24'],
    138: [
      'b',
      '15',
      ['a', 'b', 'c', 'd', 'e', 'f'],
      '23',
      'a',
      '17',
      '29',
      '9',
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
          if (part == 4 && catalogOffline) {
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
                : part == 3
                ? data['catalog3']
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

  Future<void> part4(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('math-book-1-1')));
    await tester.tap(find.text('1-sinf · IV qism').last);
    await tester.pumpAndSettle();
  }

  test(
    'all four books and explicit server QA metadata satisfy client contract',
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
    testWidgets('book4 source$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await part4(tester);
      final initial =
          data['lessons'][[133, 134, 135, 136, 137, 138].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 133) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('IV qism, 2023. PDF: 47–48. Bosma: 46–47.'),
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
        4,
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

  Future<void> change(WidgetTester tester, String key, double value) async {
    tester.widget<Slider>(find.byKey(ValueKey(key))).onChanged!(value);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  test(
    'Roman1–100 canonical output, independent subtractive values and bounds',
    () {
      const checks = {
        1: 'I',
        4: 'IV',
        9: 'IX',
        19: 'XIX',
        40: 'XL',
        43: 'XLIII',
        49: 'XLIX',
        50: 'L',
        58: 'LVIII',
        90: 'XC',
        94: 'XCIV',
        99: 'XCIX',
        100: 'C',
      };
      for (final e in checks.entries) {
        expect(mathRoman1to100(e.key), e.value);
      }
      const values = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100};
      final seen = <String>{};
      for (var n = 1; n <= 100; n++) {
        final result = mathRoman1to100(n);
        expect(seen.add(result), isTrue);
        var sum = 0;
        for (var i = 0; i < result.length; i++) {
          final v = values[result[i]]!;
          sum += i + 1 < result.length && v < values[result[i + 1]]! ? -v : v;
        }
        expect(sum, n);
      }
      expect(() => mathRoman1to100(0), throwsRangeError);
      expect(() => mathRoman1to100(101), throwsRangeError);
    },
  );
  testWidgets(
    'given letter values and numeric constants stay distinct with safe subtraction',
    (tester) async {
      await model(tester, 'algebra_value_table');
      expect(find.text('Qiymat: 16'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('evaluation-given')));
      expect(
        find.textContaining('harfning qiymati yetishmayapti'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('evaluation-result')), findsNothing);
      await tap(tester, find.widgetWithText(ChoiceChip, '37 + 13 + (20 − 10)'));
      expect(find.text('Qiymat: 60'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'x + 9'));
      await tap(tester, find.byKey(const ValueKey('evaluation-given')));
      await change(tester, 'evaluation-parameter', 0);
      await tap(tester, find.widgetWithText(ChoiceChip, '18 + (a − 5)'));
      expect(
        tester
            .widget<Slider>(find.byKey(const ValueKey('evaluation-parameter')))
            .value,
        5,
      );
      expect(find.text('Qiymat: 18'), findsOneWidget);
      await change(tester, 'evaluation-parameter', 20);
      expect(find.text('Qiymat: 33'), findsOneWidget);
    },
  );
  testWidgets(
    'addition grouping and commutation preserve all terms including zero',
    (tester) async {
      await model(tester, 'algebra_addition_properties');
      expect(find.text('(4 + 6) + 5 = 15'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('properties-swap')));
      await tap(
        tester,
        find.widgetWithText(ChoiceChip, 'Avval oxirgi juftlik'),
      );
      expect(find.text('6 + (4 + 5) = 15'), findsOneWidget);
      for (final key in ['properties-a', 'properties-b', 'properties-c']) {
        await change(tester, key, 0);
      }
      expect(find.text('0 + (0 + 0) = 0'), findsOneWidget);
      for (final key in ['properties-a', 'properties-b', 'properties-c']) {
        await change(tester, key, 20);
      }
      expect(find.text('20 + (20 + 20) = 60'), findsOneWidget);
    },
  );
  testWidgets(
    'strict two-digit inequalities exclude endpoints and wrong domain',
    (tester) async {
      await model(tester, 'algebra_integer_inequalities');
      expect(find.text('Barcha mos sonlar: 26, 27, 28, 29'), findsOneWidget);
      for (final n in [25, 30]) {
        await change(tester, 'inequality-candidate', n.toDouble());
        expect(find.text('Ikkala shart birga bajarilmadi.'), findsOneWidget);
      }
      await tap(tester, find.widgetWithText(ChoiceChip, 'x < 15'));
      expect(find.text('Mos sonlar soni: 5'), findsOneWidget);
      await change(tester, 'inequality-candidate', 9);
      expect(
        find.text('Ikki xonali: yo‘q; tengsizlik rost: ha.'),
        findsOneWidget,
      );
      await change(tester, 'inequality-candidate', 14);
      expect(find.text('Ikkala shartga mos.'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'x > 95'));
      await change(tester, 'inequality-candidate', 100);
      expect(find.text('Ikkala shart birga bajarilmadi.'), findsOneWidget);
      expect(find.text('Barcha mos sonlar: 96, 97, 98, 99'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, '40 < x < 45'));
      expect(find.text('Barcha mos sonlar: 41, 42, 43, 44'), findsOneWidget);
    },
  );
  testWidgets('Roman notation fits320px at200percent with zero tens and ones', (
    tester,
  ) async {
    await model(tester, 'notation_roman_100');
    for (final n in [1, 4, 9, 88, 90, 100]) {
      await change(tester, 'roman-number', n.toDouble());
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('roman-result'))).data,
        mathRoman1to100(n),
      );
      expect(tester.takeException(), isNull);
    }
    expect(find.textContaining('qoldiq 0, belgi qo‘shilmaydi'), findsOneWidget);
  });
  testWidgets(
    'unknown component roles use bounded candidates and original equation checks',
    (tester) async {
      await model(tester, 'equation_unknown_component');
      expect(find.text('Chap: 19; o‘ng: 19'), findsOneWidget);
      await change(tester, 'equation-guess', 40);
      await tap(tester, find.widgetWithText(ChoiceChip, '26 − x = 10'));
      expect(
        tester
            .widget<Slider>(find.byKey(const ValueKey('equation-guess')))
            .value,
        26,
      );
      await change(tester, 'equation-guess', 16);
      expect(find.text('Chap: 10; o‘ng: 10'), findsOneWidget);
      await change(tester, 'equation-guess', 0);
      await tap(tester, find.widgetWithText(ChoiceChip, 'x − 8 = 13'));
      expect(
        tester
            .widget<Slider>(find.byKey(const ValueKey('equation-guess')))
            .value,
        8,
      );
      await change(tester, 'equation-guess', 21);
      expect(find.text('Chap: 13; o‘ng: 13'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, '9 + x = 24'));
      await change(tester, 'equation-guess', 15);
      expect(find.text('Nomzod asl tenglikka mos.'), findsOneWidget);
    },
  );
  testWidgets('six-step worked guide resets per equation and never awards XP', (
    tester,
  ) async {
    await model(tester, 'equation_solution_steps');
    for (final label in ['x + 8 = 23', '31 − x = 12', 'x − 6 = 14']) {
      await tap(tester, find.widgetWithText(ChoiceChip, label));
      expect(find.text('Qadam: 1 / 6'), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        await tap(tester, find.byKey(const ValueKey('equation-next-step')));
      }
      expect(find.text('Qadam: 6 / 6'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('equation-next-step')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.textContaining(
          label == '31 − x = 12'
              ? 'Tekshiruv: 31 − 19 = 12'
              : label == 'x − 6 = 14'
              ? 'Tekshiruv: 20 − 6 = 14'
              : 'Tekshiruv: 15 + 8 = 23',
        ),
        findsOneWidget,
      );
    }
    await tap(tester, find.widgetWithText(OutlinedButton, 'Boshidan ko‘rish'));
    expect(find.text('Qadam: 1 / 6'), findsOneWidget);
    expect(requests.where((r) => r.path.endsWith('/complete')), isEmpty);
  });
}
