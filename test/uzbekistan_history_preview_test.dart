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
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'))
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
      for (var i = 1; i <= 10; i++) {
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
    'five grades remain selectable; missing scan has an honest empty state',
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
        if (grade == 8) expect(find.text('Manba kutilmoqda'), findsOneWidget);
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

  for (var n = 1; n <= 10; n++) {
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

  for (final n in [2, 3, 4, 5, 8, 10]) {
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
