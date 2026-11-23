import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/study_help/study_help.dart';
import 'package:ilm_ai_flutter/features/study_help/subject_tutor.dart';
import 'nvidia_explanation_test.dart' show generated, checked;
import 'release_hardening_test.dart' show Adapter, reply;
import 'study_help_test.dart' show evidence;

Map<String, dynamic> googleAnswer(bool correct) {
  final data = generated('kimyo', correct);
  data['generation']['provider'] = 'gemini';
  data['generation']['model'] = 'gemini-3.1-flash-lite';
  return data;
}

void main() {
  for (final outcome in ['correct', 'wrong']) {
    testWidgets(
      'checked $outcome question opens contextual Gemini conversation on tap',
      (tester) async {
        final requests = <RequestOptions>[];
        final dio = Dio()
          ..httpClientAdapter = Adapter((request) {
            requests.add(request);
            if (request.path.endsWith('/ai-answer-report')) {
              return reply(200, {'reported': true});
            }
            final data = request.data as Map;
            final paragraphs = [
              {
                'text': 'Synthetic contextual response for $outcome.',
                'evidence_ids': ['fixture'],
              },
            ];
            return reply(200, {
              'mode': 'subject_chat',
              'status': 'answered',
              'subject': data['subject'],
              'grade': data['grade'],
              'conversation_id': data['conversation_id'],
              'request_id': data['request_id'],
              'report_receipt': 'authorized-fixture-proof',
              'generation': {
                'provider': 'gemini',
                'model': 'gemini-3.1-flash-lite',
                'http_status': 200,
                'status': 'answered',
                'language': 'uz',
                'grounding':
                    'citations_and_quotes_checked_not_semantic_verification',
                'paragraphs': paragraphs,
              },
              'evidence': [
                {'id': 'fixture'},
              ],
              'paragraphs': paragraphs,
            });
          });
        addTearDown(() => dio.close(force: true));
        Widget screen(String questionKey) => ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(101),
            dioProvider.overrideWithValue(dio),
            subjectTutorRepositoryProvider.overrideWithValue(
              SubjectTutorRepository(dio),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StudyHelpButton(
                contextData: StudyHelpContext(
                  subject: 'kimyo',
                  grade: 7,
                  attemptId: 'owned',
                  questionKey: questionKey,
                  checked: true,
                ),
                language: 'uz',
              ),
            ),
          ),
        );
        await tester.pumpWidget(screen(outcome));
        expect(requests, isEmpty);
        await tester.tap(find.byKey(const ValueKey('question_study_help')));
        await tester.pumpAndSettle();
        expect(requests, hasLength(1));
        expect(requests.single.path, endsWith('/subject-chat'));
        expect((requests.single.data as Map)['question_key'], outcome);
        expect((requests.single.data as Map)['attempt_id'], 'owned');
        expect((requests.single.data as Map)['checked'], isTrue);
        expect(
          find.text('Synthetic contextual response for $outcome.'),
          findsOneWidget,
        );
        expect(find.byType(SubjectTutorScreen), findsOneWidget);
        final report = find.text('AI javobidan shikoyat qilish');
        await tester.ensureVisible(report);
        await tester.tap(report);
        await tester.pumpAndSettle();
        expect(requests, hasLength(2));
        expect(requests.last.path, endsWith('/ai-answer-report'));
        expect(requests.last.data, {
          'receipt': 'authorized-fixture-proof',
          'paragraphs': ['Synthetic contextual response for $outcome.'],
        });
        expect(find.text('Shikoyat yuborildi'), findsOneWidget);
        await tester.pumpWidget(screen('next-question'));
        await tester.pumpAndSettle();
        expect(find.byType(SubjectTutorScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'generated explanation reports its text and can retry on failure',
    (tester) async {
      final data = googleAnswer(true)..['report_receipt'] = 'answer-proof';
      final reports = <RequestOptions>[];
      final dio = Dio()
        ..httpClientAdapter = Adapter((request) {
          if (request.path.endsWith('/ai-answer-report')) {
            reports.add(request);
            return reports.length == 1
                ? reply(503, {})
                : reply(200, {'reported': true});
          }
          return reply(200, data);
        });
      addTearDown(() => dio.close(force: true));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(101),
            dioProvider.overrideWithValue(dio),
            studyHelpRepositoryProvider.overrideWithValue(
              StudyHelpRepository(dio),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StudyHelpSheet(contextData: checked, language: 'en'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text('Report AI answer');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.text('The report could not be sent. Try again.'),
        findsOneWidget,
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(reports, hasLength(2));
      expect(reports.last.data, {
        'receipt': 'answer-proof',
        'paragraphs': [
          for (final paragraph in data['generation']['paragraphs'])
            paragraph['text'],
        ],
      });
      expect(find.text('Report sent'), findsOneWidget);
    },
  );
  testWidgets('configured provider failure is not labeled as disconnected', (
    tester,
  ) async {
    final data = evidence()..['provider_status'] = 'unavailable';
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
        child: const MaterialApp(
          home: Scaffold(
            body: StudyHelpSheet(contextData: checked, language: 'uz'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AI javobidan shikoyat qilish'), findsNothing);
    expect(
      find.textContaining('AI izohini hozir tayyorlab bo‘lmadi.'),
      findsOneWidget,
    );
    expect(find.textContaining('AI hozir ulanmagan'), findsNothing);
    expect(find.text('Tekshirilgan dars izohi'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final correct in [false, true]) {
    testWidgets(
      'legacy Gemini correct=$correct retains truthful provider label',
      (tester) async {
        final requests = <RequestOptions>[];
        final dio = Dio()
          ..httpClientAdapter = Adapter((request) {
            requests.add(request);
            return reply(200, googleAnswer(correct));
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
            child: const MaterialApp(
              home: Scaffold(
                body: StudyHelpSheet(contextData: checked, language: 'uz'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(requests.single.headers['X-ILM-Study-Help'], 'reviewed-text-v2');
        expect(find.text('Gemini yaratgan izoh.'), findsOneWidget);
        expect(find.text('NVIDIA AI yaratgan izoh.'), findsNothing);
        expect(
          find.byKey(const ValueKey('nvidia_generated_explanation')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  for (final pair in [
    ['gemini', 'meta/muse-glimmer-30b'],
    ['nvidia', 'gemini-3.1-flash-lite'],
    ['gemini', 'unreviewed-model'],
  ]) {
    test('rejects mismatched provider/model $pair', () async {
      final data = googleAnswer(true);
      data['generation']['provider'] = pair[0];
      data['generation']['model'] = pair[1];
      final dio = Dio()..httpClientAdapter = Adapter((_) => reply(200, data));
      addTearDown(() => dio.close(force: true));
      await expectLater(
        StudyHelpRepository(dio).ask(checked, 'uz', '', CancelToken()),
        throwsFormatException,
      );
    });
  }
}
