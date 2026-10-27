import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/mathematics_preview.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/mathematics/data/math_repository.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_models.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_preview_screen.dart';
import 'release_hardening_test.dart' show Adapter, reply;

MathJson fixture() =>
    jsonDecode(
          File(
            'test/fixtures/mathematics/grade1_part1_batch1.json',
          ).readAsStringSync(),
        )
        as MathJson;

void main() {
  late Dio dio;
  late MathJson data;
  late List<RequestOptions> requests;
  var offlineAnswer = false;
  var invalidAnswer = false;
  setUp(() {
    data = fixture();
    requests = [];
    offlineAnswer = false;
    invalidAnswer = false;
    SharedPreferences.setMockInitialValues({});
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8892'))
      ..transformer = SyncTransformer()
      ..httpClientAdapter = Adapter((r) {
        requests.add(r);
        if (r.path.endsWith('/catalog')) {
          return reply(200, data['completed_catalog']);
        }
        if (r.path.endsWith('/start')) {
          final match = RegExp(r'math-1-1-(\d+)-r1').firstMatch(r.path)!;
          return reply(
            200,
            data['lessons'][int.parse(match[1]!) - 1]['initial'],
          );
        }
        if (r.path.endsWith('/answers')) {
          if (offlineAnswer) {
            throw DioException(
              requestOptions: r,
              type: DioExceptionType.receiveTimeout,
            );
          }
          if (invalidAnswer) {
            return reply(422, {
              'detail': {
                'code': 'invalid_expression',
                'feedback': 'Yozuvni tekshir.',
              },
            });
          }
          final key = r.data['question_id'] as String;
          final match = RegExp(r'math-1-1-(\d+)-r1-q(\d+)').firstMatch(key)!;
          final source =
              data['lessons'][int.parse(match[1]!) -
                      1]['feedback'][int.parse(match[2]!) - 1]
                  as MathJson;
          return reply(200, {...source, 'request_id': r.data['request_id']});
        }
        if (r.path.endsWith('/complete')) {
          final row = (data['lessons'] as List).firstWhere(
            (v) => r.path.contains(v['initial']['attempt_id'] as String),
          );
          return reply(200, row['result']);
        }
        throw StateError('Unexpected math request');
      });
  });
  tearDown(() => dio.close(force: true));

  Future<PrefsService> pumpScreen(
    WidgetTester tester, {
    int uid = 1,
    PrefsService? prefs,
    Size size = const Size(320, 568),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = prefs ?? await PrefsService.create();
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
          preferences: preferences,
          userId: uid,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return preferences;
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> teaching(WidgetTester tester, int number) async {
    final lesson = data['lessons'][number - 1]['initial'] as MathJson;
    await tap(tester, lesson['title'] as String);
    for (var i = 0; i < (lesson['content']['cards'] as List).length; i++) {
      await tap(tester, 'Davom etish');
    }
    await tap(tester, 'Birga yechamiz');
  }

  test('preview rejects public production hosts and bad version', () {
    expect(
      mathematicsPreviewAllowed('http://127.0.0.1:8892', enabled: true),
      isTrue,
    );
    expect(
      mathematicsPreviewAllowed('https://example.com', enabled: true),
      isFalse,
    );
    expect(
      mathematicsPreviewAllowed('http://127.0.0.1', enabled: false),
      isFalse,
    );
    expect(
      mathematicsPreviewAllowed('http://u:p@127.0.0.1', enabled: true),
      isFalse,
    );
    expect(
      () => MathRepository(dio).checked({'assessment_version': 2}, 'catalog'),
      throwsFormatException,
    );
  });

  test('all real server DTOs satisfy the math client contract', () {
    final repository = MathRepository(dio);
    repository.checked(data['catalog'], 'catalog');
    for (final lesson in mathRows(data['lessons'])) {
      repository.checked(lesson['initial'], 'attempt');
      repository.checked(lesson['result'], 'result');
      for (final response in mathRows(lesson['feedback'])) {
        repository.checked(response, 'answer');
      }
    }
  });

  for (var number = 1; number <= 5; number++) {
    testWidgets(
      'source lesson $number complete flow fits 320px and 200% text',
      (tester) async {
        await pumpScreen(tester);
        await teaching(tester, number);
        final row = data['lessons'][number - 1] as MathJson;
        final answers = <int, List<String>>{
          1: ['c', 'b', 'o‘lcham', 'b', 'shakl', 'c'],
          2: ['b', 'a', 'b', 'b', 'uzunlik', 'b'],
          3: ['a', 'doira', 'o‘ngda', 'b', 'doira', 'b'],
          4: ['3', 'b', 'b', 'b', '2', '4'],
          5: ['b', 'yassi', 'b', 'a', 'shar', 'a'],
        }[number]!;
        final questions = mathRows(row['initial']['questions']);
        for (var i = 0; i < questions.length; i++) {
          final q = questions[i];
          if (q['response_kind'] == 'choice') {
            final option = mathRows(
              q['choices'],
            ).firstWhere((c) => c['id'] == answers[i]);
            final chip = find.widgetWithText(
              ChoiceChip,
              option['label'] as String,
            );
            await tester.scrollUntilVisible(
              chip,
              180,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            await tester.tap(chip);
            await tester.pumpAndSettle();
          } else {
            await tester.scrollUntilVisible(
              find.byType(TextField),
              180,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField), answers[i]);
            await tester.pumpAndSettle();
          }
          await tap(tester, 'Tekshirish');
          expect(find.text('Topding!'), findsOneWidget);
          await tap(tester, 'Davom etish');
        }
        await tap(tester, 'Natijani saqlash');
        expect(find.text('Mashq yakunlandi!'), findsOneWidget);
        expect(
          requests.where((r) => r.path.endsWith('/answers')),
          hasLength(6),
        );
      },
    );
  }

  testWidgets('timeout retains exact payload UUID and double tap sends once', (
    tester,
  ) async {
    await pumpScreen(tester);
    await teaching(tester, 1);
    final chip = find.widgetWithText(ChoiceChip, 'C');
    await tester.scrollUntilVisible(
      chip,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    offlineAnswer = true;
    final submit = find.text('Tekshirish');
    await tester.scrollUntilVisible(
      submit,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    final first = requests.where((r) => r.path.endsWith('/answers')).toList();
    expect(first, hasLength(1));
    final payload = jsonEncode(first.single.data);
    offlineAnswer = false;
    await tap(tester, 'Saqlangan javobni qayta jo‘natish');
    final retry = requests.where((r) => r.path.endsWith('/answers')).last;
    expect(jsonEncode(retry.data), payload);
    expect(find.text('Topding!'), findsOneWidget);
  });

  testWidgets('422 permits editing again instead of permanently locking FRQ', (
    tester,
  ) async {
    await pumpScreen(tester);
    await teaching(tester, 4);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1/0');
    await tester.pumpAndSettle();
    invalidAnswer = true;
    await tap(tester, 'Tekshirish');
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    final oldRequest = requests
        .where((r) => r.path.endsWith('/answers'))
        .last
        .data['request_id'];
    invalidAnswer = false;
    await tester.enterText(find.byType(TextField), '3');
    await tester.pumpAndSettle();
    await tap(tester, 'Tekshirish');
    expect(
      requests
          .where((r) => r.path.endsWith('/answers'))
          .last
          .data['request_id'],
      isNot(oldRequest),
    );
    expect(find.text('Topding!'), findsOneWidget);
  });

  testWidgets(
    'reopening same lesson reuses start UUID but new account has its own draft',
    (tester) async {
      final prefs = await pumpScreen(tester);
      await teaching(tester, 1);
      final first = requests
          .where((r) => r.path.endsWith('/start'))
          .single
          .data['request_id'];
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await pumpScreen(tester, prefs: prefs);
      await tap(tester, 'Narsalarning xossalari');
      expect(
        requests
            .where((r) => r.path.endsWith('/start'))
            .last
            .data['request_id'],
        first,
      );
      expect(find.text('Birga yechamiz'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await pumpScreen(tester, prefs: prefs, uid: 2);
      await tap(tester, 'Narsalarning xossalari');
      expect(
        requests
            .where((r) => r.path.endsWith('/start'))
            .last
            .data['request_id'],
        isNot(first),
      );
      expect(find.text('Qarash va solishtirish'), findsOneWidget);
    },
  );

  testWidgets(
    'count model counts each object only once and exposes semantic names',
    (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MathExplorer(mode: 'count_once')),
        ),
      );
      final first = find.bySemanticsLabel(RegExp(r'^S1:'));
      await tester.tap(first);
      await tester.pump();
      await tester.tap(first);
      await tester.pump();
      expect(
        find.textContaining('Bir martadan tegilgan shakllar: 1.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Sanashni qaytadan boshlash'));
      await tester.pump();
      expect(
        find.textContaining('Bir martadan tegilgan shakllar: 0.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    },
  );

  testWidgets('landscape numeric practice remains usable with keyboard inset', (
    tester,
  ) async {
    await pumpScreen(tester, size: const Size(568, 320));
    await teaching(tester, 4);
    tester.view.viewInsets = const FakeViewPadding(bottom: 140);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), '3');
    await tester.pumpAndSettle();
    await tap(tester, 'Tekshirish');
    expect(find.text('Topding!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bar geometry shares origin and preserves exact displayed length ratio',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MathExplorer(mode: 'compare_lengths')),
        ),
      );
      tester.widget<Slider>(find.byType(Slider)).onChanged!(1.3);
      await tester.pump();
      final bars = find.byWidgetPredicate(
        (w) => w is Container && w.color == mathTurquoise,
      );
      expect(bars, findsNWidgets(2));
      expect(
        tester.getSize(bars.at(1)).width / tester.getSize(bars.at(0)).width,
        closeTo(1.3, 1e-9),
      );
      expect(
        tester.getTopLeft(bars.at(0)).dx,
        tester.getTopLeft(bars.at(1)).dx,
      );
    },
  );
}
