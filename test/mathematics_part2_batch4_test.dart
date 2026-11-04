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
              'test/fixtures/mathematics/grade1_part2_batch4.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    57: ['4', '2', '6', 'a', 'b', '6', '9', '6'],
    58: ['4', '5', '50', '30', 'b', '50', '50', '100'],
    59: ['3', '4', '41', '40', 'b', '35', '30', '40'],
    60: ['40', '2', '64', '49', 'b', '32', '40', '30'],
    61: ['42', '10', '60', '5', 'a', '64', '34', 'b'],
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
          if (part == 2 && catalogOffline) {
            throw DioException(
              requestOptions: r,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return reply(
            200,
            part == 1
                ? data['catalog1']
                : locked
                ? data['locked_catalog']
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

  Future<void> part2(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('math-book-1-1')));
    await tester.tap(find.text('1-sinf · II qism').last);
    await tester.pumpAndSettle();
  }

  test('both books and all new public DTOs satisfy client contract', () {
    final repo = MathRepository(dio);
    for (final c in [
      'catalog1',
      'catalog2',
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
  });
  for (var n = 57; n <= 61; n++) {
    testWidgets('book2 source$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await part2(tester);
      final initial = data['lessons'][n - 57]['initial'] as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 57) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('II qism, 2023. PDF: 35–36. Bosma: 34–35.'),
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
        2,
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
    '100 is ten tens, changing modes restores a valid two-digit number',
    (tester) async {
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

      await show('round_tens_100');
      tester
          .widget<Slider>(find.byKey(const ValueKey('round-tens-slider')))
          .onChanged!(10);
      await tester.pumpAndSettle();
      expect(find.text('100 — yuz'), findsOneWidget);
      expect(
        find.text('10 ta to‘liq o‘nlik va 0 ta alohida birlik'),
        findsOneWidget,
      );
      await show('place_value_100');
      expect(find.text('42 = 40 + 2'), findsOneWidget);
      tester
          .widget<Slider>(find.byKey(const ValueKey('hundred-units-slider')))
          .onChanged!(0);
      await tester.pumpAndSettle();
      expect(find.text('40 = 40 + 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('abacus reads bead positions and chart cannot step past 100', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MathExplorer(mode: 'abacus_100')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNWidgets(6));
    expect(find.text('42 = 40 + 2'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathExplorer(mode: 'hundred_chart'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('100 — yuz'));
    await tester.tap(find.text('100 — yuz'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('hundred-current-number')))
          .data,
      '100 = 100 + 0',
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Yana 1 qo‘sh'),
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('Oldingi qo‘shni: 99'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
