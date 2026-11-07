import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/features/mathematics/data/math_repository.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_models.dart';

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/mathematics/grade2_part2_batch7.json',
            ).readAsStringSync(),
          )
          as MathJson;
  MathJson logical() =>
      jsonDecode(jsonEncode(fixture['lessons'][3]['initial'])) as MathJson;
  late Dio dio;
  setUp(() => dio = Dio());
  tearDown(() => dio.close(force: true));
  test(
    'bookII activity32 uses its exact source page and legacyI remains valid',
    () {
      final r = MathRepository(dio);
      final doc = logical();
      r.checked(doc, 'attempt');
      expect(doc['content']['cards'].length, 32);
      expect(doc['questions'].length, 43);
      final old =
          jsonDecode(
                File(
                  'test/fixtures/mathematics/grade2_part1_batch8.json',
                ).readAsStringSync(),
              )
              as MathJson;
      for (final row in mathRows(old['lessons'])) {
        r.checked(row['initial'], 'attempt');
      }
      for (final mutate in <void Function(MathJson)>[
        (d) => d['content']['cards'][0]['source_activity']['number'] = 33,
        (d) => d['content']['cards'][0]['source_activity']['pdf_pages'] = [77],
        (d) =>
            d['content']['cards'][0]['source_activity']['printed_pages'] = [72],
        (d) => d['lesson_key'] = 'math-2-1-44-r1',
        (d) =>
            d['content']['cards'][0]['source_activity']['book_id'] = 'unknown',
      ]) {
        final bad = logical();
        mutate(bad);
        expect(() => r.checked(bad, 'attempt'), throwsFormatException);
      }
    },
  );
  test(
    'clock vectors and rosette shapes are bounded; grading keys stay server-side',
    () {
      final doc = logical();
      final r = MathRepository(dio);
      final questions = mathRows(doc['questions']);
      expect((questions[41]['visual'] as Map).keys.toSet(), {
        'type',
        'hour_hand',
        'minute_hand',
        'mirrored',
      });
      expect(jsonEncode(doc), isNot(contains('"grading"')));
      expect(jsonEncode(doc), isNot(contains('"expected"')));
      for (final mutate in <void Function(MathJson)>[
        (d) => d['questions'][41]['visual']['minute_hand'] = [0, 0],
        (d) => d['questions'][41]['visual']['hour_hand'] = [double.infinity, 0],
        (d) => d['questions'][41]['visual']['expected'] = '35',
        (d) =>
            d['questions'][42]['visual']['patterns'][0]['colors'] = ['yellow'],
        (d) => d['questions'][42]['visual']['patterns'][0]['id'] = '',
        (d) => d['questions'][42]['visual']['patterns'] = ['invalid'],
      ]) {
        final bad = logical();
        mutate(bad);
        expect(() => r.checked(bad, 'attempt'), throwsFormatException);
      }
    },
  );
  testWidgets(
    'mirrored whole clock and seven rosettes render with semantic choices',
    (t) async {
      final doc = logical();
      final questions = mathRows(doc['questions']);
      String? selected;
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final semantics = t.ensureSemantics();

      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    MathBoard(scene: questions[41]['visual']),
                    MathBoard(
                      scene: questions[42]['visual'],
                      onSelect: (v) => selected = v,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.bySemanticsLabel(RegExp('Ko‘zgudagi aks')), findsOneWidget);
      final g = find.text('G');
      await t.ensureVisible(g);
      await t.pumpAndSettle();
      await t.tap(g);
      expect(selected, 'g');
      expect(t.takeException(), isNull);
      semantics.dispose();
    },
  );
}
