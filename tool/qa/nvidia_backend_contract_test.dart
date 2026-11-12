import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/study_help/study_help.dart';
import '../../test/release_hardening_test.dart' show Adapter, reply;

// Explicit local cross-repository contract run. This is not Android/live AI.
// No optional skip: a missing/unaccepted backend receipt must fail the run.
void main() {
  const filename = String.fromEnvironment('NVIDIA_CONTRACT_FILE');
  if (filename.isEmpty) {
    test('requires accepted source-bound backend contract file', () {
      fail('Provide NVIDIA_CONTRACT_FILE for this explicit local QA command.');
    });
    return;
  }
  final contract = jsonDecode(File(filename).readAsStringSync()) as Map;
  if (contract['real_provider_requests'] != false ||
      contract['source'] != 'accepted reviewed backend synthetic transport') {
    throw const FormatException('Wrong backend contract scope');
  }
  final cases = contract['cases'] as List;
  if (cases.isEmpty) throw const FormatException('No accepted backend cases');
  for (var index = 0; index < cases.length; index++) {
    final record = cases[index] as Map;
    final data = Map<String, dynamic>.from(record['response'] as Map);
    testWidgets(
      'backend contract $index ${data['subject']} ${record['kind']} correct=${data['is_correct']}',
      (tester) async {
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
              home: Scaffold(
                body: StudyHelpSheet(
                  contextData: StudyHelpContext(
                    subject: data['subject'] as String,
                    grade: data['grade'] as int,
                    lessonKey: data['lesson_key'] as String?,
                    attemptId: data['attempt_id'] as String,
                    questionKey: data['question_key'] as String,
                    checked: true,
                  ),
                  language: 'uz',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // The sheet scrolls to its newest reply after loading. Source-bound
        // questions are longer than small synthetic fixtures, so observe the
        // status before scrolling it out of the lazy list's built viewport.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('study_help_status')),
          -120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('NVIDIA AI yaratgan izoh.'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('nvidia_generated_explanation')),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        for (final paragraph in data['generation']['paragraphs'] as List) {
          expect(find.text(paragraph['text'] as String), findsOneWidget);
        }
        expect(find.byKey(const ValueKey('study_help_error')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
