import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/network/mobile_api.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/learning/presentation/assessment_lesson_screen.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/duo_onboarding_screen.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_home_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_feedback_panel.dart';
import 'package:ilm_ai_flutter/features/chemistry/presentation/chemistry_display_text.dart';
import 'package:ilm_ai_flutter/features/world_history/presentation/world_history_display_text.dart';
import 'release_hardening_test.dart' show Adapter, reply;

typedef Json = Map<String, dynamic>;
Json fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Json;

class _LoggedOut extends AuthController {
  @override
  Future<StoredTokens?> build() async => null;
}

const presets = [
  (
    slug: 'fizika',
    grade: 6,
    lesson: 'physics_lesson6',
    result: 'physics_result6',
    catalog: 'physics_catalog',
  ),
  (
    slug: 'kimyo',
    grade: 7,
    lesson: 'chemistry_lesson',
    result: 'chemistry_results',
    catalog: 'chemistry_catalog',
  ),
  (
    slug: 'jahon_tarixi',
    grade: 6,
    lesson: 'world_history_lesson',
    result: 'world_history_results',
    catalog: 'world_history_catalog',
  ),
  (
    slug: 'ozbekiston_tarixi',
    grade: 7,
    lesson: 'uzbekistan_history/lesson1',
    result: 'uzbekistan_history/result',
    catalog: 'uzbekistan_history/catalog7',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (!integratedBeta) {
    test(
      'normal build keeps the integrated beta disabled',
      () => expect(integratedBetaRequested, isFalse),
    );
    return;
  }
  test(
    'beta origin rejects production, LAN, credentials and mismatched host',
    () {
      requireBetaConfiguration('http://127.0.0.1:8930');
      expect(
        isBetaOrigin(Uri.parse('http://127.0.0.1:8930/beta/skills/subjects')),
        isTrue,
      );
      for (final uri in [
        'https://ilm-ai-backend-256x.onrender.com',
        'http://192.168.1.2:8930',
        'http://127.0.0.1:8925',
        'http://secret@127.0.0.1:8930',
      ]) {
        expect(isBetaOrigin(Uri.parse(uri)), isFalse);
      }
      expect(mobileAppScheme, 'ilmai-beta');
    },
  );
  test(
    'normal skills API uses integrated beta without preview endpoints',
    () async {
      final dio = Dio(BaseOptions(baseUrl: betaApiOrigin));
      RequestOptions? captured;
      dio.interceptors.add(MobileApiInterceptor());
      dio.httpClientAdapter = Adapter((options) {
        captured = options;
        return reply(200, []);
      });
      await dio.get('/skills/subjects');
      expect(captured!.path, '/beta/skills/subjects');
      dio.close();
    },
  );

  testWidgets(
    'onboarding shows five subjects, filters by grade and disables coming soon',
    (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();
      final names = [
        'Biologiya',
        'Fizika',
        'Kimyo',
        'O‘zbekiston tarixi',
        'Jahon tarixi',
        'Matematika',
        'Ona tili',
      ];
      final slugs = [
        'biologiya',
        'fizika',
        'kimyo',
        'ozbekiston_tarixi',
        'jahon_tarixi',
        'matematika',
        'ona_tili',
      ];
      final grades = [
        [5, 6, 7, 8, 9, 10, 11],
        [6, 7, 8, 9, 10, 11],
        [7, 8, 9, 10, 11],
        [7, 8, 9, 10, 11],
        [6, 7, 8, 9, 10, 11],
        <int>[],
        <int>[],
      ];
      final subjects = [
        for (var i = 0; i < names.length; i++)
          SkillSubject(
            id: i + 1,
            slug: slugs[i],
            nameUz: names[i],
            nameRu: names[i],
            nameEn: names[i],
            available: i < 5,
            grades: grades[i],
          ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(_LoggedOut.new),
            subjectCatalogProvider.overrideWith((ref) async => subjects),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in names) {
        expect(find.text(name), findsOneWidget);
      }
      final disabled = find
          .ancestor(of: find.text('Matematika'), matching: find.byType(InkWell))
          .first;
      expect(tester.widget<InkWell>(disabled).onTap, isNull);
      await tester.ensureVisible(find.text('6-sinf'));
      await tester.tap(find.text('6-sinf'));
      await tester.pumpAndSettle();
      expect(find.text('Fizika'), findsOneWidget);
      expect(find.text('Jahon tarixi'), findsOneWidget);
      expect(find.text('Kimyo'), findsNothing);
      expect(find.text('O‘zbekiston tarixi'), findsNothing);
      await tester.ensureVisible(find.text('7-sinf'));
      await tester.tap(find.text('7-sinf'));
      await tester.pumpAndSettle();
      expect(find.text('Kimyo'), findsOneWidget);
      expect(find.text('O‘zbekiston tarixi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final preset in presets) {
    late Dio dio;
    late Json lesson, result;
    late Map<String, Json> committed;
    late List<RequestOptions> requests;
    bool loseNextAnswer = false;
    bool completedNode = false;
    void setup({bool onlyFrq = false, bool completed = false}) {
      completedNode = completed;
      lesson = fixture(preset.lesson);
      final content = lesson['content'] as Json;
      lesson['content'] = {
        ...content,
        'formulas': content['formulas'] ?? [],
        'examples': content['examples'] ?? [],
        'reflections': content['reflections'] ?? [],
      };
      if (onlyFrq) {
        lesson['questions'] = [
          (lesson['questions'] as List).firstWhere(
            (q) => q['response_kind'] != 'concept_selection',
          ),
        ];
      }
      result = fixture(preset.result);
      committed = {};
      requests = [];
      loseNextAnswer = false;
      dio = Dio(BaseOptions(baseUrl: betaApiOrigin));
      // Dio otherwise moves these large history catalogues to a real isolate,
      // which cannot finish while the widget test advances its fake clock.
      dio.transformer = SyncTransformer();
      dio.httpClientAdapter = Adapter((request) {
        requests.add(request);
        if (request.path.endsWith('/catalog')) {
          return reply(200, fixture(preset.catalog));
        }
        if (request.path.endsWith('/start')) {
          final first =
              requests.where((r) => r.path.endsWith('/start')).length == 1;
          return reply(200, {
            ...lesson,
            'answers': Map.of(committed),
            if (completedNode && first)
              'result': {
                ...(result['result'] ?? result) as Map,
                'stars': 3,
                'elapsed_seconds': 20,
              },
          });
        }
        if (request.path.endsWith('/answers')) {
          final key = (request.data as Map)['assessment_key'] as String;
          // UI transport contract only; real answer correctness is exercised
          // against all five unchanged graders in test_integrated_beta.py.
          final responses = preset.slug == 'ozbekiston_tarixi'
              ? fixture('uzbekistan_history/feedback42')['responses'] as Map
              : result['answers'] as Map;
          final feedback = Map<String, dynamic>.from(
            (responses[key] ?? responses.values.first) as Map,
          )..['assessment_key'] = key;
          committed[key] = feedback;
          if (loseNextAnswer) {
            loseNextAnswer = false;
            throw DioException(
              requestOptions: request,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return reply(200, feedback);
        }
        if (request.path.endsWith('/complete')) {
          return reply(200, {
            ...(result['result'] ?? result) as Map,
            'stars': 3,
            'elapsed_seconds': 20,
          });
        }
        return reply(404, {'detail': 'unexpected_endpoint'});
      });
    }

    SkillTreeLesson descriptor() => SkillTreeLesson(
      id: -1,
      slug: lesson['lesson_key'] as String,
      assessmentKey: lesson['lesson_key'] as String,
      assessmentSubject: preset.slug,
      grade: preset.grade,
      titleUz: lesson['title'] as String,
      titleRu: lesson['title'] as String,
      titleEn: lesson['title'] as String,
      orderIndex: 1,
      xpReward: 10,
      status: completedNode ? LessonStatus.completed : LessonStatus.unlocked,
      stars: 0,
    );
    Future<PrefsService> mount(
      WidgetTester tester, {
      double scale = 1,
      PrefsService? store,
    }) async {
      if (store == null) SharedPreferences.setMockInitialValues({});
      final prefs = store ?? await PrefsService.create();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue(900777),
            dioProvider.overrideWithValue(dio),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: AssessmentLessonScreen(lesson: descriptor()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return prefs;
    }

    String display(String text) => preset.slug == 'kimyo'
        ? chemistryDisplayText(text)
        : preset.slug == 'jahon_tarixi'
        ? worldHistoryDisplayText(text)
        : text;
    List<Json> teaching() {
      final c = lesson['content'] as Json;
      return [
        for (final key in ['cards', 'formulas', 'examples', 'reflections'])
          for (final item in c[key] as List)
            Map<String, dynamic>.from(item as Map),
      ];
    }

    Future<void> action(WidgetTester tester) async {
      final button = find.byType(Duo3DButton).last;
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Future<void> exercises(WidgetTester tester) async {
      for (var i = 0; i < teaching().length; i++) {
        await action(tester);
      }
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '${preset.slug} preserves every teaching page and enters exercises at ${scale}x',
        (tester) async {
          setup();
          await tester.binding.setSurfaceSize(const Size(360, 740));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await mount(tester, scale: scale);
          for (final page in teaching()) {
            expect(find.text(display(page['title'] as String)), findsOneWidget);
            await action(tester);
            expect(tester.takeException(), isNull);
          }
          expect(
            find.text(
              display((lesson['questions'] as List).first['prompt'] as String),
            ),
            findsOneWidget,
          );
          expect(
            requests.any(
              (r) => r.path.startsWith('/preview') || r.path.startsWith('/qa'),
            ),
            isFalse,
          );
          await tester.pumpWidget(const SizedBox());
          dio.close();
        },
      );
      testWidgets(
        '${preset.slug} real FRQ editor stores input and shows common feedback at ${scale}x',
        (tester) async {
          setup(onlyFrq: true);
          await tester.binding.setSurfaceSize(const Size(360, 740));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await mount(tester, scale: scale);
          await exercises(tester);
          if (preset.slug == 'fizika') {
            for (final entry in [
              ('physics-formula', 'x/2'),
              ('physics-value', '2'),
              ('physics-unit', 'cm'),
            ]) {
              final field = find.byKey(Key(entry.$1));
              await tester.ensureVisible(field);
              await tester.enterText(field, entry.$2);
            }
          } else {
            final field = find.byType(TextField).first;
            await tester.ensureVisible(field);
            await tester.enterText(field, 'botanika');
          }
          await action(tester);
          expect(find.byType(LessonFeedbackPanel), findsOneWidget);
          expect(requests.where((r) => r.path.endsWith('/answers')).length, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          dio.close();
        },
      );
    }
    testWidgets(
      '${preset.slug} resumes the exact teaching page after widget restart',
      (tester) async {
        setup();
        final prefs = await mount(tester);
        await action(tester);
        await action(tester);
        final title = display(teaching()[2]['title'] as String);
        expect(find.text(title), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await mount(tester, store: prefs);
        expect(find.text(title), findsOneWidget);
        expect(
          requests
              .where((r) => r.path.endsWith('/start'))
              .map((r) => (r.data as Map)['request_id'])
              .toSet()
              .length,
          1,
        );
        await tester.pumpWidget(const SizedBox());
        dio.close();
      },
    );
    testWidgets(
      '${preset.slug} completed path starts a fresh review, not an old result',
      (tester) async {
        setup(completed: true);
        await mount(tester);
        expect(
          find.text(display(teaching().first['title'] as String)),
          findsOneWidget,
        );
        final starts = requests
            .where((r) => r.path.endsWith('/start'))
            .toList();
        expect(starts.length, 2);
        expect(
          (starts.first.data as Map)['request_id'],
          isNot((starts.last.data as Map)['request_id']),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        dio.close();
      },
    );
  }
}
