import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_switch_sheet.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_grade_card.dart';
import 'package:ilm_ai_flutter/features/study_help/study_help.dart';
import 'release_hardening_test.dart' show Adapter, reply;

class DeferredHelp extends StudyHelpRepository {
  DeferredHelp(super.dio);
  final result = Completer<Map<String, dynamic>>();
  CancelToken? cancellation;
  @override
  Future<Map<String, dynamic>> ask(
    StudyHelpContext context,
    String language,
    String message,
    CancelToken cancel,
  ) {
    cancellation = cancel;
    return result.future;
  }
}

final subjects = [
  for (final (slug, grades) in [
    ('biologiya', [5, 6, 7, 8, 9, 10, 11]),
    ('fizika', [6, 7, 8, 9, 10, 11]),
    ('kimyo', [7, 8, 9, 10, 11]),
    ('ozbekiston_tarixi', [7, 8, 9, 10, 11]),
    ('jahon_tarixi', [6, 7, 8, 9, 10, 11]),
    ('matematika', <int>[]),
  ])
    SkillSubject(
      id: 1,
      slug: slug,
      nameUz: slug,
      nameRu: slug,
      nameEn: slug,
      grades: grades,
      available: grades.isNotEmpty,
    ),
];

Map<String, dynamic> evidence() => {
  'mode': 'reviewed_evidence',
  'attempt_id': 'owned',
  'question_key': 'q',
  'subject': 'kimyo',
  'grade': 7,
  'title': 'Dars mavzusi',
  'provider_status': 'unconfigured',
  'source_refs': [],
  'answered': true,
  'evidence': [
    {
      'id': 'e1',
      'kind': 'feedback',
      'text': 'Tekshirilgan dars izohi',
      'source_refs': [],
    },
  ],
};

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'quick switch selects subject and grade with 200% text, dark=$dark',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 740));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SubjectSelection? selected;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(dark ? darkColors : lightColors),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    selected = await showSubjectSwitcher(
                      context,
                      subjects: subjects,
                      language: 'uz',
                      grade: 6,
                      currentSubject: 'fizika',
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('switch_kimyo')),
          120,
          scrollable: find.byType(Scrollable).last,
        );
        expect(
          tester
              .widget<SubjectGradeCard>(
                find.byKey(const ValueKey('switch_kimyo')),
              )
              .canStudy,
          isFalse,
        );
        expect(
          tester
              .widget<SubjectGradeCard>(
                find.byKey(const ValueKey('switch_fizika')),
              )
              .selected,
          isTrue,
        );
        await tester.tap(find.byKey(const ValueKey('switch_grade')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('7-sinf').last);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('switch_kimyo')),
          120,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('switch_kimyo')));
        await tester.pumpAndSettle();
        expect(selected?.subject.slug, 'kimyo');
        expect(selected?.grade, 7);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('reviewed fallback, follow up, keyboard and theme dark=$dark', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8930'));
      dio.httpClientAdapter = Adapter((request) {
        requests.add(request);
        return reply(200, evidence());
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(1),
            studyHelpRepositoryProvider.overrideWithValue(
              StudyHelpRepository(dio),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(dark ? darkColors : lightColors),
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 740),
                  textScaler: TextScaler.linear(2),
                  viewInsets: EdgeInsets.only(bottom: 240),
                ),
                child: const StudyHelpSheet(
                  contextData: StudyHelpContext(
                    subject: 'kimyo',
                    grade: 7,
                    attemptId: 'owned',
                    questionKey: 'q',
                  ),
                  language: 'uz',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('study_help_status')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('AI hozir ulanmagan'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Tekshirilgan dars izohi'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tekshirilgan dars izohi'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Shu mavzuni tushuntir');
      await tester.tap(find.byTooltip('Yuborish'));
      await tester.pumpAndSettle();
      expect(requests.length, 2);
      expect((requests.last.data as Map)['question_key'], 'q');
      expect((requests.last.data as Map)['message'], 'Shu mavzuni tushuntir');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dio.close();
    });
  }
  testWidgets('network failure has retry', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8930'));
    var fail = true;
    dio.httpClientAdapter = Adapter((request) {
      if (fail) {
        throw DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
        );
      }
      return reply(200, evidence());
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(1),
          studyHelpRepositoryProvider.overrideWithValue(
            StudyHelpRepository(dio),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: const Scaffold(
            body: StudyHelpSheet(
              contextData: StudyHelpContext(
                subject: 'kimyo',
                grade: 7,
                attemptId: 'owned',
                questionKey: 'q',
                checked: true,
              ),
              language: 'uz',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('study_help_error')), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Qayta urinish'));
    await tester.pumpAndSettle();
    expect(find.text('Tekshirilgan dars izohi'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    dio.close();
  });
  testWidgets('reviewed help displays a repeated whole passage only once', (
    tester,
  ) async {
    final data = evidence();
    data['evidence'] = [
      {'id': 'e1', 'text': 'To‘g‘ri. Tekshirilgan izoh.', 'source_refs': []},
      {'id': 'e2', 'text': 'Tekshirilgan izoh.', 'source_refs': []},
      {'id': 'e3', 'text': 'Keyingi qadam.', 'source_refs': []},
    ];
    final dio = Dio()..httpClientAdapter = Adapter((_) => reply(200, data));
    addTearDown(() => dio.close(force: true));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(1),
          studyHelpRepositoryProvider.overrideWithValue(
            StudyHelpRepository(dio),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: const Scaffold(
            body: StudyHelpSheet(
              contextData: StudyHelpContext(
                subject: 'kimyo',
                grade: 7,
                attemptId: 'owned',
                questionKey: 'q',
                checked: true,
              ),
              language: 'uz',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('To‘g‘ri. Tekshirilgan izoh.'), findsOneWidget);
    expect(
      find.text('Tekshirilgan izoh.'),
      reviewedLearning ? findsNothing : findsOneWidget,
    );
    expect(find.text('Keyingi qadam.'), findsOneWidget);
    expect(
      (data['evidence'] as List).length,
      3,
    ); // No server evidence mutation.
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('repository rejects another question from the same subject', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8930'));
    dio.httpClientAdapter = Adapter((r) => reply(200, evidence()));
    await expectLater(
      StudyHelpRepository(dio).ask(
        const StudyHelpContext(
          subject: 'kimyo',
          grade: 7,
          attemptId: 'owned',
          questionKey: 'another',
        ),
        'uz',
        '',
        CancelToken(),
      ),
      throwsFormatException,
    );
    dio.close();
  });
  test('repository rejects a response for another subject', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8930'));
    dio.httpClientAdapter = Adapter((r) => reply(200, evidence()));
    await expectLater(
      StudyHelpRepository(dio).ask(
        const StudyHelpContext(subject: 'fizika', grade: 7),
        'uz',
        '',
        CancelToken(),
      ),
      throwsFormatException,
    );
    dio.close();
  });
  testWidgets(
    'changing account cancels and closes the outstanding help panel',
    (tester) async {
      final user = StateProvider<int?>((ref) => 1);
      final dio = Dio();
      final repository = DeferredHelp(dio);
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(user)),
          studyHelpRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const Scaffold(
              body: StudyHelpButton(
                contextData: StudyHelpContext(
                  subject: 'kimyo',
                  grade: 7,
                  attemptId: 'owned',
                  questionKey: 'q',
                  checked: true,
                ),
                language: 'uz',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('question_study_help')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(repository.cancellation, isNotNull);
      container.read(user.notifier).state = 2;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(repository.cancellation!.isCancelled, isTrue);
      expect(find.byType(StudyHelpSheet), findsNothing);
      repository.result.complete(evidence());
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      dio.close();
    },
  );
  testWidgets('cancel selection does not apply anything', (tester) async {
    SubjectSelection? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(lightColors),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showSubjectSwitcher(
                  context,
                  subjects: subjects,
                  language: 'uz',
                  grade: 7,
                  currentSubject: 'kimyo',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(ListView))).pop();
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });
}
