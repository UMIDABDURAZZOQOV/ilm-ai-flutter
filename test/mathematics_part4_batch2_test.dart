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
              'test/fixtures/mathematics/grade1_part4_batch2.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    117: ['18', '20', '15', '6', 'a', '20', '18', '12'],
    118: ['6', '20', '12', '4', 'b', '7', '20', 'a'],
    119: ['20', '16', '8', '6', 'a', '24', 'a', '4'],
    120: ['32', '20', 'a', 'b', 'b', '32', '16', 'b'],
    121: ['2', '1', 'a', 'c', 'b', 'o‘tkir', 'o‘tmas', 'b'],
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
          data['lessons'][[117, 118, 119, 120, 121].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 117) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('IV qism, 2023. PDF: 15–16. Bosma: 14–15.'),
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
    'closed perimeter counts every side once and resets on size changes',
    (tester) async {
      await model(tester, 'geometry_perimeter_trace');
      for (var i = 1; i <= 4; i++) {
        await tap(tester, find.byKey(const ValueKey('perimeter-next')));
        expect(
          find.text('Sanaldi: $i / 4; hozirgi jami: ${i * 3} cm'),
          findsOneWidget,
        );
      }
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('perimeter-next')))
            .onPressed,
        isNull,
      );
      await change(tester, 'perimeter-sides', 3);
      await change(tester, 'perimeter-side', 5);
      expect(find.text('Sanaldi: 0 / 3; hozirgi jami: 0 cm'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tap(tester, find.byKey(const ValueKey('perimeter-next')));
      }
      expect(
        find.text('Yopiq chegara to‘liq sanaldi. P = 15 cm.'),
        findsOneWidget,
      );
      expect(requests.where((r) => r.path.endsWith('/complete')), isEmpty);
    },
  );
  testWidgets(
    'unknown side is checked against fixed given perimeter rather than changing geometry',
    (tester) async {
      await model(tester, 'geometry_perimeter_missing');
      await change(tester, 'perimeter-guess', 0);
      expect(find.text('8 + 6 + 0 = 14 cm'), findsOneWidget);
      await change(tester, 'perimeter-guess', 12);
      expect(find.text('8 + 6 + 12 = 26 cm'), findsOneWidget);
      await change(tester, 'perimeter-guess', 6);
      expect(find.text('P ga mos: 20 − (8 + 6) = 6 cm.'), findsOneWidget);
    },
  );
  testWidgets(
    'equal perimeters need not be equal shapes and square stays in rectangle family',
    (tester) async {
      await model(tester, 'geometry_rectangle_perimeter');
      await change(tester, 'perimeter-width', 8);
      await change(tester, 'perimeter-height', 2);
      expect(find.text('8 + 2 + 8 + 2 = 20 cm'), findsOneWidget);
      await change(tester, 'perimeter-width', 5);
      await change(tester, 'perimeter-height', 5);
      expect(find.text('5 + 5 + 5 + 5 = 20 cm'), findsOneWidget);
      expect(
        find.text('Hozir kvadrat ham, to‘g‘ri to‘rtburchak ham.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'parallel paper model distinguishes inner boundary and physical packing scope',
    (tester) async {
      await model(tester, 'geometry_parallel_paper_fit');
      await change(tester, 'perimeter-paper', 6);
      expect(find.text('Tashqi P: 32 cm; ichki P: 24 cm'), findsOneWidget);
      expect(
        find.textContaining('ikkala o‘lchamga ham sig‘adi'),
        findsOneWidget,
      );
      await change(tester, 'perimeter-paper', 7);
      expect(find.text('Tashqi P: 32 cm; ichki P: 28 cm'), findsOneWidget);
      expect(
        find.textContaining('7 cm tomon 6 cm bo‘yga sig‘maydi'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'angle type follows opening under rotation with no numeric degree prerequisite',
    (tester) async {
      await model(tester, 'geometry_angle_comparison');
      expect(find.text('To‘g‘ri burchak; 2 nur; 1 umumiy uch'), findsOneWidget);
      for (final name in ['O‘tkir', 'O‘tmas', 'To‘g‘ri']) {
        await tap(tester, find.widgetWithText(ChoiceChip, name));
        await tap(tester, find.byKey(const ValueKey('angle-rotate')));
        expect(find.text('$name burchak; 2 nur; 1 umumiy uch'), findsOneWidget);
      }
      expect(
        find.textContaining('Sonli gradus bilimi talab qilinmaydi'),
        findsOneWidget,
      );
      await model(tester, 'geometry_rectangle_perimeter');
      await model(tester, 'geometry_angle_comparison');
      expect(find.text('To‘g‘ri burchak; 2 nur; 1 umumiy uch'), findsOneWidget);
    },
  );
}
