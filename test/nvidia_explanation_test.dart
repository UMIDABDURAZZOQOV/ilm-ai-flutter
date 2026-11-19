import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/study_help/study_help.dart';
import 'package:ilm_ai_flutter/features/study_help/subject_tutor.dart';
import 'release_hardening_test.dart' show Adapter, reply;
import 'study_help_test.dart' show evidence;

// Synthetic protocol/widget fixtures, never live NVIDIA or real Android proof.
Map<String, dynamic> generated(String subject, bool correct) {
  final data = evidence();
  data.addAll({
    'mode': 'generated_explanation',
    'subject': subject,
    'is_correct': correct,
    'provider_status': 'generated',
    'generation': {
      'provider': 'nvidia',
      'model': 'meta/muse-glimmer-30b',
      'usage': 'internal_evaluation',
      'http_status': 200,
      'request_id': ''.padLeft(32, 'a'),
      'request_sha256': ''.padLeft(64, 'b'),
      'response_sha256': ''.padLeft(64, 'c'),
      'language': 'uz',
      'is_correct': correct,
      'grounding': 'citations_and_quotes_checked_not_semantic_verification',
      'paragraphs': [
        {
          'text':
              'Model matnining sintetik protokol sinovi: $subject, $correct.',
          'evidence_ids': ['e1'],
        },
      ],
    },
  });
  (data['evidence'] as List).first['source_refs'] = [
    {
      'book_id': 'synthetic-reviewed-fixture',
      'printed_pages': [5],
    },
  ];
  return data;
}

const checked = StudyHelpContext(
  subject: 'kimyo',
  grade: 7,
  attemptId: 'owned',
  questionKey: 'q',
  checked: true,
);

void main() {
  for (final subject in [
    'biologiya',
    'fizika',
    'kimyo',
    'ozbekiston_tarixi',
    'jahon_tarixi',
  ]) {
    for (final correct in [false, true]) {
      for (final dark in [false, true]) {
        testWidgets(
          'generated $subject correct=$correct dark=$dark is distinct from reviewed fallback',
          (tester) async {
            final data = generated(subject, correct);
            final requests = <RequestOptions>[];
            final dio = Dio()
              ..httpClientAdapter = Adapter((request) {
                requests.add(request);
                return reply(200, data);
              });
            addTearDown(() => dio.close(force: true));
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  currentUserIdProvider.overrideWithValue(101),
                  studyHelpRepositoryProvider.overrideWithValue(
                    StudyHelpRepository(dio),
                  ),
                ],
                child: MaterialApp(
                  theme: buildAppTheme(dark ? darkColors : lightColors),
                  home: Scaffold(
                    body: StudyHelpSheet(
                      contextData: StudyHelpContext(
                        subject: subject,
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
            // Legacy generated-explanation presentation remains supported;
            // the question button now opens the separately tested tutor chat.
            await tester.pumpAndSettle();
            expect(requests, hasLength(1));
            expect(
              requests.single.headers['X-ILM-Study-Help'],
              'reviewed-text-v2',
            );
            expect(
              (requests.single.data as Map).containsKey('explanation_version'),
              isFalse,
            );
            expect(
              find.byKey(const ValueKey('nvidia_generated_explanation')),
              findsOneWidget,
            );
            expect(find.text('NVIDIA AI yaratgan izoh.'), findsOneWidget);
            expect(
              find.text(
                'Model matnining sintetik protokol sinovi: $subject, $correct.',
              ),
              findsOneWidget,
            );
            expect(find.text('Tekshirilgan dars izohi'), findsOneWidget);
            expect(find.textContaining('AI hozir ulanmagan.'), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }

  final corruptions = <String, void Function(Map<String, dynamic>)>{
    'missing generation': (d) => d.remove('generation'),
    'wrong provider': (d) => d['generation']['provider'] = 'other',
    'wrong model': (d) => d['generation']['model'] = 'other/model',
    'wrong question': (d) => d['question_key'] = 'other-question',
    'wrong subject': (d) => d['subject'] = 'fizika',
    'unchecked response': (d) => d['answered'] = false,
    'wrong grading flag': (d) => d['generation']['is_correct'] = false,
    'wrong language': (d) => d['generation']['language'] = 'en',
    'wrong status': (d) => d['generation']['http_status'] = 503,
    'no provenance': (d) => d['generation']['request_sha256'] = '',
    'invented source': (d) =>
        d['generation']['paragraphs'][0]['evidence_ids'] = ['invented'],
    'unreferenced source': (d) => d['evidence'][0]['source_refs'] = [],
    'too much output': (d) =>
        d['generation']['paragraphs'][0]['text'] = ''.padLeft(1501, 'x'),
    'fallback mislabeled': (d) => d['mode'] = 'reviewed_evidence',
  };
  for (final entry in corruptions.entries) {
    test('repository rejects ${entry.key}', () async {
      final data = generated('kimyo', true);
      entry.value(data);
      final dio = Dio()..httpClientAdapter = Adapter((_) => reply(200, data));
      addTearDown(() => dio.close(force: true));
      await expectLater(
        StudyHelpRepository(dio).ask(checked, 'uz', '', CancelToken()),
        throwsFormatException,
      );
    });
  }

  test(
    'a generated response cannot be used before a submitted answer',
    () async {
      final dio = Dio()
        ..httpClientAdapter = Adapter(
          (_) => reply(200, generated('kimyo', true)),
        );
      addTearDown(() => dio.close(force: true));
      await expectLater(
        StudyHelpRepository(dio).ask(
          const StudyHelpContext(
            subject: 'kimyo',
            grade: 7,
            attemptId: 'owned',
            questionKey: 'q',
          ),
          'uz',
          '',
          CancelToken(),
        ),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'AI stays hidden before submission and failed network offers retry',
    (tester) async {
      final dio = Dio()
        ..httpClientAdapter = Adapter(
          (_) => reply(503, {'detail': 'synthetic upstream failure'}),
        );
      addTearDown(() => dio.close(force: true));
      Widget page(bool done) => ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(101),
          studyHelpRepositoryProvider.overrideWithValue(
            StudyHelpRepository(dio),
          ),
          subjectTutorRepositoryProvider.overrideWithValue(
            SubjectTutorRepository(dio),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(
            body: StudyHelpButton(
              contextData: StudyHelpContext(
                subject: 'kimyo',
                grade: 7,
                attemptId: 'owned',
                questionKey: 'q',
                checked: done,
              ),
              language: 'uz',
            ),
          ),
        ),
      );
      await tester.pumpWidget(page(false));
      expect(find.byKey(const ValueKey('question_study_help')), findsNothing);
      await tester.pumpWidget(page(true));
      await tester.tap(find.byKey(const ValueKey('question_study_help')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tutor_error')), findsOneWidget);
      expect(find.text('Qayta urinish'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('nvidia_generated_explanation')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  for (final size in [const Size(360, 740), const Size(740, 360)]) {
    testWidgets(
      'generated help keeps keyboard composer reachable at 200% $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final data = generated('kimyo', false);
        final dio = Dio()..httpClientAdapter = Adapter((_) => reply(200, data));
        addTearDown(() => dio.close(force: true));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWithValue(101),
              studyHelpRepositoryProvider.overrideWithValue(
                StudyHelpRepository(dio),
              ),
            ],
            child: MaterialApp(
              theme: buildAppTheme(lightColors),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 240),
                ),
                child: child!,
              ),
              home: const Scaffold(
                body: StudyHelpSheet(contextData: checked, language: 'uz'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(
          find.byType(TextField),
          'Shu savolni tushuntiring',
        );
        await tester.ensureVisible(find.byTooltip('Yuborish'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Yuborish').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  for (final size in [const Size(360, 740), const Size(740, 360)]) {
    testWidgets('generated text scrolls at 200% text size $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data = generated('kimyo', true);
      final dio = Dio()..httpClientAdapter = Adapter((_) => reply(200, data));
      addTearDown(() => dio.close(force: true));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(101),
            studyHelpRepositoryProvider.overrideWithValue(
              StudyHelpRepository(dio),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: StudyHelpSheet(contextData: checked, language: 'uz'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('nvidia_generated_explanation')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('nvidia_generated_explanation')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
