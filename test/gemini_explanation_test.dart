import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/study_help/study_help.dart';
import 'nvidia_explanation_test.dart' show generated, checked;
import 'release_hardening_test.dart' show Adapter, reply;

Map<String, dynamic> googleAnswer(bool correct) {
  final data = generated('kimyo', correct);
  data['generation']['provider'] = 'gemini';
  data['generation']['model'] = 'gemini-3.1-flash-lite';
  return data;
}

void main() {
  for (final correct in [false, true]) {
    testWidgets(
      'Gemini checked=$correct opens on tap with truthful provider label',
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
                body: StudyHelpButton(contextData: checked, language: 'uz'),
              ),
            ),
          ),
        );
        expect(requests, isEmpty);
        await tester.tap(find.byKey(const ValueKey('question_study_help')));
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
