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
              'test/fixtures/mathematics/grade1_part4_batch6.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    139: ['19', '25', '14', '25', 'b', '18', '17', 'b'],
    140: ['21', '13', '8', '22', 'a', '15', '18', 'b'],
    141: ['17', '7', '24', '15', 'a', '17', '31', 'b'],
    142: [
      '23',
      '19',
      ['a', 'b', 'c'],
      '10',
      'b',
      '11',
      'b',
      '7',
    ],
    143: [
      '60',
      ['b', 'a', 'c'],
      '11',
      '4',
      'a',
      '36',
      '15',
      'b',
    ],
    144: ['26', '2', '33', '12', 'b', '20', '6', '3'],
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
          data['lessons'][[139, 140, 141, 142, 143, 144].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 139) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('IV qism, 2023. PDF: 59–60. Bosma: 58–59.'),
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

  testWidgets('root means original equality, not any candidate', (
    tester,
  ) async {
    await model(tester, 'equation_root_check');
    expect(find.text('Chap: 26; o‘ng: 26'), findsOneWidget);
    expect(find.text('Bu son shu tenglamaning ildizi.'), findsOneWidget);
    await change(tester, 'root-candidate', 18);
    expect(find.text('Nomzod tenglikni rost qilmadi.'), findsOneWidget);
    await tap(tester, find.widgetWithText(ChoiceChip, '36 − x = 17'));
    await change(tester, 'root-candidate', 19);
    expect(find.text('Chap: 17; o‘ng: 17'), findsOneWidget);
    await change(tester, 'root-candidate', 36);
    expect(find.text('Chap: 0; o‘ng: 17'), findsOneWidget);
  });
  testWidgets(
    'inverse family retains both disjoint parts at zero and maximum',
    (tester) async {
      await model(tester, 'inverse_story_family');
      expect(find.text('Butun: 21'), findsOneWidget);
      await tap(
        tester,
        find.widgetWithText(ChoiceChip, 'Birinchi qism noma’lum'),
      );
      expect(find.text('x + 13 = 21; x = 8'), findsOneWidget);
      await change(tester, 'family-a', 0);
      await change(tester, 'family-b', 0);
      expect(find.text('x + 0 = 0; x = 0'), findsOneWidget);
      await change(tester, 'family-a', 20);
      await change(tester, 'family-b', 20);
      await tap(
        tester,
        find.widgetWithText(ChoiceChip, 'Ikkinchi qism noma’lum'),
      );
      expect(find.text('20 + x = 40; x = 20'), findsOneWidget);
    },
  );
  testWidgets(
    'initial removed remaining obey conservation and clamp after reset',
    (tester) async {
      await model(tester, 'equation_initial_remaining');
      expect(find.text('Dastlab: 24; olindi: 7; qoldi: 17'), findsOneWidget);
      await change(tester, 'removed-count', 24);
      await change(tester, 'initial-count', 4);
      expect(find.text('Dastlab: 4; olindi: 4; qoldi: 0'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Olingan noma’lum'));
      expect(find.text('4 − x = 0; x = 4'), findsOneWidget);
      await change(tester, 'initial-count', 0);
      expect(find.byKey(const ValueKey('removed-count')), findsNothing);
      expect(find.text('Dastlab: 0; olindi: 0; qoldi: 0'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Dastlabki noma’lum'));
      expect(find.text('x − 0 = 0; x = 0'), findsOneWidget);
      await change(tester, 'initial-count', 30);
      await change(tester, 'removed-count', 30);
      expect(find.text('Tekshiruv: 30 + 0 = 30'), findsOneWidget);
    },
  );
  testWidgets(
    'computed values sort with corrective feedback and no repeated chip',
    (tester) async {
      await model(tester, 'review_sort_quantity');
      for (final i in [3, 2, 1, 0]) {
        await tap(tester, find.byKey(ValueKey('review-sort-$i')));
      }
      expect(
        find.text('Natijalar hali o‘sish tartibida emas.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ActionChip>(find.byKey(const ValueKey('review-sort-0')))
            .onPressed,
        isNull,
      );
      await tap(tester, find.byKey(const ValueKey('review-sort-reset')));
      expect(find.text('Hali tartib tanlanmadi.'), findsOneWidget);
      for (final i in [0, 1, 2, 3]) {
        await tap(tester, find.byKey(ValueKey('review-sort-$i')));
      }
      expect(find.text('Natijalar o‘sish tartibida.'), findsOneWidget);
    },
  );
  testWidgets(
    'language tracks parentheses even when distinct expressions share value',
    (tester) async {
      await model(tester, 'review_word_expression');
      expect(find.text('Ushbu qiymatlarda natija: 15'), findsOneWidget);
      await tap(
        tester,
        find.widgetWithText(ChoiceChip, 'Sondan ayirmani ayirish'),
      );
      expect(
        find.text('Ichki va tashqi amalni qayta tekshiring.'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(ChoiceChip, 'k − (v − w)'));
      expect(find.text('Yozuv gapga mos.'), findsOneWidget);
      expect(find.text('Ushbu qiymatlarda natija: 29'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, '(k − v) + w'));
      expect(find.text('Ushbu qiymatlarda natija: 29'), findsOneWidget);
      expect(
        find.text('Ichki va tashqi amalni qayta tekshiring.'),
        findsOneWidget,
      );
      await tap(
        tester,
        find.widgetWithText(ChoiceChip, 'Ayirmaga son qo‘shish'),
      );
      expect(find.text('Yozuv gapga mos.'), findsOneWidget);
    },
  );
  testWidgets(
    'segment adjacent and all pair counts stay distinct under bounded lengths',
    (tester) async {
      await model(tester, 'review_segment_parts');
      expect(find.text('AB = 3 + 4 + 5 = 12 cm'), findsOneWidget);
      expect(
        find.textContaining('CD 4 cm ikki marta sanaladi'),
        findsOneWidget,
      );
      expect(
        find.text('Faqat qo‘shni bo‘laklar: AC, CD, DB — 3 ta.'),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const ValueKey('segment-all-pairs')));
      expect(
        find.text('Barcha kesmalar: AC, AD, AB, CD, CB, DB — 6 ta.'),
        findsOneWidget,
      );
      for (final key in ['segment-ac', 'segment-cd', 'segment-db']) {
        await change(tester, key, 10);
      }
      expect(find.text('AB = 10 + 10 + 10 = 30 cm'), findsOneWidget);
      expect(
        find.textContaining('CD 10 cm ikki marta sanaladi'),
        findsOneWidget,
      );
      for (final key in ['segment-ac', 'segment-cd', 'segment-db']) {
        await change(tester, key, 1);
      }
      expect(find.text('AB = 1 + 1 + 1 = 3 cm'), findsOneWidget);
      await model(tester, 'equation_root_check');
      await model(tester, 'review_segment_parts');
      expect(find.text('AB = 3 + 4 + 5 = 12 cm'), findsOneWidget);
      expect(requests.where((r) => r.path.endsWith('/complete')), isEmpty);
    },
  );
}
