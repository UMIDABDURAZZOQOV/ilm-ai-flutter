import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/uzbekistan_history_preview.dart';
import 'package:ilm_ai_flutter/core/network/api_contract.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/uzbekistan_history/data/history_repository.dart';
import 'package:ilm_ai_flutter/features/uzbekistan_history/presentation/history_answer_editor.dart';
import 'package:ilm_ai_flutter/features/uzbekistan_history/presentation/history_preview_screen.dart';
import 'release_hardening_test.dart' show Adapter, reply;

Json fixture(String name) =>
    jsonDecode(
          File(
            'test/fixtures/uzbekistan_history/$name.json',
          ).readAsStringSync(),
        )
        as Json;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late List<RequestOptions> requests;
  late Json catalog, lesson;
  var offline = false;
  setUp(() {
    requests = [];
    catalog = fixture('catalog7');
    lesson = fixture('lesson1');
    offline = false;
    // Large real catalog fixtures otherwise decode on a background isolate,
    // outside widget fake time. Keep only this mock transport synchronous.
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'))
      ..transformer = SyncTransformer()
      ..httpClientAdapter = Adapter((r) {
        requests.add(r);
        if (offline) {
          throw DioException(
            requestOptions: r,
            type: DioExceptionType.connectionError,
          );
        }
        if (r.path.endsWith('/catalog')) {
          final grade = r.queryParameters['grade'] as int;
          return reply(200, grade == 7 ? catalog : fixture('catalog$grade'));
        }
        if (r.path.endsWith('/start')) return reply(200, lesson);
        throw StateError('Unexpected ${r.path}');
      });
  });
  tearDown(() => dio.close(force: true));

  test(
    'combined textbook paragraphs keep source numbering rather than path order',
    () {
      expect(
        historySectionLabel({
          'sequence': 4,
          'source_numbers': [4, 5],
        }),
        '§4–5',
      );
      expect(
        historySectionLabel({
          'sequence': 34,
          'source_numbers': [35, 36],
        }),
        '§35–36',
      );
      expect(
        historySectionLabel({
          'sequence': 5,
          'source_numbers': [6],
        }),
        '§6',
      );
      expect(historySectionLabel({'sequence': 5}), '5-bosqich');
      final grade8 = fixture('catalog8');
      final capstone = jsonRows(grade8['lessons']).last;
      expect(grade8['grade_content_complete'], isTrue);
      expect(capstone['source_numbers'], isNull);
      expect(historySectionLabel(capstone), '41-bosqich');
      expect(capstone['title'], contains('Yakuniy'));
      expect(grade8['course_ready'], isFalse);
      expect(
        historySectionLabel(jsonRows(fixture('catalog9')['lessons'])[3]),
        '§4–5',
      );
    },
  );

  Future<void> mount(
    WidgetTester tester, {
    Widget? child,
    double scale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefsService.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(900003),
          historyRepositoryProvider.overrideWithValue(HistoryRepository(dio)),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child ?? const UzbekistanHistoryPreviewScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('preview is opt-in and rejects public hosts and userinfo', () {
    expect(uzbekistanHistoryPreview, false);
    expect(uzbekistanHistoryPreviewAllowed('http://localhost:8000'), false);
    expect(
      uzbekistanHistoryPreviewAllowed('http://192.168.1.2:8000', enabled: true),
      true,
    );
    for (final host in [
      'https://ilm-ai.onrender.com',
      'https://user:secret@localhost',
      'http://172.32.1.1',
    ]) {
      expect(uzbekistanHistoryPreviewAllowed(host, enabled: true), false);
    }
  });

  test(
    'real public DTOs contain no private grading rules or aliases',
    () async {
      final repo = HistoryRepository(dio);
      for (var i = 1; i <= 42; i++) {
        lesson = fixture('lesson$i');
        final dto = await repo.start(
          'uzh-7-$i-r1',
          HistoryRepository.requestId(),
          CancelToken(),
        );
        final encoded = jsonEncode(dto);
        for (final key in [
          'grading_spec',
          'accepted_answers',
          'aliases',
          'expected_order',
        ]) {
          expect(encoded, isNot(contains('"$key"')));
        }
        expect(dto['questions'], isNotEmpty);
      }
      for (var grade = 7; grade <= 11; grade++) {
        final dto = await repo.catalog(CancelToken(), grade: grade);
        expect(dto['grade'], grade);
      }
    },
  );

  test(
    'wrong subject, grade, lesson identity and response kind fail closed',
    () async {
      final repo = HistoryRepository(dio);
      catalog['subject'] = 'jahon_tarixi';
      await expectLater(
        repo.catalog(CancelToken()),
        throwsA(isA<InvalidApiResponseException>()),
      );
      catalog = fixture('catalog7')..['grade'] = 9;
      await expectLater(
        repo.catalog(CancelToken()),
        throwsA(isA<InvalidApiResponseException>()),
      );
      lesson['lesson_key'] = 'uzh-7-2-r1';
      await expectLater(
        repo.start('uzh-7-1-r1', 'test', CancelToken()),
        throwsA(isA<InvalidApiResponseException>()),
      );
      lesson = fixture('lesson1');
      jsonRows(lesson['questions']);
      (lesson['questions'] as List).first['response_kind'] = 'free_essay';
      await expectLater(
        repo.start('uzh-7-1-r1', 'test', CancelToken()),
        throwsA(isA<InvalidApiResponseException>()),
      );
    },
  );

  testWidgets(
    'five grades remain selectable with the verified scanned grade8 book',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, scale: 2);
      for (final grade in [8, 9, 10, 11, 7]) {
        final picker = find.byType(DropdownButtonFormField<int>);
        await tester.ensureVisible(picker);
        await tester.tap(picker);
        await tester.pumpAndSettle();
        await tester.tap(find.text('$grade-sinf').last);
        await tester.pumpAndSettle();
        expect(requests.last.queryParameters['grade'], grade);
        if (grade == 8) {
          expect(find.text('Manba kutilmoqda'), findsNothing);
          expect(find.text('Darsni ochish'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('teaching cards and source button open before exercises', (
    tester,
  ) async {
    await mount(tester);
    final button = find.text('Darsni ochish').first;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Mashqlarga o‘tish'), findsOneWidget);
    expect(
      find.text(
        jsonRows((lesson['content'] as Json)['cards']).first['body'] as String,
      ),
      findsOneWidget,
    );
    final source = find.text('Manba sahifalari').first;
    await tester.ensureVisible(source);
    await tester.tap(source);
    await tester.pumpAndSettle();
    expect(find.textContaining('PDF'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network error supports retry without fabricated catalog', (
    tester,
  ) async {
    offline = true;
    await mount(tester);
    expect(find.text('Darsni ochish'), findsNothing);
    final retry = find.text('Qayta urinish');
    expect(retry, findsOneWidget);
    offline = false;
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('Darsni ochish'), findsOneWidget);
  });

  testWidgets(
    'prior paragraph citation shows its own human title at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      lesson = fixture('lesson40');
      // QA transport state only: completed prerequisites expose this later lesson.
      for (final row in catalog['lessons'] as List) {
        row['state'] = row['sequence'] == 40 ? 'available' : 'completed';
      }
      await mount(tester, scale: 2);
      final open = find.text('Darsni ochish');
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      final source = find.text('Manba sahifalari').at(3);
      await tester.ensureVisible(source);
      await tester.pumpAndSettle();
      await tester.tap(source);
      await tester.pumpAndSettle();
      final prior = find.textContaining('Ta’lim tizimi');
      final sheetScroll = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(prior, 180, scrollable: sheetScroll);
      expect(prior, findsOneWidget);
      expect(find.textContaining('uzh-7-topic'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('century answer stays raw text for server grading', (
    tester,
  ) async {
    final q = jsonRows(fixture('lesson29')['questions']).last;
    Json value = {};
    await mount(
      tester,
      child: Scaffold(
        body: HistoryAnswerEditor(
          question: q,
          draft: {},
          enabled: true,
          onChanged: (v) => value = v,
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'XII');
    expect(value, {'value': 'XII'});
  });

  testWidgets(
    'last lesson completes MCQ FRQ and chronology using server feedback',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      lesson = fixture('lesson42');
      for (final row in catalog['lessons'] as List) {
        row['state'] = row['sequence'] == 42 ? 'available' : 'completed';
      }
      final feedback = fixture('feedback42')['responses'] as Json;
      dio.httpClientAdapter = Adapter((r) {
        requests.add(r);
        if (r.path.endsWith('/catalog')) return reply(200, catalog);
        if (r.path.endsWith('/start')) return reply(200, lesson);
        if (r.path.endsWith('/answers')) {
          return reply(200, feedback[(r.data as Json)['assessment_key']]);
        }
        if (r.path.endsWith('/complete')) return reply(200, fixture('result'));
        throw StateError('Unexpected ${r.path}');
      });
      Future<void> press(String label, {bool twice = false}) async {
        final target = find.text(label);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        if (twice) await tester.tap(target);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await mount(tester, scale: 2);
      await press('Darsni ochish');
      // Exercises start only after the actual teaching cards and rubric.
      final cards = jsonRows((lesson['content'] as Json)['cards']);
      await tester.ensureVisible(find.text(cards.last['body'] as String));
      expect(tester.takeException(), isNull);
      await press('Mashqlarga o‘tish');
      final choices = [
        'Lavvohlik',
        'Sahhoflik',
        'Nasta’liq',
        'Kamoliddin Behzod',
      ];
      final rawNames = ['Mahmud Muzahhib', 'Sultonali Mashhadiy'];
      final questions = jsonRows(lesson['questions']);
      for (var index = 0; index < questions.length; index++) {
        final question = questions[index];
        if (index < 4) {
          await press(choices[index]);
        } else if (index < 6) {
          await tester.ensureVisible(find.byType(TextFormField));
          await tester.enterText(
            find.byType(TextFormField),
            rawNames[index - 4],
          );
          await tester.pumpAndSettle();
        } else {
          final items = jsonRows(question['items']);
          for (final id in ['e1', 'e2', 'e3']) {
            await press(
              items.singleWhere((item) => item['id'] == id)['label'] as String,
            );
          }
        }
        await press('Tekshirish', twice: true);
        expect(find.text('To‘g‘ri!'), findsOneWidget);
        expect(
          find.text((feedback[question['key']] as Json)['feedback'] as String),
          findsOneWidget,
        );
        expect(
          requests.where((r) => r.path.endsWith('/answers')).length,
          index + 1,
        );
        if (index == 4 || index == 5) {
          expect((requests.last.data as Json)['answer'], {
            'value': rawNames[index - 4],
          });
        }
        await press('Davom etish');
      }
      await press('Natijani saqlash', twice: true);
      expect(find.text('Dars yakunlandi!'), findsOneWidget);
      expect(find.textContaining('7/7 to‘g‘ri • +10 XP'), findsOneWidget);
      expect(requests.where((r) => r.path.endsWith('/complete')).length, 1);
    },
  );

  testWidgets('scanned grade8 opens separately without a grade7 prerequisite', (
    tester,
  ) async {
    lesson = fixture('grade8_lesson1');
    await mount(tester);
    final picker = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('8-sinf').last);
    await tester.pumpAndSettle();
    final button = find.text('Darsni ochish');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Dashti Qipchoqdagi siyosiy vaziyat'), findsOneWidget);
    expect(requests.last.path, contains('uzh-8-1-r1'));
    expect(find.text('Mashqlarga o‘tish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'grade9 opens separately with the original combined paragraph numbering',
    (tester) async {
      lesson = fixture('grade9_lesson1');
      await mount(tester);
      final picker = find.byType(DropdownButtonFormField<int>);
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('9-sinf').last);
      await tester.pumpAndSettle();
      final button = find.text('Darsni ochish');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'XIX asr o‘rtalarida O‘rta Osiyo davlatlarining hududi va aholisi',
        ),
        findsOneWidget,
      );
      expect(requests.last.path, contains('uzh-9-1-r1'));
      expect(find.text('Mashqlarga o‘tish'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (grade, count) in [(8, 41), (9, 20)]) {
    for (var n = 1; n <= count; n++) {
      testWidgets(
        'grade$grade lesson $n keeps raw names and fits chronology at large text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final dto = fixture('grade${grade}_lesson$n');
          for (final q in jsonRows(dto['questions'])) {
            Json value = {};
            await mount(
              tester,
              scale: 2,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: HistoryAnswerEditor(
                    question: q,
                    draft: {},
                    enabled: true,
                    onChanged: (v) => value = v,
                  ),
                ),
              ),
            );
            if (q['response_kind'] == 'short_text') {
              await tester.enterText(
                find.byType(TextFormField),
                "  Qutlug' Nigorxonim  ",
              );
              expect(value, {'value': "  Qutlug' Nigorxonim  "});
            } else if (q['response_kind'] == 'ordering') {
              for (final row in jsonRows(q['items'])) {
                expect(find.text(row['label'] as String), findsOneWidget);
              }
            }
            expect(tester.takeException(), isNull);
          }
          final encoded = jsonEncode(dto);
          expect(encoded, isNot(contains('"grading_spec"')));
          expect(encoded, isNot(contains('"accepted_answers"')));
        },
      );
    }
  }

  for (var n = 1; n <= 42; n++) {
    testWidgets('grade 7 lesson $n short input keeps raw text at 200% scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final q in jsonRows(
        fixture('lesson$n')['questions'],
      ).where((q) => q['response_kind'] == 'short_text')) {
        Json value = {};
        await mount(
          tester,
          scale: 2,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: HistoryAnswerEditor(
                  key: ValueKey(q['key']),
                  question: q,
                  draft: {},
                  enabled: true,
                  onChanged: (v) => value = v,
                ),
              ),
            ),
          ),
        );
        final field = find.byType(TextFormField);
        await tester.enterText(field, "  Sug‘d tili.  ");
        expect(value, {'value': '  Sug‘d tili.  '});
        await tester.enterText(field, '   ');
        expect(value, isEmpty);
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final n in [
    2,
    3,
    4,
    5,
    8,
    10,
    11,
    12,
    13,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    39,
    42,
  ]) {
    testWidgets(
      'lesson $n chronology labels fit a small screen with large text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final q = jsonRows(
          fixture('lesson$n')['questions'],
        ).singleWhere((q) => q['response_kind'] == 'ordering');
        await mount(
          tester,
          scale: 2,
          child: Scaffold(
            body: SingleChildScrollView(
              child: HistoryAnswerEditor(
                question: q,
                draft: {},
                enabled: true,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        for (final row in jsonRows(q['items'])) {
          expect(find.text(row['label'] as String), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
