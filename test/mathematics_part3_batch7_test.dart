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
              'test/fixtures/mathematics/grade1_part3_batch7.json',
            ).readAsStringSync(),
          )
          as MathJson;
  final keys = <int, List<dynamic>>{
    36: ['8', '16', '27', '3', 'b', '23', '30', '46'],
    37: ['b', '10', '7', '7', 'b', '5', '6', '50'],
    38: ['8', '9', '11', '12', 'b', '13', '6', 'b'],
    39: ['a', '17', '39', '14', 'b', '43', '2', '9'],
    40: ['a', '11', '11', '31', 'b', '25', '72', 'a'],
    41: ['37', '22', '19', '8', 'a', '27', '12', '61'],
    42: [
      '8',
      '14',
      '17',
      '12',
      'b',
      '17',
      ['d', 'c', 'a', 'b'],
      '15',
    ],
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
          if (part == 3 && catalogOffline) {
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

  Future<void> part3(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('math-book-1-1')));
    await tester.tap(find.text('1-sinf · III qism').last);
    await tester.pumpAndSettle();
  }

  test(
    'all three books and explicit server QA metadata satisfy client contract',
    () {
      final repo = MathRepository(dio);
      for (final c in [
        'catalog1',
        'catalog2',
        'catalog3',
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
    testWidgets('book3 source$n full flow at320px and200percent text', (
      tester,
    ) async {
      await pump(tester);
      await part3(tester);
      final initial =
          data['lessons'][[36, 37, 38, 39, 40, 41, 42].indexOf(n)]['initial']
              as MathJson;
      await tap(tester, find.byKey(ValueKey(initial['lesson_key'])));
      if (n == 36) {
        await tap(tester, find.text('Manba'));
        expect(
          find.textContaining('III qism, 2024. PDF: 66–67. Bosma: 64–65.'),
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
        3,
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
  testWidgets(
    'source bridge remains explicit and normal strict mode stays locked',
    (tester) async {
      locked = true;
      await pump(tester);
      await part3(tester);
      await tester.scrollUntilVisible(
        find.textContaining('avval oldingi kitob'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('avval oldingi kitob'), findsWidgets);
      expect(requests.where((r) => r.path.endsWith('/start')), isEmpty);
      locked = false;
      await tap(tester, find.byKey(const ValueKey('math-book-1-3')));
      await tester.tap(find.text('1-sinf · I qism').last);
      await tester.pumpAndSettle();
      await part3(tester);
      await tester.scrollUntilVisible(
        find.textContaining('Lokal sinov:'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Lokal sinov:'), findsWidgets);
      expect(find.textContaining('37 / 37'), findsOneWidget);
    },
  );
  testWidgets('37body lessons do not claim source-less controls are ready', (
    tester,
  ) async {
    await pump(tester);
    await part3(tester);
    await tester.scrollUntilVisible(
      find.textContaining('Alohida matni berilmagan nazorat'),
      160,
      maxScrolls: 50,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('hali tayyor emas'), findsOneWidget);
    expect(data['completed_catalog']['course_ready'], false);
  });
  Future<void> model(WidgetTester tester, String mode) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MathExplorer(mode: mode)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('equal mass batches handle zero and all five groups', (
    tester,
  ) async {
    await model(tester, 'quantity_mass_batches');
    for (final row in {
      0: '0 ishlov: 0 kg',
      3: '3 ishlov: 12 kg',
      5: '5 ishlov: 20 kg',
    }.entries) {
      tester.widget<Slider>(find.byType(Slider)).onChanged!(row.key.toDouble());
      await tester.pumpAndSettle();
      expect(find.text(row.value), findsOneWidget);
    }
  });
  testWidgets(
    'litre addition and capacity subtraction keep distinct meanings',
    (tester) async {
      await model(tester, 'quantity_litre_addition');
      tester.widget<Slider>(find.byType(Slider)).onChanged!(4);
      await tester.pumpAndSettle();
      expect(find.text('6 + 4 = 10 litr'), findsOneWidget);
      tester.widget<Slider>(find.byType(Slider)).onChanged!(10);
      await tester.pumpAndSettle();
      expect(find.text('6 + 10 = 16 litr'), findsOneWidget);
      await model(tester, 'quantity_capacity_content');
      for (final row in {
        0: 'Qolgan: 12 litr; bo‘sh joy: 8 litr',
        3: 'Qolgan: 9 litr; bo‘sh joy: 11 litr',
        12: 'Qolgan: 0 litr; bo‘sh joy: 20 litr',
      }.entries) {
        tester.widget<Slider>(find.byType(Slider)).onChanged!(
          row.key.toDouble(),
        );
        await tester.pumpAndSettle();
        expect(find.text(row.value), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'maximal pours conserve8litres and isolate2without discarded water',
    (tester) async {
      await model(tester, 'quantity_conserving_pour');
      Future<void> pour(int a, int b) async {
        tester
            .widget<DropdownButton<int>>(
              find.byKey(const ValueKey('quantity-pour-0')),
            )
            .onChanged!(a);
        tester
            .widget<DropdownButton<int>>(
              find.byKey(const ValueKey('quantity-pour-1')),
            )
            .onChanged!(b);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Quyish'));
        await tester.pumpAndSettle();
        expect(find.text('Jami: 8 litr'), findsOneWidget);
      }

      await pour(0, 0);
      expect(find.text('Ikki idish turli bo‘lsin.'), findsOneWidget);
      await pour(0, 1);
      expect(find.text('A:3l; B:5l; C:0l'), findsOneWidget);
      await pour(1, 2);
      expect(find.text('A:3l; B:2l; C:3l'), findsOneWidget);
      expect(find.textContaining('Suv yo‘qolmadi'), findsOneWidget);
      await pour(0, 2);
      expect(find.text('0 litr ko‘chirildi.'), findsOneWidget);
      await tester.tap(find.text('Qaytadan'));
      await tester.pumpAndSettle();
      expect(find.text('A:8l; B:0l; C:0l'), findsOneWidget);
    },
  );
  testWidgets(
    'commutative quantities keep the selected unit as a new problem',
    (tester) async {
      await model(tester, 'quantity_commutative_units');
      expect(find.text('7 + 4 = 11 kg'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('4 + 7 = 11 kg'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Alohida idishlar (l)'));
      await tester.pumpAndSettle();
      expect(find.text('4 + 7 = 11 litr'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Kesmalar (cm)'));
      await tester.pumpAndSettle();
      expect(find.text('4 + 7 = 11 cm'), findsOneWidget);
    },
  );
  testWidgets(
    'unit table and equal partitions preserve their original constraints',
    (tester) async {
      await model(tester, 'quantity_unknown_components');
      final rows = {
        'Litr': '24 + 13 = 37 litr',
        'Detsimetr': '29 − 7 = 22 dm',
        'Kilogramm': '14 + 5 = 19 kg',
        'Santimetr': '38 − 30 = 8 cm',
      };
      for (final row in rows.entries) {
        await tester.tap(find.widgetWithText(ChoiceChip, row.key));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ustunni tekshirish'));
        await tester.pumpAndSettle();
        expect(find.text(row.value), findsOneWidget);
      }
      await tester.tap(find.text('Ikki teng shaklga ajrat'));
      await tester.pumpAndSettle();
      for (final label in ['Tik', 'Yotiq', 'Diagonal']) {
        await tester.ensureVisible(find.widgetWithText(ChoiceChip, label));
        await tester.tap(find.widgetWithText(ChoiceChip, label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'review separates a proposed part, container count and logical ordering',
    (tester) async {
      await model(tester, 'quantity_course_review');
      tester.widget<Slider>(find.byType(Slider)).onChanged!(8);
      await tester.pumpAndSettle();
      expect(find.text('11 + 6 + 8 = 25'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'To‘la va bo‘sh'));
      await tester.pumpAndSettle();
      expect(find.text('To‘la: 14 ta idish'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('Barchasi: 17 ta idish'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tartib'));
      await tester.pumpAndSettle();
      for (final id in ['D', 'C', 'A', 'B']) {
        await tester.tap(find.widgetWithText(ActionChip, id));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Barcha shartga mos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
