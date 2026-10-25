// Public payloads captured from the real, isolated Chemistry API. No live HTTP.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/chemistry_preview.dart';
import 'package:ilm_ai_flutter/core/network/api_contract.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/chemistry/data/chemistry_repository.dart';
import 'package:ilm_ai_flutter/features/chemistry/presentation/chemistry_preview_screen.dart';
import 'package:ilm_ai_flutter/features/chemistry/presentation/chemistry_display_text.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_feedback_panel.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_completion_view.dart';
import 'release_hardening_test.dart' show Adapter, reply;
import 'support/load_review_fonts.dart';

Json fixture(String name) =>
    jsonDecode(File('test/fixtures/chemistry_$name.json').readAsStringSync())
        as Json;
const _capture = Key('chemistry-review');
const _surfaceCapture = Key('chemistry-overlay-review');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadReviewFonts);
  late Dio dio;
  late Json lesson, results, catalog;
  Json? grade8Catalog;
  Json? grade9Catalog;
  late List<RequestOptions> requests;
  final committed = <String, Json>{};
  bool lostAnswer = false, offline = false, expired = false;
  setUp(() {
    lesson = fixture('lesson');
    results = fixture('results');
    catalog = fixture('catalog');
    grade8Catalog = null;
    grade9Catalog = null;
    requests = [];
    committed.clear();
    lostAnswer = false;
    offline = false;
    expired = false;
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8897'))
      ..httpClientAdapter = Adapter((r) {
        requests.add(r);
        if (offline) {
          throw DioException(
            requestOptions: r,
            type: DioExceptionType.connectionError,
          );
        }
        if (r.path.endsWith('/catalog')) {
          if (r.queryParameters['grade'] == 9 && grade9Catalog != null) {
            return reply(200, grade9Catalog!);
          }
          return reply(
            200,
            r.queryParameters['grade'] == 8 && grade8Catalog != null
                ? grade8Catalog!
                : catalog,
          );
        }
        if (r.path.endsWith('/start')) {
          return expired
              ? reply(409, {'detail': 'attempt_expired'})
              : reply(200, {...lesson, 'answers': Map.of(committed)});
        }
        if (r.path.endsWith('/answers')) {
          final key = (r.data as Map)['assessment_key'] as String;
          final value = Map<String, dynamic>.from(
            (results['answers'] as Map)[key] as Map,
          );
          committed[key] = value;
          if (lostAnswer) {
            lostAnswer = false;
            throw DioException(
              requestOptions: r,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return reply(200, value);
        }
        if (r.path.endsWith('/complete')) return reply(200, results['result']);
        throw StateError('Unexpected ${r.path}');
      });
  });
  tearDown(() => dio.close(force: true));

  Future<PrefsService> mount(
    WidgetTester t, {
    PrefsService? prefs,
    String language = 'uz',
    bool dark = false,
    double scale = 1,
    int uid = 900003,
    Size size = const Size(390, 844),
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    if (prefs == null) {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.language: language,
        PrefsKeys.themeMode: dark ? 'dark' : 'light',
      });
    }
    final store = prefs ?? await PrefsService.create();
    await t.pumpWidget(
      ProviderScope(
        key: ValueKey('$uid-$language-$dark-$scale'),
        overrides: [
          prefsServiceProvider.overrideWithValue(store),
          currentUserIdProvider.overrideWithValue(uid),
          chemistryRepositoryProvider.overrideWithValue(
            ChemistryRepository(dio),
          ),
        ],
        child: RepaintBoundary(
          key: _surfaceCapture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(dark ? darkColors : lightColors),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const RepaintBoundary(
              key: _capture,
              child: ChemistryPreviewScreen(),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return store;
  }

  Future<void> tapFinder(WidgetTester t, Finder f) async {
    await t.pumpAndSettle();
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String text) =>
      tapFinder(t, find.text(text).first);

  Future<void> begin(WidgetTester t) async {
    await tap(t, 'Darsni boshlash');
    for (var i = 0; i < 7; i++) {
      await tap(t, 'Davom etish');
    }
    await tap(t, 'Mashqlarga o‘tish');
  }

  void skip(int count) {
    final answers = results['answers'] as Map;
    for (final q in jsonRows(lesson['questions']).take(count)) {
      committed[q['key'] as String] = Map<String, dynamic>.from(
        answers[q['key']] as Map,
      );
    }
  }

  void useReviewedLesson(String name) {
    lesson = fixture('${name}_lesson');
    results = fixture('${name}_results');
    catalog['lessons'] = [
      {
        ...jsonRows(catalog['lessons']).first,
        'key': lesson['lesson_key'],
        'title': lesson['title'],
        'sequence': {
          'numeric': 6,
          'formula': 12,
          'equation': 15,
          'context': 18,
          'review': 19,
          'practical': 3,
          'water': 31,
          'concentration': 36,
          'acid_practical': 50,
          'laboratory': 59,
        }[name]!,
        'source_refs': (lesson['content'] as Json)['source_refs'],
      },
    ];
  }

  Future<void> capture(
    WidgetTester t,
    String name, {
    bool overlay = false,
  }) async {
    if (!const bool.fromEnvironment('CHEMISTRY_CAPTURE')) return;
    await t.pumpAndSettle();
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(overlay ? _surfaceCapture : _capture),
    );
    await t.runAsync(() async {
      final picture = await boundary.toImage(pixelRatio: 1);
      final bytes = (await picture.toByteData(format: ui.ImageByteFormat.png))!;
      final directory = Directory('build/chemistry-review')
        ..createSync(recursive: true);
      File(
        '${directory.path}/$name.png',
      ).writeAsBytesSync(bytes.buffer.asUint8List());
      picture.dispose();
    });
  }

  test('preview is disabled by default and permits only explicit loopback', () {
    expect(chemistryPreview, false);
    expect(chemistryPreviewAllowed('http://127.0.0.1:8897'), false);
    for (final u in ['http://127.0.0.1:8897', 'http://localhost:8897']) {
      expect(chemistryPreviewAllowed(u, enabled: true), true);
    }
    for (final u in [
      'https://ilm-ai.onrender.com',
      'http://192.168.1.2',
      'http://10.0.2.2',
      'https://user:secret@localhost',
      'http://localhost?token=x',
    ]) {
      expect(chemistryPreviewAllowed(u, enabled: true), false);
    }
    expect(
      ChemistryRepository.requestId(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
  test(
    'catalog rejects missing,duplicate,unsupported and mismatched grades',
    () {
      final repo = ChemistryRepository(dio);
      expect(repo.checked(catalog, 'catalog')['grade'], 7);
      for (final grades in [
        null,
        <int>[],
        [7, 7],
        [7, 12],
        [8],
      ]) {
        expect(
          () =>
              repo.checked({...catalog, 'available_grades': grades}, 'catalog'),
          throwsA(isA<InvalidApiResponseException>()),
        );
      }
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'grade8 selection uses real source and retains grade7 ${dark ? 'dark' : 'light'} at200%',
      (t) async {
        catalog['available_grades'] = [7, 8];
        final oldKey = jsonRows(catalog['lessons']).first['key'];
        grade8Catalog = fixture('grade8_catalog');
        lesson = fixture('grade8_lesson');
        results = fixture('grade8_results');
        await mount(t, dark: dark, size: const Size(320, 568), scale: 2);
        await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
        expect(requests.last.queryParameters['grade'], 8);
        expect(find.textContaining('Kimyo · 8-sinf'), findsWidgets);
        expect(find.text('5/59 dars mavjud.'), findsOneWidget);
        await capture(t, 'grade8-path-${dark ? 'dark' : 'light'}');
        await tap(t, 'Darsni boshlash');
        expect(requests.last.path, contains('chemistry-8-p01-r1/start'));
        expect(find.byKey(const ValueKey('chemistry-grade-7')), findsNothing);
        final source = find.textContaining('Manba: §1');
        await tapFinder(t, source);
        expect(
          find.textContaining('5 -> PDF 5 · Yakka sahifa'),
          findsOneWidget,
        );
        expect(find.textContaining('Kimyo 8 · 2019'), findsOneWidget);
        expect(find.textContaining('kimyo_8_uzb.pdf'), findsOneWidget);
        await t.ensureVisible(find.textContaining('5 -> PDF 5 · Yakka sahifa'));
        await t.pumpAndSettle();
        await capture(
          t,
          'grade8-source-${dark ? 'dark' : 'light'}',
          overlay: true,
        );
        expect(t.takeException(), isNull);
        expect(jsonRows(catalog['lessons']).first['key'], oldKey);
      },
    );
  }
  testWidgets('switching back keeps grade7 path and grade8 draft separately', (
    t,
  ) async {
    catalog['available_grades'] = [7, 8];
    grade8Catalog = fixture('grade8_catalog');
    lesson = fixture('grade8_lesson');
    results = fixture('grade8_results');
    await mount(t);
    await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
    skip(5);
    await tap(t, 'Darsni boshlash');
    final field = find.byKey(const Key('chemistry-short-answer'));
    await t.enterText(field, 'vodorod');
    await t.pumpAndSettle();
    await tapFinder(t, find.byIcon(Icons.arrow_back));
    await tap(t, 'Saqlab chiqish');
    expect(find.textContaining('Kimyo · 8-sinf'), findsWidgets);
    await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-7')));
    expect(requests.last.queryParameters['grade'], 7);
    expect(find.textContaining('Kimyo · 7-sinf'), findsWidgets);
    await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
    await tap(t, 'Darsni boshlash');
    expect(find.widgetWithText(TextField, 'vodorod'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'grade8 numeric FRQ retains common feedback and exact full page at200%',
    (t) async {
      catalog['available_grades'] = [7, 8];
      grade8Catalog = fixture('grade8_catalog');
      lesson = fixture('grade8_lesson');
      results = fixture('grade8_results');
      skip(11);
      await mount(t, dark: true, size: const Size(320, 568), scale: 2);
      await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
      await tap(t, 'Darsni boshlash');
      expect(find.textContaining('49 g H2SO4'), findsOneWidget);
      await t.enterText(find.byType(TextField), '0,5');
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': '0,5'});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      final source = find.descendant(
        of: find.byType(LessonFeedbackPanel),
        matching: find.textContaining('Manba: §1'),
      );
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, 'grade8-numeric-feedback');
      await tapFinder(t, source);
      expect(find.textContaining('9 -> PDF 9 · Yakka sahifa'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'chapter introduction keeps exact section and heading boundary ${dark ? 'dark' : 'light'} at200%',
      (t) async {
        catalog['available_grades'] = [7, 8];
        grade8Catalog = fixture('chapter_intro_catalog');
        lesson = fixture('chapter_intro_lesson');
        results = fixture('chapter_intro_results');
        await mount(t, dark: dark, size: const Size(320, 568), scale: 2);
        await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
        await tap(t, 'Darsni boshlash');
        final source = find.textContaining('Manba: Kimyoviy bog‘lanishlar');
        expect(source, findsOneWidget);
        expect(find.textContaining('Manba: §3'), findsNothing);
        await tapFinder(t, source);
        expect(
          find.textContaining('Manba bo‘limi: Kimyoviy bog‘lanishlar'),
          findsOneWidget,
        );
        final location = find.textContaining('63 -> PDF 63 · Yakka sahifa');
        expect(location, findsOneWidget);
        Navigator.of(t.element(location)).pop();
        await t.pumpAndSettle();
        await tap(t, 'Davom etish');
        await tapFinder(t, source);
        expect(
          find.textContaining('64 -> PDF 64 · Yakka sahifa'),
          findsOneWidget,
        );
        final boundary = find.textContaining(
          'paragraf sarlavhasidan oldingi bob kirishi',
        );
        expect(boundary, findsOneWidget);
        await t.ensureVisible(boundary);
        await t.pumpAndSettle();
        await capture(
          t,
          'chapter-intro-boundary-${dark ? 'dark' : 'light'}',
          overlay: true,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final name in ['oxidation', 'redox']) {
    testWidgets('$name reviewed FRQ uses unchanged shared feedback at200%', (
      t,
    ) async {
      catalog['available_grades'] = [7, 8];
      grade8Catalog = fixture('${name}_catalog');
      lesson = fixture('${name}_lesson');
      results = fixture('${name}_results');
      skip(name == 'oxidation' ? 7 : 10);
      await mount(
        t,
        dark: name == 'redox',
        size: const Size(320, 568),
        scale: 2,
      );
      await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
      await tap(t, 'Darsni boshlash');
      final value = name == 'oxidation'
          ? '−2'
          : '10FeSO4+2KMnO4+8H2SO4=5Fe2(SO4)3+K2SO4+2MnSO4+8H2O';
      await t.enterText(find.byType(TextField), value);
      await t.pumpAndSettle();
      await t.ensureVisible(find.byType(TextField));
      await t.pumpAndSettle();
      await capture(t, '$name-reviewed-input');
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': value});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      final section = name == 'oxidation' ? 18 : 20;
      final source = find.descendant(
        of: find.byType(LessonFeedbackPanel),
        matching: find.textContaining('Manba: §$section'),
      );
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, '$name-reviewed-feedback');
      await tapFinder(t, source);
      final page = name == 'oxidation' ? 78 : 86;
      expect(
        find.textContaining('$page -> PDF $page · Yakka sahifa'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  }
  for (final numeric in [false, true]) {
    testWidgets(
      'halogen practical ${numeric ? 'scientific number' : 'original balance'} keeps actual evidence at200%',
      (t) async {
        catalog['available_grades'] = [7, 8];
        grade8Catalog = fixture('halogen_practical_catalog');
        lesson = fixture('halogen_practical_lesson');
        results = fixture('halogen_practical_results');
        skip(numeric ? 13 : 6);
        await mount(t, dark: numeric, size: const Size(320, 568), scale: 2);
        await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
        // The full real catalog crosses Dio's background JSON isolate threshold.
        // Drain real asynchronous decoding before looking for its action.
        for (
          var i = 0;
          i < 100 && find.text('Darsni boshlash').evaluate().isEmpty;
          i++
        ) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await t.pumpAndSettle();
        }
        await tap(t, 'Darsni boshlash');
        for (
          var i = 0;
          i < 100 && find.byType(TextField).evaluate().isEmpty;
          i++
        ) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await t.pumpAndSettle();
        }
        final value = numeric ? '2.408e23' : 'Zn+Cl2=ZnCl2';
        await t.enterText(find.byType(TextField), value);
        await t.pumpAndSettle();
        await t.ensureVisible(find.byType(TextField));
        await t.pumpAndSettle();
        final mode = numeric ? 'number' : 'balance';
        await capture(t, 'halogen-practical-$mode-input');
        await tap(t, 'Tekshirish');
        final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
        expect((request.data as Map)['answer'], {'value': value});
        expect(find.byType(LessonFeedbackPanel), findsOneWidget);
        final source = find.descendant(
          of: find.byType(LessonFeedbackPanel),
          matching: find.textContaining(
            numeric ? 'Manba: Amaliy 1' : 'Manba: §23',
          ),
        );
        await t.ensureVisible(source);
        await t.pumpAndSettle();
        await capture(t, 'halogen-practical-$mode-feedback');
        await tapFinder(t, source);
        final page = numeric ? 129 : 97;
        expect(
          find.textContaining('$page -> PDF $page · Yakka sahifa'),
          findsOneWidget,
        );
        if (numeric) {
          expect(
            find.textContaining('Manba bo‘limi: Amaliy 1'),
            findsOneWidget,
          );
        }
        await capture(t, 'halogen-practical-$mode-source', overlay: true);
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final name in ['kinetics', 'equilibrium']) {
    testWidgets('$name reviewed theory symbols and source at200%', (t) async {
      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await t.pumpAndSettle();
        }
        expect(finder, findsWidgets);
      }

      catalog['available_grades'] = [7, 8];
      grade8Catalog = fixture('${name}_catalog');
      lesson = fixture('${name}_lesson');
      results = fixture('${name}_results');
      await mount(
        t,
        dark: name == 'equilibrium',
        size: const Size(320, 568),
        scale: 2,
      );
      await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
      await waitFor(find.text('Darsni boshlash'));
      await tap(t, 'Darsni boshlash');
      await waitFor(find.text('Davom etish'));
      for (var i = 0; i < (name == 'kinetics' ? 4 : 1); i++) {
        await tap(t, 'Davom etish');
      }
      final body = find.textContaining(
        name == 'kinetics' ? 'v2/v1' : 'SO2+H2O',
      );
      expect(body, findsOneWidget);
      await t.ensureVisible(body);
      await t.pumpAndSettle();
      await capture(t, '$name-reviewed-theory');
      final section = name == 'kinetics' ? 33 : 34;
      await tapFinder(t, find.textContaining('Manba: §$section'));
      final page = name == 'kinetics' ? 143 : 145;
      final locator = find.textContaining('$page -> PDF $page · Yakka sahifa');
      expect(locator, findsOneWidget);
      await t.ensureVisible(locator);
      await t.pumpAndSettle();
      await capture(t, '$name-reviewed-source', overlay: true);
      expect(t.takeException(), isNull);
    });
  }
  for (final dark in [false, true]) {
    for (final name in ['nitrogen', 'ammonia']) {
      testWidgets(
        '$name source and response ${dark ? 'dark' : 'light'} at200%',
        (t) async {
          Future<void> waitFor(Finder finder) async {
            for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
              await t.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 10)),
              );
              await t.pumpAndSettle();
            }
            expect(finder, findsWidgets);
          }

          catalog['available_grades'] = [7, 8];
          grade8Catalog = fixture('${name}_catalog');
          lesson = fixture('${name}_lesson');
          results = fixture('${name}_results');
          if (name == 'ammonia') skip(17);
          await mount(t, dark: dark, size: const Size(320, 568), scale: 2);
          await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
          await waitFor(find.text('Darsni boshlash'));
          await tap(t, 'Darsni boshlash');
          if (name == 'nitrogen') {
            await waitFor(find.text('Davom etish'));
            await tap(t, 'Davom etish');
            final body = find.textContaining('Bi83/209/6');
            expect(body, findsOneWidget);
            await t.ensureVisible(body);
            await t.pumpAndSettle();
            await capture(t, 'nitrogen-${dark ? 'dark' : 'light'}-table');
            await tapFinder(t, find.textContaining('Manba: Azot guruhchasi'));
            expect(
              find.textContaining('Manba bo‘limi: Azot guruhchasi'),
              findsOneWidget,
            );
            final boundary = find.textContaining(
              'paragraf sarlavhasidan oldingi bob kirishi',
            );
            expect(boundary, findsOneWidget);
            expect(
              find.textContaining('157 -> PDF 157 · Yakka sahifa'),
              findsOneWidget,
            );
            await t.ensureVisible(boundary);
            await t.pumpAndSettle();
          } else {
            final field = find.byKey(const Key('chemistry-short-answer'));
            await waitFor(field);
            await t.ensureVisible(field);
            await t.enterText(field, '−3');
            await tap(t, 'Tekshirish');
            final request = requests.lastWhere(
              (r) => r.path.endsWith('/answers'),
            );
            expect((request.data as Map)['answer'], {'value': '−3'});
            expect(find.byType(LessonFeedbackPanel), findsOneWidget);
            final source = find.descendant(
              of: find.byType(LessonFeedbackPanel),
              matching: find.textContaining('Manba: §37'),
            );
            await t.ensureVisible(source);
            await t.pumpAndSettle();
            await capture(t, 'ammonia-${dark ? 'dark' : 'light'}-feedback');
            await tapFinder(t, source);
            final locator = find.textContaining(
              '161 -> PDF 161 · Yakka sahifa',
            );
            expect(locator, findsOneWidget);
            await t.ensureVisible(locator);
            await t.pumpAndSettle();
          }
          await capture(
            t,
            '$name-${dark ? 'dark' : 'light'}-source',
            overlay: true,
          );
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  for (final name in ['nitrate_practical', 'phosphate']) {
    testWidgets('$name reviewed model and source at200%', (t) async {
      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await t.pumpAndSettle();
        }
        expect(finder, findsWidgets);
      }

      catalog['available_grades'] = [7, 8];
      grade8Catalog = fixture('${name}_catalog');
      lesson = fixture('${name}_lesson');
      results = fixture('${name}_results');
      if (name == 'nitrate_practical') skip(13);
      await mount(
        t,
        dark: name == 'phosphate',
        size: const Size(320, 568),
        scale: 2,
      );
      await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
      await waitFor(find.text('Darsni boshlash'));
      await tap(t, 'Darsni boshlash');
      if (name == 'nitrate_practical') {
        final field = find.byKey(const Key('chemistry-short-answer'));
        await waitFor(field);
        await t.ensureVisible(field);
        await t.enterText(field, '0,833');
        await tap(t, 'Tekshirish');
        final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
        expect((request.data as Map)['answer'], {'value': '0,833'});
        expect(find.byType(LessonFeedbackPanel), findsOneWidget);
        await capture(t, 'nitrate-practical-feedback-top');
        final source = find.descendant(
          of: find.byType(LessonFeedbackPanel),
          matching: find.textContaining('Manba: Amaliy 3'),
        );
        await t.ensureVisible(source);
        await t.pumpAndSettle();
        await capture(t, 'nitrate-practical-feedback-source');
        await tapFinder(t, source);
        final locator = find.textContaining('173 -> PDF 173 · Yakka sahifa');
        expect(locator, findsOneWidget);
        await t.ensureVisible(locator);
      } else {
        await waitFor(find.text('Davom etish'));
        for (var i = 0; i < 5; i++) {
          await tap(t, 'Davom etish');
        }
        final body = find.textContaining('kislota qoldig‘idagi H soni');
        expect(body, findsOneWidget);
        await t.ensureVisible(body);
        await t.pumpAndSettle();
        await capture(t, 'phosphate-dissociation-theory');
        await tapFinder(t, find.textContaining('Manba: §41'));
        final locator = find.textContaining('178 -> PDF 178 · Yakka sahifa');
        expect(locator, findsOneWidget);
        await t.ensureVisible(locator);
      }
      await t.pumpAndSettle();
      await capture(t, '$name-reviewed-model-source', overlay: true);
      expect(t.takeException(), isNull);
    });
  }
  for (final name in ['fertilizer', 'zinc_lab']) {
    testWidgets('$name sourced arithmetic or lab model at200%', (t) async {
      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await t.pumpAndSettle();
        }
        expect(finder, findsWidgets);
      }

      catalog['available_grades'] = [7, 8];
      grade8Catalog = fixture('${name}_catalog');
      lesson = fixture('${name}_lesson');
      results = fixture('${name}_results');
      skip(name == 'fertilizer' ? 12 : 8);
      await mount(
        t,
        dark: name == 'zinc_lab',
        size: const Size(320, 568),
        scale: 2,
      );
      await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
      await waitFor(find.text('Darsni boshlash'));
      await tap(t, 'Darsni boshlash');
      final field = find.byKey(const Key('chemistry-short-answer'));
      await waitFor(field);
      await t.ensureVisible(field);
      final value = name == 'fertilizer'
          ? '4,120'
          : 'Zn(OH)2+2NaOH=Na2ZnO2+2H2O';
      await t.enterText(field, value);
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': value});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      await capture(t, '$name-model-feedback');
      final source = find.descendant(
        of: find.byType(LessonFeedbackPanel),
        matching: find.textContaining(
          name == 'fertilizer' ? 'Manba: §43' : 'Manba: Laboratoriya 1',
        ),
      );
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await tapFinder(t, source);
      final page = name == 'fertilizer' ? 191 : 200;
      final locator = find.textContaining('$page -> PDF $page · Yakka sahifa');
      expect(locator, findsOneWidget);
      if (name == 'zinc_lab') {
        expect(
          find.textContaining('Manba bo‘limi: Laboratoriya 1'),
          findsOneWidget,
        );
      }
      await t.ensureVisible(locator);
      await t.pumpAndSettle();
      await capture(t, '$name-model-source', overlay: true);
      expect(t.takeException(), isNull);
    });
  }
  for (final name in ['sulfate_lab', 'fertilizer_lab']) {
    testWidgets('$name final grade8 lab at200%', (t) async {
      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await t.pumpAndSettle();
        }
        expect(finder, findsWidgets);
      }

      final sulfate = name == 'sulfate_lab';
      catalog['available_grades'] = [7, 8];
      grade8Catalog = fixture('${name}_catalog');
      lesson = fixture('${name}_lesson');
      results = fixture('${name}_results');
      skip(sulfate ? 9 : 12);
      await mount(
        t,
        dark: sulfate,
        size: const Size(320, 568),
        scale: 2,
      );
      await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-8')));
      await waitFor(find.text('Darsni boshlash'));
      await tap(t, 'Darsni boshlash');
      final field = find.byKey(const Key('chemistry-short-answer'));
      await waitFor(field);
      await t.ensureVisible(field);
      final value = sulfate
          ? 'Al2(SO4)3+3BaCl2=3BaSO4+2AlCl3'
          : '74,5';
      await t.enterText(field, value);
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': value});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      await capture(t, '$name-model-feedback');
      final lab = sulfate ? 8 : 10;
      final source = find.descendant(
        of: find.byType(LessonFeedbackPanel),
        matching: find.textContaining('Manba: Laboratoriya $lab'),
      );
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await tapFinder(t, source);
      final page = sulfate ? 203 : 204;
      final locator = find.textContaining('$page -> PDF $page · Yakka sahifa');
      expect(locator, findsOneWidget);
      expect(
        find.textContaining('Manba bo‘limi: Laboratoriya $lab'),
        findsOneWidget,
      );
      await t.ensureVisible(locator);
      await t.pumpAndSettle();
      await capture(t, '$name-model-source', overlay: true);
      expect(t.takeException(), isNull);
    });
  }
  for (final name in ['grade9_periodic', 'grade9_degree']) {
    testWidgets('$name sourced grade9 FRQ at200%', (t) async {
      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await t.pumpAndSettle();
        }
        expect(finder, findsWidgets);
      }

      final periodic = name == 'grade9_periodic';
      catalog['available_grades'] = [7, 8, 9];
      grade9Catalog = fixture('${name}_catalog');
      lesson = fixture('${name}_lesson');
      results = fixture('${name}_results');
      skip(periodic ? 16 : 18);
      await mount(
        t,
        dark: periodic,
        size: const Size(320, 568),
        scale: 2,
      );
      await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-9')));
      await waitFor(find.text('Darsni boshlash'));
      expect(
        requests.any(
          (r) => r.path.endsWith('/catalog') && r.queryParameters['grade'] == 9,
        ),
        isTrue,
      );
      await tap(t, 'Darsni boshlash');
      final field = find.byKey(const Key('chemistry-short-answer'));
      await waitFor(field);
      await t.ensureVisible(field);
      final value = periodic ? '1,66' : '1e-5';
      await t.enterText(field, value);
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': value});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      await capture(t, '$name-model-feedback');
      final paragraph = periodic ? 1 : 5;
      final source = find.descendant(
        of: find.byType(LessonFeedbackPanel),
        matching: find.textContaining('Manba: §$paragraph'),
      );
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await tapFinder(t, source);
      final page = periodic ? 11 : 28;
      final locator = find.textContaining('$page -> PDF $page · Yakka sahifa');
      expect(locator, findsOneWidget);
      expect(find.textContaining('kimyo_9_uzb.pdf'), findsOneWidget);
      await t.ensureVisible(locator);
      await t.pumpAndSettle();
      await capture(t, '$name-model-source', overlay: true);
      expect(t.takeException(), isNull);
    });
  }
  for (final name in ['carbon_family', 'carbon_oxide']) {
    testWidgets('$name earlier textbook source at200%', (t) async {
      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await t.pumpAndSettle();
        }
        expect(finder, findsWidgets);
      }

      final family = name == 'carbon_family';
      catalog['available_grades'] = [7, 8, 9];
      grade9Catalog = fixture('${name}_catalog');
      lesson = fixture('${name}_lesson');
      results = fixture('${name}_results');
      skip(family ? 11 : 24);
      await mount(
        t,
        dark: family,
        size: const Size(320, 568),
        scale: 2,
      );
      await tapFinder(t, find.byKey(const ValueKey('chemistry-grade-9')));
      await waitFor(find.text('Darsni boshlash'));
      await tap(t, 'Darsni boshlash');
      final field = find.byKey(const Key('chemistry-short-answer'));
      await waitFor(field);
      await t.ensureVisible(field);
      final value = family ? 'SiH4' : '71,5';
      await t.enterText(field, value);
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': value});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      await capture(t, '$name-model-feedback');
      final paragraph = family ? 8 : 10;
      final ownSource = find.descendant(
        of: find.byType(LessonFeedbackPanel),
        matching: find.textContaining('Manba: §$paragraph'),
      );
      await t.ensureVisible(ownSource);
      await t.pumpAndSettle();
      await tapFinder(t, ownSource);
      final ownPage = family ? 47 : 51;
      final ownLocator = find.textContaining('$ownPage -> PDF $ownPage');
      expect(ownLocator, findsOneWidget);
      expect(find.textContaining('kimyo_9_uzb.pdf'), findsOneWidget);
      await t.ensureVisible(ownLocator);
      await t.pumpAndSettle();
      await capture(t, '$name-current-source', overlay: true);
      Navigator.of(t.element(ownLocator)).pop();
      await t.pumpAndSettle();
      final earlierSource = find.descendant(
        of: find.byType(LessonFeedbackPanel),
        matching: find.textContaining('Manba: §25'),
      );
      await t.ensureVisible(earlierSource);
      await t.pumpAndSettle();
      await tapFinder(t, earlierSource);
      final earlierPage = family ? 110 : 105;
      final earlierLocator = find.textContaining(
        '$earlierPage -> PDF $earlierPage · Yakka sahifa',
      );
      expect(earlierLocator, findsOneWidget);
      expect(find.textContaining('kimyo_8_uzb.pdf'), findsOneWidget);
      expect(find.textContaining('kimyo_9_uzb.pdf'), findsNothing);
      await t.ensureVisible(earlierLocator);
      await t.pumpAndSettle();
      await capture(t, '$name-earlier-source', overlay: true);
      expect(t.takeException(), isNull);
    });
  }
  test('portable formula display preserves source and grading data', () {
    final before = jsonEncode(fixture('grade8_lesson'));
    expect(chemistryDisplayText('H₂SO₄ + NH₄⁺'), 'H2SO4 + NH4^(+)');
    expect(chemistryDisplayText('1,66·10⁻²⁴ g'), '1,66·10^(-24) g');
    expect(chemistryDisplayText('Fe2(SO4)3=Fe2(SO4)3'), 'Fe2(SO4)3=Fe2(SO4)3');
    expect(chemistryDisplayText('SO₂+H₂O⇌H₂SO₃'), 'SO2+H2O <=> H2SO3');
    final equilibrium = fixture('equilibrium_lesson');
    final equilibriumBefore = jsonEncode(equilibrium);
    for (final card in jsonRows((equilibrium['content'] as Json)['cards'])) {
      chemistryDisplayText(card['body'] as String);
    }
    expect(jsonEncode(equilibrium), equilibriumBefore);
    expect(jsonEncode(fixture('grade8_lesson')), before);
  });
  test('public first paragraph has no private rubric or AI output', () {
    final raw = jsonEncode(lesson);
    for (final key in [
      'grading_spec',
      'expected',
      'aliases',
      'correct_answer',
      'verified_answer',
    ]) {
      expect(raw, isNot(contains('"$key"')));
    }
    expect(jsonRows(lesson['questions']).length, 12);
    expect(
      jsonRows(
        lesson['questions'],
      ).where((q) => q['response_kind'] == 'short_text').length,
      3,
    );
    expect(jsonRows((lesson['content'] as Json)['cards']).length, 8);
  });
  test('numeric API input has explicit units and no private grading data', () {
    final data = fixture('numeric_lesson');
    final repo = ChemistryRepository(dio);
    expect(repo.checked(data, 'attempt')['lesson_key'], 'chemistry-7-p04-r1');
    final q = jsonRows(
      data['questions'],
    ).firstWhere((q) => q['response_kind'] == 'numeric_value');
    expect(q['unit'], isA<String>());
    expect(jsonEncode(data), isNot(contains('"expected"')));
    q.remove('unit');
    data['questions'] = [q];
    expect(
      () => repo.checked(data, 'attempt'),
      throwsA(isA<InvalidApiResponseException>()),
    );
  });
  testWidgets(
    'numeric FRQ can submit a comma decimal using the common exercise flow',
    (t) async {
      useReviewedLesson('numeric');
      // Resume at the source-reviewed mass reference denominator question.
      for (final q in jsonRows(lesson['questions']).take(6)) {
        committed[q['key'] as String] = Map<String, dynamic>.from(
          (results['answers'] as Map)[q['key']] as Map,
        );
      }
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      expect(find.textContaining('FRQ'), findsOneWidget);
      await t.enterText(find.byType(TextField), '12,0');
      await t.pumpAndSettle();
      await tap(t, 'Tekshirish');
      final submitted = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((submitted.data as Map)['answer'], {'value': '12,0'});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  test(
    'repository fails closed on version, private keys and source mapping',
    () {
      final repo = ChemistryRepository(dio);
      expect(
        () => repo.checked({...lesson, 'assessment_version': 1}, 'attempt'),
        throwsA(isA<ApiCompatibilityException>()),
      );
      final bad = fixture('lesson');
      (bad['content'] as Map)['expected'] = 'secret';
      expect(
        () => repo.checked(bad, 'attempt'),
        throwsA(isA<InvalidApiResponseException>()),
      );
      final source = fixture('lesson');
      ((jsonRows((source['content'] as Json)['cards']).first['source_refs']
                      as List)
                  .first
              as Map)['regions'] =
          [];
      expect(
        () => repo.checked(source, 'attempt'),
        throwsA(isA<InvalidApiResponseException>()),
      );
    },
  );
  test(
    'real formula and equation payloads remain public and source linked',
    () {
      for (final name in ['formula', 'equation']) {
        final data = fixture('${name}_lesson');
        expect(ChemistryRepository(dio).checked(data, 'attempt'), isA<Map>());
        expect(
          jsonRows(
            data['questions'],
          ).any((q) => q['response_kind'] == 'chemical_$name'),
          isTrue,
        );
        expect(jsonEncode(data), isNot(contains('"grading_spec"')));
        expect(jsonEncode(data), isNot(contains('"expected"')));
      }
    },
  );
  for (final name in ['formula', 'equation']) {
    testWidgets('$name FRQ submits exact typed notation at200% text', (
      t,
    ) async {
      useReviewedLesson(name);
      skip(name == 'formula' ? 7 : 6);
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      final value = name == 'formula' ? 'P₂O₅' : 'O₂ + 2Mg → 2MgO';
      await t.enterText(find.byType(TextField), value);
      await t.pumpAndSettle();
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': value});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('a response for a different lesson cannot enter the exercise', (
    t,
  ) async {
    lesson = fixture('numeric_lesson');
    // The catalog/request still identifies paragraph01. Do not store or show a
    // mismatched lesson from an incompatible response under that draft key.
    await mount(t);
    await tap(t, 'Darsni boshlash');
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Nazariya 1/6'), findsNothing);
    expect(find.text('Nazariya 1/8'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('prior paragraph data retains its own source button and page', (
    t,
  ) async {
    useReviewedLesson('context');
    await mount(t, size: const Size(320, 568), scale: 2);
    await tap(t, 'Darsni boshlash');
    for (var i = 0; i < 4; i++) {
      await tap(t, 'Davom etish');
    }
    expect(find.textContaining('Manba: §10'), findsOneWidget);
    expect(find.textContaining('Manba: §15'), findsOneWidget);
    await t.ensureVisible(find.textContaining('Manba: §15'));
    await t.pumpAndSettle();
    await capture(t, 'context-source-groups');
    await tapFinder(t, find.textContaining('Manba: §10'));
    expect(find.textContaining('Kitobdagi bet: 34'), findsOneWidget);
    expect(find.textContaining('34 -> PDF 18 · chap sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'chapter review source is named without a false paragraph or activity',
    (t) async {
      useReviewedLesson('review');
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      for (var i = 0; i < 4; i++) {
        await tap(t, 'Davom etish');
      }
      final source = find.textContaining('Manba: I bobga doir');
      expect(source, findsOneWidget);
      expect(find.textContaining('Amaliy null'), findsNothing);
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, 'review-source-kind');
      await tapFinder(t, source);
      expect(find.textContaining('47 -> PDF 24 · o‘ng sahifa'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'practical source label is an activity rather than paragraph one',
    (t) async {
      useReviewedLesson('practical');
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      final source = find.textContaining('Manba: Amaliy 1');
      expect(source, findsOneWidget);
      expect(find.textContaining('Manba: §1'), findsNothing);
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, 'practical-source-kind');
      await tapFinder(t, source);
      expect(find.textContaining('Manba bo‘limi: Amaliy 1'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'practical6 reuses the earlier review with its actual page at200%',
    (t) async {
      useReviewedLesson('acid_practical');
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      expect(find.textContaining('Manba: Amaliy 6'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await tap(t, 'Davom etish');
      }
      final source = find.textContaining('Manba: I bobga doir');
      expect(source, findsOneWidget);
      expect(find.textContaining('Manba: §6'), findsNothing);
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, 'acid-practical-earlier-review');
      await tapFinder(t, source);
      expect(find.textContaining('50 -> PDF 26 · chap sahifa'), findsOneWidget);
      expect(find.textContaining('Amaliy null'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'practical6 numeric report keeps comma input and prior-source feedback',
    (t) async {
      useReviewedLesson('acid_practical');
      skip(6);
      await mount(t, size: const Size(320, 568), scale: 2, dark: true);
      await tap(t, 'Darsni boshlash');
      await t.enterText(find.byType(TextField), '4,9');
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': '4,9'});
      expect(find.byType(LessonFeedbackPanel), findsOneWidget);
      final source = find.descendant(
        of: find.byType(LessonFeedbackPanel),
        matching: find.textContaining('Manba: I bobga doir'),
      );
      expect(source, findsOneWidget);
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, 'acid-practical-earlier-feedback');
      await tapFinder(t, source);
      expect(find.textContaining('50 -> PDF 26 · chap sahifa'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'laboratory source has its activity label and exact spread page',
    (t) async {
      useReviewedLesson('laboratory');
      await mount(t, size: const Size(320, 568), scale: 2);
      await tap(t, 'Darsni boshlash');
      final source = find.textContaining('Manba: Laboratoriya 1');
      expect(source, findsOneWidget);
      expect(find.textContaining('Manba: §1'), findsNothing);
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, 'laboratory-source-kind');
      await tapFinder(t, source);
      expect(
        find.textContaining('Manba bo‘limi: Laboratoriya 1'),
        findsOneWidget,
      );
      expect(
        find.textContaining('147 -> PDF 74 · o‘ng sahifa'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'laboratory short FRQ keeps typed value and source feedback at200%',
    (t) async {
      useReviewedLesson('laboratory');
      skip(3);
      await mount(t, size: const Size(320, 568), scale: 2, dark: true);
      await tap(t, 'Darsni boshlash');
      await t.enterText(find.byType(TextField), 'eruvchanlik');
      await tap(t, 'Tekshirish');
      final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
      expect((request.data as Map)['answer'], {'value': 'eruvchanlik'});
      final source = find.descendant(
        of: find.byType(LessonFeedbackPanel),
        matching: find.textContaining('Manba: Laboratoriya 1'),
      );
      expect(source, findsOneWidget);
      await t.ensureVisible(source);
      await t.pumpAndSettle();
      await capture(t, 'laboratory-short-feedback');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('water theory and original page remain readable at200% text', (
    t,
  ) async {
    useReviewedLesson('water');
    await mount(t, size: const Size(320, 568), scale: 2);
    await tap(t, 'Darsni boshlash');
    expect(find.text('Nazariya 1/10'), findsOneWidget);
    final source = find.textContaining('Manba: §27').first;
    await t.ensureVisible(source);
    await t.pumpAndSettle();
    await capture(t, 'water-theory-source');
    await tapFinder(t, source);
    expect(find.textContaining('80 -> PDF 41 · chap sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('hydrate is a recognition MCQ with common source feedback', (
    t,
  ) async {
    useReviewedLesson('water');
    skip(3);
    await mount(t, size: const Size(320, 568), scale: 2, dark: true);
    await tap(t, 'Darsni boshlash');
    expect(find.byType(TextField), findsNothing);
    await tap(t, 'CuSO4·5H2O');
    await tap(t, 'Tekshirish');
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
    final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
    expect((request.data as Map)['answer'], {'choice_id': 'b'});
    expect(committed.values.last['is_correct'], true);
    final source = find.descendant(
      of: find.byType(LessonFeedbackPanel),
      matching: find.textContaining('Manba: §27'),
    );
    expect(source, findsOneWidget);
    await t.ensureVisible(source);
    await t.pumpAndSettle();
    await capture(t, 'water-hydrate-feedback');
    await tapFinder(t, source);
    expect(find.textContaining('82 -> PDF 42 · chap sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('molar theory retains the prior molar-mass source at200%', (
    t,
  ) async {
    useReviewedLesson('concentration');
    await mount(t, size: const Size(320, 568), scale: 2);
    await tap(t, 'Darsni boshlash');
    for (var i = 0; i < 5; i++) {
      await tap(t, 'Davom etish');
    }
    expect(find.textContaining('Manba: §10'), findsOneWidget);
    expect(find.textContaining('Manba: §32'), findsOneWidget);
    await tapFinder(t, find.textContaining('Manba: §10'));
    expect(find.textContaining('34 -> PDF 18 · chap sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('molar FRQ keeps its fixed unit and exact comma input at200%', (
    t,
  ) async {
    useReviewedLesson('concentration');
    skip(10);
    await mount(t, size: const Size(320, 568), scale: 2, dark: true);
    await tap(t, 'Darsni boshlash');
    expect(find.textContaining('mol/l'), findsWidgets);
    await t.enterText(find.byType(TextField), '0,4');
    await t.pumpAndSettle();
    await t.ensureVisible(find.textContaining('Birlik: mol/l'));
    await t.pumpAndSettle();
    await capture(t, 'molar-fixed-unit-input');
    await tap(t, 'Tekshirish');
    final request = requests.lastWhere((r) => r.path.endsWith('/answers'));
    expect((request.data as Map)['answer'], {'value': '0,4'});
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
    final source = find.descendant(
      of: find.byType(LessonFeedbackPanel),
      matching: find.textContaining('Manba: §32'),
    );
    await t.ensureVisible(source);
    await t.pumpAndSettle();
    await capture(t, 'molar-source-feedback');
    await tapFinder(t, source);
    expect(find.textContaining('91 -> PDF 46 · o‘ng sahifa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('theory advances one card and sources resolve spread sides', (
    t,
  ) async {
    await mount(t);
    await tap(t, 'Darsni boshlash');
    expect(find.text('Nazariya 1/8'), findsOneWidget);
    expect(
      find.text(
        jsonRows((lesson['content'] as Json)['cards'])[1]['title'] as String,
      ),
      findsNothing,
    );
    await tap(t, 'Davom etish');
    expect(find.text('Nazariya 2/8'), findsOneWidget);
    final source = find.textContaining('Manba:').first;
    await t.ensureVisible(source);
    await t.tap(source);
    await t.pumpAndSettle();
    expect(find.text('kimyo_7_uzb.pdf'), findsOneWidget);
    expect(find.textContaining('-> PDF 3 · chap sahifa'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'completed lesson action accurately describes reopening on a new device',
    (t) async {
      (catalog['lessons'] as List).first['state'] = 'completed';
      await mount(t);
      expect(find.text('Darsni takrorlash'), findsOneWidget);
      await tap(t, 'Darsni takrorlash');
      expect(find.text('Nazariya 1/8'), findsOneWidget);
      expect(find.byType(LessonCompletionView), findsNothing);
    },
  );
  testWidgets('server MCQ feedback uses common panel and completion view', (
    t,
  ) async {
    await mount(t);
    await begin(t);
    await tap(
      t,
      jsonRows(jsonRows(lesson['questions']).first['options']).first['label']
          as String,
    );
    await tap(t, 'Tekshirish');
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
    expect(committed.values.first['is_correct'], false);
    final payload = requests.last.data as Map;
    expect(payload.keys.toSet(), {
      'assessment_version',
      'assessment_key',
      'answer',
    });
    expect((payload['answer'] as Map).keys.toSet(), {'choice_id'});
    await tap(t, 'Davom etish');
    expect(find.text('2/12 · MCQ'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('FRQ input is sent to server without client correctness or XP', (
    t,
  ) async {
    skip(9);
    await mount(t);
    await tap(t, 'Darsni boshlash');
    expect(find.text('10/12 · FRQ'), findsOneWidget);
    final field = find.byKey(const Key('chemistry-short-answer'));
    await t.ensureVisible(field);
    await t.enterText(field, '  KIMYO FANI. ');
    await tap(t, 'Tekshirish');
    final answer = requests.last.data as Map;
    expect(answer['answer'], {'value': '  KIMYO FANI. '});
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('lost answer freezes payload and retry is byte-equivalent', (
    t,
  ) async {
    skip(9);
    await mount(t);
    await tap(t, 'Darsni boshlash');
    final field = find.byKey(const Key('chemistry-short-answer'));
    await t.ensureVisible(field);
    await t.enterText(field, 'kimyo');
    lostAnswer = true;
    await tap(t, 'Tekshirish');
    expect(t.widget<TextField>(field).readOnly, true);
    final before = jsonEncode(requests.last.data);
    await tap(t, 'Qayta yuborish');
    expect(jsonEncode(requests.last.data), before);
    expect(find.byType(LessonFeedbackPanel), findsOneWidget);
  });
  testWidgets('saved text and request ID resume on same account only', (
    t,
  ) async {
    skip(9);
    final store = await mount(t);
    await tap(t, 'Darsni boshlash');
    final first = (requests.last.data as Map)['request_id'];
    final field = find.byKey(const Key('chemistry-short-answer'));
    await t.ensureVisible(field);
    await t.enterText(field, 'alkaloid');
    await t.pumpAndSettle();
    await t.pumpWidget(const SizedBox());
    await mount(t, prefs: store);
    await tap(t, 'Darsni boshlash');
    expect((requests.last.data as Map)['request_id'], first);
    expect(t.widget<TextField>(field).controller!.text, 'alkaloid');
    await t.pumpWidget(const SizedBox());
    await mount(t, prefs: store, uid: 900004);
    await tap(t, 'Darsni boshlash');
    expect((requests.last.data as Map)['request_id'], isNot(first));
    expect(t.widget<TextField>(field).controller!.text, isEmpty);
  });
  testWidgets('exit uses shared save dialog and returns to path', (t) async {
    await mount(t);
    await tap(t, 'Darsni boshlash');
    await t.tap(find.byIcon(Icons.arrow_back));
    await t.pumpAndSettle();
    expect(find.text('Darsdan chiqasizmi?'), findsOneWidget);
    await tap(t, 'Saqlab chiqish');
    expect(find.text('Darsni boshlash'), findsOneWidget);
    await tap(t, 'Darsni boshlash');
    expect(find.text('Nazariya 1/8'), findsOneWidget);
  });
  testWidgets('expiry does not silently discard a saved attempt', (t) async {
    expired = true;
    await mount(t);
    await tap(t, 'Darsni boshlash');
    expect(find.textContaining('24 soatlik'), findsOneWidget);
    expect(find.text('Yangi urinish'), findsOneWidget);
    final old = (requests.last.data as Map)['request_id'];
    expired = false;
    await tap(t, 'Yangi urinish');
    expect((requests.last.data as Map)['request_id'], isNot(old));
  });
  testWidgets(
    'completed attempt uses common result and sourced answer review',
    (t) async {
      skip(12);
      lesson['result'] = results['result'];
      await mount(t);
      await tap(t, 'Darsni boshlash');
      expect(find.byType(LessonCompletionView), findsOneWidget);
      final result = t.widget<LessonCompletionView>(
        find.byType(LessonCompletionView),
      );
      expect(result.xp, 20);
      expect(result.correct, 11);
      result.onReview();
      await t.pumpAndSettle();
      expect(find.text('Javoblar'), findsOneWidget);
      expect(find.textContaining('Manba:'), findsWidgets);
      expect(t.takeException(), isNull);
    },
  );

  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'small and landscape 200% text $lang ${dark ? 'dark' : 'light'}',
        (t) async {
          skip(9);
          await mount(
            t,
            language: lang,
            dark: dark,
            scale: 2,
            size: const Size(320, 568),
          );
          await tap(
            t,
            lang == 'uz'
                ? 'Darsni boshlash'
                : lang == 'ru'
                ? 'Начать урок'
                : 'Start lesson',
          );
          final field = find.byKey(const Key('chemistry-short-answer'));
          await t.ensureVisible(field);
          await t.enterText(field, 'kimyo');
          await tap(
            t,
            lang == 'uz'
                ? 'Tekshirish'
                : lang == 'ru'
                ? 'Проверить'
                : 'Check',
          );
          expect(find.byType(LessonFeedbackPanel), findsOneWidget);
          expect(t.takeException(), isNull);
          t.view.physicalSize = const Size(640, 360);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  for (final dark in [false, true]) {
    testWidgets(
      'review captures ${dark ? 'dark' : 'light'} theory MCQ FRQ feedback and result',
      (t) async {
        final mode = dark ? 'dark' : 'light';
        final store = await mount(t, dark: dark);
        await tap(t, 'Darsni boshlash');
        await capture(t, 'theory-$mode');
        for (var i = 0; i < 7; i++) {
          await tap(t, 'Davom etish');
        }
        await tap(t, 'Mashqlarga o‘tish');
        await capture(t, 'mcq-$mode');
        await tap(
          t,
          jsonRows(
                jsonRows(lesson['questions']).first['options'],
              ).first['label']
              as String,
        );
        await tap(t, 'Tekshirish');
        await capture(t, 'feedback-$mode');
        skip(9);
        await t.pumpWidget(const SizedBox());
        await mount(t, dark: dark, prefs: store);
        await tap(t, 'Darsni boshlash');
        await capture(t, 'frq-$mode');
        skip(12);
        lesson['result'] = results['result'];
        await t.pumpWidget(const SizedBox());
        await mount(t, dark: dark, prefs: store);
        await tap(t, 'Darsni boshlash');
        await capture(t, 'result-$mode');
        expect(t.takeException(), isNull);
      },
    );
  }
}
