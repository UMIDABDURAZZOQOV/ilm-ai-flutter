import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/app.dart';
import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/login_screen.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/language_select_screen.dart';
import 'package:ilm_ai_flutter/features/phone_qa/phone_qa_hub.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/learning_path_sections.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_home_screen.dart';
import 'release_hardening_test.dart' show Adapter, reply;

void main() {
  if (!integratedBeta) {
    test(
      'beta shell remains opt-in',
      () => expect(integratedBetaRequested, false),
    );
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  final subjects = [
    for (final (i, slug) in betaSubjectSlugs.indexed)
      {
        'id': i + 1,
        'slug': slug,
        'name_uz': slug,
        'name_ru': slug,
        'name_en': slug,
        'available': true,
        'grades': [7],
      },
  ];
  testWidgets('ordinary app starts with language selection, not QA hub', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await PrefsService.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsServiceProvider.overrideWithValue(prefs)],
        child: const IlmAiApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LanguageSelectScreen), findsOneWidget);
    expect(find.byType(PhoneQaHub), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'normal login stores runtime credentials, restores and logs in again',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.onboardingComplete: true,
        PrefsKeys.language: 'uz',
        'class_901': '7',
      });
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await PrefsService.create();
      final identities = <String>[];
      final dio = Dio(BaseOptions(baseUrl: betaApiOrigin));
      dio.httpClientAdapter = Adapter((r) {
        if (r.path == '/beta/config') {
          return reply(200, {
            'google_configured': false,
            'test_auth_available': true,
          });
        }
        if (r.path == '/beta/auth/test-login') {
          identities.add((r.data as Map)['installation_secret'] as String);
          return reply(200, {
            'access_token': 'widget-only-access',
            'refresh_token': 'widget-only-refresh',
            'user_id': 901,
            'name': 'Beta learner',
            'email': 'test@example.test',
            'needs_onboarding': false,
          });
        }
        if (r.path.endsWith('/preferences')) {
          return reply(200, {
            'preferences': {'grade': '7'},
          });
        }
        if (r.path.endsWith('/subjects')) return reply(200, subjects);
        if (r.path == '/auth/profile/901') {
          return reply(200, {'needs_onboarding': false});
        }
        if (r.path == '/auth/logout') return reply(200, {'ok': true});
        return reply(404, {'detail': 'widget_endpoint_not_stubbed'});
      });
      Future<ProviderContainer> mount() async {
        final container = ProviderContainer(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            dioProvider.overrideWithValue(dio),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const IlmAiApp(),
          ),
        );
        await tester.pumpAndSettle();
        return container;
      }

      var container = await mount();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('Google kirish lokal beta serverida hali sozlanmagan.'),
        findsOneWidget,
      );
      Future<void> login() async {
        final button = find.text('Ichki beta orqali davom etish');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.byType(SubjectHomeScreen), findsOneWidget);
        expect(find.byType(PhoneQaHub), findsNothing);
      }

      await login();
      expect(identities.single, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      for (final slug in betaSubjectSlugs) {
        await tester.scrollUntilVisible(find.text(slug), 200);
        expect(find.text(slug), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      container = await mount();
      expect(find.byType(SubjectHomeScreen), findsOneWidget);
      expect(identities.length, 1); // Secure tokens restored without new login.
      await container.read(authControllerProvider.notifier).logout();
      await tester.pumpAndSettle();
      await login();
      expect(identities.length, 2);
      expect(identities.last, identities.first); // Same installation/account.
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      dio.close();
    },
  );

  testWidgets(
    'long chapter uses ten-item ranges without unlocking future lessons',
    (tester) async {
      final lessons = [
        for (var i = 1; i <= 31; i++)
          SkillTreeLesson(
            id: i,
            slug: 'item-$i',
            titleUz: 'Item $i',
            titleRu: 'Item $i',
            titleEn: 'Item $i',
            orderIndex: i,
            xpReward: 10,
            status: i == 1 ? LessonStatus.unlocked : LessonStatus.locked,
            stars: 0,
          ),
      ];
      final unit = SkillTreeUnit(
        id: 1,
        slug: 'original-section',
        titleUz: 'Original section',
        titleRu: 'Original section',
        titleEn: 'Original section',
        orderIndex: 1,
        lessons: lessons,
        examStatus: 'none',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(
            body: LearningPathSections(
              storageKey: 'pagination',
              language: 'uz',
              units: [unit],
              currentUnitId: 1,
              pageSize: 10,
              leading: const SizedBox(),
              itemBuilder: (_, lesson) => Text(lesson!.titleUz),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 11'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('21–30').last);
      await tester.pumpAndSettle();
      expect(find.text('Item 21'), findsOneWidget);
      expect(lessons[20].status, LessonStatus.locked);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Learn quick switch saves subject and grade without changing drafts',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'subject_1': 'fizika',
        PrefsKeys.language: 'uz',
        'class_1': '7',
        'assessment_draft_sentinel': 'existing progress',
        'subject_2': 'biologiya',
      });
      final prefs = await PrefsService.create();
      final dio = Dio(BaseOptions(baseUrl: betaApiOrigin));
      dio.httpClientAdapter = Adapter((r) {
        if (r.path.endsWith('/grades')) {
          return reply(200, {
            'grades': [
              for (final g in [7, 8])
                {
                  'grade': g,
                  'title_uz': 'Source grade $g',
                  'status': 'mapped',
                  'ready_lessons': 0,
                },
            ],
          });
        }
        if (r.path.endsWith('/preferences')) return reply(200, {'ok': true});
        return reply(404, {});
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue(1),
            dioProvider.overrideWithValue(dio),
            subjectCatalogProvider.overrideWith(
              (ref) async => [
                for (final slug in ['fizika', 'kimyo'])
                  SkillSubject(
                    id: 1,
                    slug: slug,
                    nameUz: slug,
                    nameRu: slug,
                    nameEn: slug,
                    grades: [7, 8],
                  ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const SubjectHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('subject_study_chat')), findsNothing);
      expect(find.text('AI savol'), findsNothing);
      expect(find.text('AI tushuntirish'), findsNothing);
      final switchButton = tester.widget<TextButton>(
        find.byKey(const ValueKey('quick_subject_switch')),
      );
      switchButton.onPressed!();
      switchButton.onPressed!();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('switch_grade')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('switch_grade')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8-sinf').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('switch_kimyo')));
      await tester.pumpAndSettle();
      expect(prefs.getString('subject_1'), 'kimyo');
      expect(prefs.getString('class_1'), '8');
      expect(prefs.getString('assessment_draft_sentinel'), 'existing progress');
      expect(prefs.getString('subject_2'), 'biologiya');
      expect(find.text('kimyo · 8-sinf'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dio.close();
    },
  );
}
