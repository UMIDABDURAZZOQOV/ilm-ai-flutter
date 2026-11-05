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
              'test/fixtures/mathematics/grade1_part4_batch4.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    127: ['4', '2', 'b', 'c', 'b', '2', '4', 'b'],
    128: ['b', 'shar', 'a', 'b', 'b', '12', '8', 'silindr'],
    129: ['25', '9', '40', 'a', 'b', '7', 'a', 'a'],
    130: ['a', 'b', '11', '9', 'b', '12', '15', 'b'],
    131: ['13', '11', 'a', 'b', 'b', '9', '13', 'b'],
    132: ['6', '10', 'a', '8', 'b', '6', '3', 'b'],
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
          data['lessons'][[127, 128, 129, 130, 131, 132].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 127) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('IV qism, 2023. PDF: 35–36. Bosma: 34–35.'),
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

  testWidgets(
    'exact shape axes distinguish square, nonsquare rectangle and circle samples',
    (tester) async {
      await model(tester, 'geometry_shape_axes');
      expect(
        find.text('Ushbu aniq modelning simmetriya o‘qlari soni: 4.'),
        findsOneWidget,
      );
      for (final name in ['Tik', 'Yotiq', 'Diagonal ↘', 'Diagonal ↗']) {
        await tap(tester, find.widgetWithText(ChoiceChip, name));
        expect(find.text('Bu chiziq simmetriya o‘qi.'), findsOneWidget);
      }
      await tap(tester, find.widgetWithText(ChoiceChip, '6 × 4 to‘rtburchak'));
      expect(
        find.text('Bu chiziq shu shaklning simmetriya o‘qi emas.'),
        findsOneWidget,
      );
      expect(
        find.text('Ushbu aniq modelning simmetriya o‘qlari soni: 2.'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(ChoiceChip, 'Doira'));
      expect(find.textContaining('o‘qlar 4 dan ham ko‘p'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('shape-all-axes')));
      expect(tester.takeException(), isNull);
      await tap(
        tester,
        find.widgetWithText(ChoiceChip, 'Teng yonli trapetsiya'),
      );
      await tap(tester, find.widgetWithText(ChoiceChip, 'Yotiq'));
      expect(
        find.text('Bu chiziq shu shaklning simmetriya o‘qi emas.'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(ChoiceChip, 'Tik'));
      expect(find.text('Bu chiziq simmetriya o‘qi.'), findsOneWidget);
      await tap(
        tester,
        find.widgetWithText(ChoiceChip, 'Muntazam oltiburchak'),
      );
      expect(
        find.text('Ushbu aniq modelning simmetriya o‘qlari soni: 6.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'seven original solid models and declared cone/cylinder views fit large text',
    (tester) async {
      await model(tester, 'geometry_solid_views');
      for (final name in [
        'Shar',
        'Kub',
        'Piramida',
        'Konus',
        'Silindr',
        'Kuboid',
        'Prizma',
      ]) {
        await tap(tester, find.widgetWithText(ChoiceChip, name));
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('solid-name'))).data,
          name,
        );
      }
      await tap(tester, find.widgetWithText(ChoiceChip, 'Konus'));
      await tap(tester, find.widgetWithText(ChoiceChip, 'Tepadagi chizma'));
      expect(find.text('Tepadagi ko‘rinish: doira.'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Yondagi chizma'));
      expect(find.text('Yondagi ko‘rinish: uchburchak.'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Silindr'));
      await tap(tester, find.widgetWithText(ChoiceChip, 'Yondagi chizma'));
      expect(
        find.text('Yondagi ko‘rinish: to‘g‘ri to‘rtburchak.'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(ChoiceChip, 'Kub'));
      expect(find.widgetWithText(ChoiceChip, 'Yondagi chizma'), findsNothing);
    },
  );
  testWidgets(
    'sum comparison evaluates both sides and handles all-zero and upper bound',
    (tester) async {
      await model(tester, 'algebra_compare_sums');
      expect(find.text('43 > 36'), findsOneWidget);
      for (final key in [
        'sums-left-a',
        'sums-left-b',
        'sums-right-a',
        'sums-right-b',
      ]) {
        await change(tester, key, 0);
      }
      expect(find.text('0 = 0'), findsOneWidget);
      await change(tester, 'sums-left-a', 40);
      await change(tester, 'sums-left-b', 40);
      expect(find.text('80 > 0'), findsOneWidget);
      expect(find.textContaining('Farq: 80 birlik.'), findsOneWidget);
    },
  );
  testWidgets(
    'letter expression classification and substitution keep zero boundary nonnegative',
    (tester) async {
      await model(tester, 'algebra_expression_kind');
      await tap(tester, find.widgetWithText(ChoiceChip, 'Sonli'));
      expect(find.textContaining('bu sonli ifoda'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'a + 7'));
      await tap(tester, find.widgetWithText(ChoiceChip, 'Sonli'));
      expect(find.textContaining('qayta tekshiring'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Harfiy'));
      await change(tester, 'expression-a', 0);
      expect(find.text('a + 7 ning qiymati: 7'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, '15 − a'));
      await change(tester, 'expression-a', 15);
      expect(find.text('15 − a ning qiymati: 0'), findsOneWidget);
    },
  );
  testWidgets(
    'variable parts preserve inverse equations for zero and maximum',
    (tester) async {
      await model(tester, 'algebra_parts_variables');
      await change(tester, 'parts-a', 20);
      await change(tester, 'parts-b', 20);
      expect(find.text('a = 20; b = 20; c = 40'), findsOneWidget);
      expect(find.text('b = c − a: 40 − 20 = 20'), findsOneWidget);
      await change(tester, 'parts-a', 0);
      await change(tester, 'parts-b', 0);
      expect(find.text('a = 0; b = 0; c = 0'), findsOneWidget);
      expect(find.text('a = c − b: 0 − 0 = 0'), findsOneWidget);
    },
  );
  testWidgets(
    'same variable is substituted on both sides and mode lifecycle resets',
    (tester) async {
      await model(tester, 'algebra_value_comparison');
      expect(find.text('8 = 8'), findsOneWidget);
      await change(tester, 'value-x', 0);
      expect(find.text('4 < 12'), findsOneWidget);
      await change(tester, 'value-x', 12);
      expect(find.text('16 > 0'), findsOneWidget);
      await model(tester, 'algebra_expression_kind');
      await model(tester, 'algebra_value_comparison');
      expect(find.text('8 = 8'), findsOneWidget);
      expect(requests.where((r) => r.path.endsWith('/complete')), isEmpty);
    },
  );
}
