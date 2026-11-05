import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/mathematics/data/math_repository.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_models.dart';
import 'package:ilm_ai_flutter/features/mathematics/presentation/math_preview_screen.dart';
import 'release_hardening_test.dart' show Adapter, reply;

void main() {
  final data =
      jsonDecode(
            File(
              'test/fixtures/mathematics/grade1_part4_batch3.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    122: ['4', '4', 'b', '1', 'a', '22', '8', '12'],
    123: ['a', 'b', 'a', '3', 'b', 'chegara', '47', 'b'],
    124: ['a', 'b', 'a', 'b', 'c', 'teng', '18', 'b'],
    125: ['7', '5', '2', '21', 'b', '4', '11', '6'],
    126: ['2', '0', 'a', 'b', 'c', 'simmetriya o‘qi', '48', 'a'],
  };
  late Dio dio;
  late List<RequestOptions> requests;
  bool catalogOffline = false, locked = false;
  setUp(() {
    requests = [];
    catalogOffline = false;
    locked = false;
    SharedPreferences.setMockInitialValues({});
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8892'))
      ..transformer = SyncTransformer()
      ..httpClientAdapter = Adapter((r) {
        requests.add(r);
        if (r.path.endsWith('/catalog')) {
          final part = r.queryParameters['part'] ?? 1;
          if (part == 4 && catalogOffline) {
            throw DioException(
              requestOptions: r,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return reply(
            200,
            part == 1
                ? data['catalog1']
                : part == 2
                ? data['catalog2']
                : part == 3
                ? data['catalog3']
                : locked
                ? data['strict_catalog']
                : data['completed_catalog'],
          );
        }
        if (r.path.endsWith('/start')) {
          final row = mathRows(data['lessons']).firstWhere(
            (v) => r.path.contains(v['initial']['lesson_key'] as String),
          );
          return reply(200, row['initial']);
        }
        if (r.path.endsWith('/answers')) {
          final feedback = mathRows(data['lessons'])
              .expand((v) => mathRows(v['feedback']))
              .firstWhere((v) => v['question_id'] == r.data['question_id']);
          return reply(200, {...feedback, 'request_id': r.data['request_id']});
        }
        if (r.path.endsWith('/complete')) {
          final row = mathRows(data['lessons']).firstWhere(
            (v) => r.path.contains(v['initial']['attempt_id'] as String),
          );
          return reply(200, row['result']);
        }
        throw StateError('Unexpected math request');
      });
  });
  tearDown(() => dio.close(force: true));
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          preferences: await PrefsService.create(),
          userId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      160,
      maxScrolls: 200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> part4(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('math-book-1-1')));
    await tester.tap(find.text('1-sinf · IV qism').last);
    await tester.pumpAndSettle();
  }

  test(
    'all four books and explicit server QA metadata satisfy client contract',
    () {
      final repo = MathRepository(dio);
      for (final c in [
        'catalog1',
        'catalog2',
        'catalog3',
        'catalog4',
        'completed_catalog',
        'locked_catalog',
      ]) {
        repo.checked(data[c], 'catalog');
      }
      for (final row in mathRows(data['lessons'])) {
        repo.checked(row['initial'], 'attempt');
        repo.checked(row['result'], 'result');
        for (final f in mathRows(row['feedback'])) {
          repo.checked(f, 'answer');
        }
      }
    },
  );
  for (final n in keys.keys) {
    testWidgets('book4 source$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await part4(tester);
      final initial =
          data['lessons'][[122, 123, 124, 125, 126].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 122) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('IV qism, 2023. PDF: 25–26. Bosma: 24–25.'),
          findsOneWidget,
        );
      }
      for (final _ in initial['content']['cards'] as List) {
        await tap(tester, find.text('Davom etish'));
      }
      await tap(tester, find.text('Birga yechamiz'));
      final questions = mathRows(initial['questions']);
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i], answer = keys[n]![i];
        if (q['response_kind'] == 'choice') {
          final option = mathRows(
            q['choices'],
          ).firstWhere((c) => c['id'] == answer);
          await tap(
            tester,
            find.widgetWithText(ChoiceChip, option['label'] as String),
          );
        } else if (q['response_kind'] == 'ordering') {
          for (final id in answer as List) {
            final item = mathRows(q['items']).firstWhere((v) => v['id'] == id);
            await tap(
              tester,
              find.widgetWithText(ActionChip, item['label'] as String),
            );
          }
        } else {
          await tester.scrollUntilVisible(
            find.byType(TextField),
            160,
            maxScrolls: 100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), answer as String);
          await tester.pumpAndSettle();
        }
        await tap(tester, find.text('Tekshirish'));
        expect(find.text('Topding!'), findsOneWidget);
        await tap(tester, find.text('Davom etish'));
      }
      await tap(tester, find.text('Natijani saqlash'));
      expect(find.text('Mashq yakunlandi!'), findsOneWidget);
      expect(
        requests
            .lastWhere((r) => r.path.endsWith('/catalog'))
            .queryParameters['part'],
        4,
      );
      final submitted = requests
          .where((r) => r.path.endsWith('/answers'))
          .toList();
      expect(submitted, hasLength(8));
      for (var i = 0; i < questions.length; i++) {
        final field =
            {
              'choice': 'choice_id',
              'ordering': 'order',
            }[questions[i]['response_kind']] ??
            'value';
        expect(submitted[i].data['answer'][field], keys[n]![i]);
      }
    });
  }
  Future<void> model(WidgetTester tester, String mode) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(child: MathExplorer(mode: mode)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'four vertices require closing edge and corner incidence differs from unique markers',
    (tester) async {
      await model(tester, 'geometry_quadrilateral');
      expect(find.text('4 uch; 4 tomon; yopiq'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('quad-close')));
      expect(find.text('4 uch; 3 tomon; ochiq'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Romb'));
      await tap(tester, find.byKey(const ValueKey('quad-close')));
      expect(find.text('4 uch; 4 tomon; yopiq'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('quad-room-switch')));
      for (var i = 1; i <= 4; i++) {
        await tap(tester, find.widgetWithText(FilterChip, '$i-burchak'));
      }
      expect(find.text('Turli belgilar: 4'), findsOneWidget);
      for (var i = 1; i <= 4; i++) {
        expect(find.text('$i-devor: 2 ta belgi'), findsOneWidget);
      }
      for (var i = 1; i <= 4; i++) {
        await tap(tester, find.widgetWithText(FilterChip, '$i-devor o‘rtasi'));
      }
      expect(find.text('Turli belgilar: 8'), findsOneWidget);
      for (var i = 1; i <= 4; i++) {
        expect(find.text('$i-devor: 3 ta belgi'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('inside, common interior, boundary and exterior stay distinct', (
    tester,
  ) async {
    await model(tester, 'geometry_regions');
    const expected = {
      'A': 'Chap doira: ichida; o‘ng doira: tashqarisida',
      'B': 'Chap doira: ichida; o‘ng doira: ichida',
      'C': 'Chap doira: tashqarisida; o‘ng doira: ichida',
      'D': 'Chap doira: chegarasida; o‘ng doira: tashqarisida',
      'E': 'Chap doira: tashqarisida; o‘ng doira: tashqarisida',
    };
    for (final row in expected.entries) {
      await tap(tester, find.widgetWithText(ChoiceChip, row.key));
      expect(find.text(row.value), findsOneWidget);
      if (row.key == 'B') {
        expect(
          find.text('Nuqta ikkala doiraning umumiy ichki qismida.'),
          findsOneWidget,
        );
      }
    }
  });
  testWidgets(
    'congruence is intrinsic but current alignment changes; same perimeter is insufficient',
    (tester) async {
      await model(tester, 'geometry_congruent_overlay');
      expect(
        find.text('Shakl va o‘lcham bo‘yicha teng shakllar.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Hozir yo‘nalishlari mos emas'),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const ValueKey('congruence-rotate')));
      expect(find.text('Hozir barcha chegaralar mos keldi.'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'B: 5 × 4 cm'));
      expect(
        find.text('A perimetri: 18 cm; B perimetri: 18 cm'),
        findsOneWidget,
      );
      expect(find.text('Shakl va o‘lcham bo‘yicha teng emas.'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('congruence-rotate')));
      expect(find.text('Shakl va o‘lcham bo‘yicha teng emas.'), findsOneWidget);
    },
  );
  testWidgets('guided tangram uses all seven pieces and does not award XP', (
    tester,
  ) async {
    await model(tester, 'geometry_tangram_guide');
    expect(find.text('Joylashtirildi: 0 / 7'), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      await tap(tester, find.byKey(ValueKey('tangram-$i')));
      expect(find.text('Joylashtirildi: ${i + 1} / 7'), findsOneWidget);
    }
    expect(
      find.textContaining('Kvadrat sxema to‘liq yig‘ildi'),
      findsOneWidget,
    );
    await tap(tester, find.byKey(const ValueKey('tangram-3')));
    expect(find.text('Joylashtirildi: 6 / 7'), findsOneWidget);
    expect(find.textContaining('Kvadrat sxema to‘liq yig‘ildi'), findsNothing);
    expect(requests.where((r) => r.path.endsWith('/complete')), isEmpty);
  });
  test(
    'original vector pieces cover the square exactly without interior overlap',
    () {
      double area(List<Offset> p) {
        var twice = 0.0;
        for (var i = 0; i < p.length; i++) {
          final a = p[i], b = p[(i + 1) % p.length];
          twice += a.dx * b.dy - a.dy * b.dx;
        }
        return twice.abs() / 2;
      }

      bool inside(List<Offset> p, Offset v) {
        var result = false;
        for (var i = 0, j = p.length - 1; i < p.length; j = i++) {
          final a = p[i], b = p[j];
          if ((a.dy > v.dy) != (b.dy > v.dy) &&
              v.dx < (b.dx - a.dx) * (v.dy - a.dy) / (b.dy - a.dy) + a.dx) {
            result = !result;
          }
        }
        return result;
      }

      expect(mathTangramPieces.map((p) => p.length).toList(), [
        3,
        3,
        3,
        4,
        3,
        3,
        4,
      ]);
      expect(mathTangramPieces.map(area).toList(), [4, 4, 1, 2, 1, 2, 2]);
      for (final p in mathTangramPieces.expand((v) => v)) {
        expect(p.dx, inInclusiveRange(0, 4));
        expect(p.dy, inInclusiveRange(0, 4));
      }
      for (var x = 0; x < 40; x++) {
        for (var y = 0; y < 40; y++) {
          // Distinct non-edge offsets avoid horizontal, vertical and45degree seams.
          final p = Offset((x + .37) / 10, (y + .23) / 10);
          expect(
            mathTangramPieces.where((shape) => inside(shape, p)).length,
            1,
            reason: 'coverage at$p',
          );
        }
      }
    },
  );
  test(
    'mirror maps are involutions with fixed axis points and equal offsets',
    () {
      for (final axis in MathMirrorAxis.values) {
        for (var x = 0; x <= 6; x++) {
          for (var y = 0; y <= 6; y++) {
            final a = Offset(x.toDouble(), y.toDouble()),
                b = mathMirrorPoint(Offset(x.toDouble(), y.toDouble()), axis);
            expect(mathMirrorPoint(b, axis), a);
            expect(b.dx, inInclusiveRange(0, 6));
            expect(b.dy, inInclusiveRange(0, 6));
            if (axis == MathMirrorAxis.vertical) {
              expect(b.dy, a.dy);
              expect((b.dx - 3).abs(), (a.dx - 3).abs());
              if (x == 3) {
                expect(b, a);
              }
            }
            if (axis == MathMirrorAxis.horizontal) {
              expect(b.dx, a.dx);
              expect((b.dy - 3).abs(), (a.dy - 3).abs());
              if (y == 3) {
                expect(b, a);
              }
            }
            if (axis == MathMirrorAxis.diagonal) {
              expect(b, Offset(a.dy, a.dx));
              if (x == y) {
                expect(b, a);
              }
            }
          }
        }
      }
    },
  );
  testWidgets(
    'mirror grid responds on all axes and resets state across modes',
    (tester) async {
      await model(tester, 'geometry_mirror_axis');
      expect(
        find.text('A: ustun 1, qator 2; aksi: ustun 5, qator 2'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(ChoiceChip, 'Yotiq'));
      expect(
        find.text('A: ustun 1, qator 2; aksi: ustun 1, qator 4'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(ChoiceChip, 'Diagonal'));
      expect(
        find.text('A: ustun 1, qator 2; aksi: ustun 2, qator 1'),
        findsOneWidget,
      );
      tester
          .widget<Slider>(find.byKey(const ValueKey('mirror-column')))
          .onChanged!(2);
      await tester.pumpAndSettle();
      expect(find.textContaining('Nuqta o‘q ustida'), findsOneWidget);
      await model(tester, 'geometry_regions');
      await model(tester, 'geometry_mirror_axis');
      expect(
        find.text('A: ustun 1, qator 2; aksi: ustun 5, qator 2'),
        findsOneWidget,
      );
    },
  );
}
