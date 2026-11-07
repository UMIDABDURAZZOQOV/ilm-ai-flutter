import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';

void main() {
  for (final answer in ['', 'Kimyo']) {
    testWidgets('progress does not merge into FRQ value: $answer', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController(text: answer);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: Column(
                    children: [
                      const Text('10/12 Independent practice'),
                      const DuoProgressBar(value: .75),
                      const Text('Write the name of the science.'),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Short answer',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final input = tester
          .getSemantics(find.byType(EditableText))
          .getSemanticsData();
      final progress = tester
          .getSemantics(find.byType(DuoProgressBar))
          .getSemanticsData();
      semantics.dispose();
      expect(input.value, answer);
      expect(progress.value, '75%');
      expect(progress.label, isEmpty);
      final boundary = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(DuoProgressBar),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(boundary.container, isTrue);
      expect(
        find.bySemanticsLabel('Write the name of the science.'),
        findsOneWidget,
      );
      expect(input.label, contains('Short answer'));
    });
  }
}
