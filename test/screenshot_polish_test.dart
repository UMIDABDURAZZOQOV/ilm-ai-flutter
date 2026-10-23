import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/i18n/app_localizations.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/curriculum_learning_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/learning_invitation_card.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/learning_journey_widgets.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_leaderboard_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_profile_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_ui.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/streak_calendar_widget.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_home_screen.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/settings_screen.dart';
import 'release_hardening_test.dart' show Adapter, reply;
import 'subject_experience_test.dart' show FakeAuth;
import 'support/load_review_fonts.dart';
import 'support/offline_preferences.dart';
import 'uiux_visual_review_test.dart' show reviewFixture, reviewLeague;

final _subject = SkillSubject.fromJson(
  reviewFixture('biology_grade5_tree')['subject'],
);
String _pathAction(String lang) => str3(
  lang,
  'Dars yo‘liga o‘tish',
  'Перейти к урокам',
  'Go to learning path',
);
String _statistics(String lang) => str3(
  lang,
  'Statistika va faollik',
  'Статистика и активность',
  'Statistics and activity',
);

Map<String, dynamic> _profile([Map<String, dynamic> changes = const {}]) => {
  'name': 'UI review learner',
  'league': reviewLeague,
  'xp_total': 0,
  'streak_days': 0,
  'lessons_completed': 0,
  'activity': <String, int>{},
  'subjects': <dynamic>[],
  ...changes,
};

Dio _dio(
  List<RequestOptions> requests, {
  bool ranked = false,
  bool finished = false,
}) => Dio(BaseOptions(baseUrl: 'https://ui.example.test'))
  ..httpClientAdapter = Adapter((r) {
    requests.add(r);
    if (r.path.endsWith('/subjects')) {
      return reply(200, [reviewFixture('biology_grade5_tree')['subject']]);
    }
    if (r.path.endsWith('/grades')) {
      return reply(200, reviewFixture('biology_complete_grades'));
    }
    if (r.path.endsWith('/tree')) {
      final tree = reviewFixture('biology_grade5_tree');
      final unit = (tree['units'] as List).first as Map<String, dynamic>;
      final lesson = (unit['lessons'] as List).first as Map<String, dynamic>;
      return reply(200, {
        ...tree,
        'units': [
          {
            ...unit,
            'title_uz': 'UI unit',
            'title_ru': 'UI unit',
            'title_en': 'UI unit',
            'exam': {'status': 'none'},
            'coverage_complete': true,
            'lessons': [
              for (var i = 1; i <= 3; i++)
                {
                  ...lesson,
                  'id': i,
                  'slug': 'ui-$i',
                  'title_uz': 'UI lesson $i',
                  'title_ru': 'UI lesson $i',
                  'title_en': 'UI lesson $i',
                  'status': finished
                      ? 'completed'
                      : i == 1
                      ? 'unlocked'
                      : 'locked',
                  'stars': finished ? 2 : 0,
                },
            ],
          },
        ],
      });
    }
    if (r.path.endsWith('/curriculum')) {
      return reply(200, {
        'completed': false,
        'chapters': [
          {
            'title_uz': 'UI unit',
            'topics': [
              for (var i = 1; i <= 4; i++)
                {
                  'title_uz': 'UI topic $i',
                  'kind': 'topic',
                  'ready': i != 4,
                  'completed': i == 3,
                  'source': {'printed_start': i, 'printed_end': i + 1},
                },
            ],
          },
        ],
      });
    }
    if (r.path.endsWith('/profile')) return reply(200, _profile());
    if (r.path.endsWith('/league')) {
      return reply(200, {
        'league': reviewLeague,
        'weekly_xp': ranked ? 42 : 0,
        'xp_to_next': ranked ? 58 : 100,
        'next_league': {
          ...reviewLeague,
          'id': 'silver',
          'name_uz': 'Kumush',
          'name_ru': 'Серебро',
          'name_en': 'Silver',
          'min_xp': 100,
        },
        'all_tiers': [reviewLeague],
      });
    }
    if (r.path.endsWith('/weekly')) {
      return reply(200, {
        'entries': ranked
            ? [
                {
                  'rank': 1,
                  'user_id': 7,
                  'name': 'UI review learner',
                  'weekly_xp': 42,
                  'league': 'bronze',
                  'is_me': true,
                },
              ]
            : [],
        'own_rank': ranked ? 1 : null,
        'total_participants': ranked ? 1 : 0,
      });
    }
    throw StateError('Unexpected isolated UI request: ${r.method} ${r.path}');
  });

Future<PrefsService> _mount(
  WidgetTester tester,
  Widget screen, {
  String lang = 'en',
  bool dark = false,
  Size size = const Size(360, 800),
  double scale = 1,
  Map<String, dynamic>? profile,
  Dio? dio,
  GoRouter? router,
  Map<String, Object> saved = const {},
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  SharedPreferences.setMockInitialValues({
    PrefsKeys.language: lang,
    'class_7': '5',
    'subject_7': 'biologiya',
    ...saved,
  });
  final prefs = await PrefsService.create();
  final client = dio ?? _dio([]);
  if (dio == null) addTearDown(() => client.close(force: true));
  Widget builder(BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  );
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        prefsServiceProvider.overrideWithValue(prefs),
        currentUserIdProvider.overrideWithValue(7),
        authControllerProvider.overrideWith(FakeAuth.new),
        dioProvider.overrideWithValue(client),
        skillTreeRepositoryProvider.overrideWithValue(
          SkillTreeRepository(client),
        ),
        skillExtrasRepositoryProvider.overrideWithValue(
          SkillExtrasRepository(client, lang),
        ),
        learningPreferencesProvider.overrideWithValue(
          OfflinePreferences(prefs),
        ),
        if (profile != null)
          skillProfileProvider.overrideWith(
            (_) async => SkillProfile.fromJson(profile),
          ),
      ],
      child: router == null
          ? MaterialApp(
              theme: buildAppTheme(dark ? darkColors : lightColors),
              builder: builder,
              home: screen,
            )
          : MaterialApp.router(
              theme: buildAppTheme(dark ? darkColors : lightColors),
              builder: builder,
              routerConfig: router,
            ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return prefs;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      160,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(loadReviewFonts);

  testWidgets(
    'first home has one lesson title/action and a compact usable goal',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <RequestOptions>[];
      final dio = _dio(requests);
      addTearDown(() => dio.close(force: true));
      await _mount(tester, const SubjectHomeScreen(), dio: dio);
      expect(find.text('UI lesson 1'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
      final panel = find.byType(LearningContinueCard);
      expect(tester.getSize(panel).height, lessThan(180));
      expect(
        find.byType(LearningJourneyTile).first.hitTestable(),
        findsOneWidget,
      );
      expect(requests.every((r) => r.method == 'GET'), true);
      await _tap(tester, find.text('DAILY GOAL'));
      expect(find.byType(BottomSheet), findsOneWidget);
    },
  );

  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'outline $lang/$dark separates content readiness from access',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final requests = <RequestOptions>[];
          final dio = _dio(requests);
          addTearDown(() => dio.close(force: true));
          await _mount(
            tester,
            CurriculumLearningScreen(subject: _subject, onChangeSubject: () {}),
            lang: lang,
            dark: dark,
            dio: dio,
          );
          expect(
            tester
                .widgetList<LearningJourneyTile>(
                  find.byType(LearningJourneyTile),
                )
                .any((row) => row.title == 'UI lesson 2' && row.locked),
            true,
          );
          await _tap(
            tester,
            find.text(str3(lang, 'Mavzular', 'Темы', 'Topics')),
          );
          final sheet = find.byType(BottomSheet);
          final prepared = str3(
            lang,
            'Kontent tayyor',
            'Контент подготовлен',
            'Content prepared',
          );
          expect(
            find.descendant(
              of: sheet,
              matching: find.byWidgetPredicate(
                (w) => w is Text && (w.data?.endsWith(' · $prepared') ?? false),
              ),
            ),
            findsNWidgets(2),
          );
          expect(
            find.descendant(
              of: sheet,
              matching: find.byIcon(Icons.play_circle_outline_rounded),
            ),
            findsNothing,
          );
          expect(
            find.textContaining(
              str3(
                lang,
                'ketma-ket ochiladi',
                'открываются по порядку',
                'unlock in order',
              ),
            ),
            findsOneWidget,
          );
          for (final tile in tester.widgetList<ListTile>(
            find.descendant(of: sheet, matching: find.byType(ListTile)),
          )) {
            expect(tile.onTap, isNull);
          }
          await _tap(
            tester,
            find.text(
              str3(
                lang,
                'Dars yo‘liga qaytish',
                'Вернуться к урокам',
                'Back to learning path',
              ),
            ),
          );
          expect(find.byType(BottomSheet), findsNothing);
          expect(requests.every((r) => r.method == 'GET'), true);
        },
      );

      for (final size in [const Size(320, 568), const Size(640, 360)]) {
        testWidgets(
          'compact goal $lang/$dark/$size at 200% keeps both goal and later-entry actions',
          (tester) async {
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            var goals = 0, entries = 0;
            final goalLabel = str3(
              lang,
              'KUNLIK MAQSAD',
              'ЦЕЛЬ ДНЯ',
              'DAILY GOAL',
            );
            for (final quickEntry in [false, true]) {
              await _mount(
                tester,
                Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: LearningContinueCard(
                      compact: true,
                      language: lang,
                      title: 'Current lesson with a longer title',
                      todayXp: 10,
                      goalXp: 30,
                      onGoal: () => goals++,
                      courseNote: str3(
                        lang,
                        'Tayyor darslar: 406',
                        'Подготовлено уроков: 406',
                        'Lessons prepared: 406',
                      ),
                      onContinue: quickEntry ? () => entries++ : null,
                    ),
                  ),
                ),
                lang: lang,
                dark: dark,
                size: size,
                scale: 2,
              );
              expect(
                find.text('Current lesson with a longer title'),
                quickEntry ? findsOneWidget : findsNothing,
              );
              await _tap(tester, find.text(goalLabel));
              final goal = find
                  .ancestor(
                    of: find.text(goalLabel),
                    matching: find.byType(InkWell),
                  )
                  .first;
              expect(tester.getSize(goal).height, greaterThanOrEqualTo(48));
              if (quickEntry) {
                await _tap(
                  tester,
                  find.text(
                    str3(lang, 'DAVOM ETISH', 'ПРОДОЛЖИТЬ', 'CONTINUE'),
                  ),
                );
              }
            }
            expect(goals, 2);
            expect(entries, 1);
          },
        );
        testWidgets(
          'empty profile and league $lang/$dark/$size at 200% have real actions',
          (tester) async {
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            try {
              var opened = 0;
              await _mount(
                tester,
                SkillProfileScreen(onOpenLearning: () => opened++),
                profile: _profile(),
                lang: lang,
                dark: dark,
                size: size,
                scale: 2,
              );
              expect(find.byType(StreakCalendarWidget), findsNothing);
              expect(find.byType(LearningInvitationCard), findsOneWidget);
              await _tap(tester, find.text(_pathAction(lang)));
              expect(opened, 1);
              final stats = find.text(_statistics(lang));
              await _tap(tester, stats);
              expect(find.byType(StreakCalendarWidget), findsOneWidget);
              await _tap(tester, stats);
              expect(find.byType(StreakCalendarWidget), findsNothing);
              await _mount(
                tester,
                SkillLeaderboardScreen(onOpenLearning: () => opened++),
                lang: lang,
                dark: dark,
                size: size,
                scale: 2,
              );
              await _tap(tester, find.text(_pathAction(lang)));
              expect(find.byType(LearningInvitationCard), findsOneWidget);
              expect(opened, 2);
            } finally {
              semantics.dispose();
            }
          },
        );
      }
      testWidgets(
        'logout $lang/$dark is explicit, secondary and cancellation keeps session',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _mount(
            tester,
            const SettingsScreen(),
            lang: lang,
            dark: dark,
            size: const Size(320, 568),
            scale: 2,
          );
          final label = t('settings.logout', lang);
          await _tap(tester, find.text(label));
          expect(find.byType(AlertDialog), findsOneWidget);
          await _tap(tester, find.text(t('common.cancel', lang)));
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.byType(SettingsScreen), findsOneWidget);
          expect(
            ProviderScope.containerOf(
              tester.element(find.byType(SettingsScreen)),
            ).read(authControllerProvider).valueOrNull?.userId,
            7,
          );
        },
      );
    }
  }

  testWidgets('completed home retains review guidance and completed lessons', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = _dio([], finished: true);
    addTearDown(() => dio.close(force: true));
    await _mount(tester, const SubjectHomeScreen(), dio: dio);
    expect(find.text('Choose a lesson to practise again'), findsOneWidget);
    expect(
      tester
          .widget<LearningContinueCard>(find.byType(LearningContinueCard))
          .compact,
      false,
    );
    expect(
      tester
          .widgetList<LearningJourneyTile>(find.byType(LearningJourneyTile))
          .every((row) => row.completed),
      true,
    );
  });

  final progressVariants = <String, Map<String, dynamic>>{
    'XP': {'xp_total': 10},
    'lesson': {'lessons_completed': 1},
    'streak': {'streak_days': 1},
    'activity': {
      'activity': {'2026-10-01': 1},
    },
    'subject': {
      'subjects': [
        {
          'slug': 'biologiya',
          'name_en': 'Biology',
          'completed': 1,
          'total': 406,
        },
      ],
    },
    'stars': {
      'subjects': [
        {'slug': 'biologiya', 'name_en': 'Biology', 'stars': 1, 'total': 406},
      ],
    },
    'strongest': {
      'strongest': {'slug': 'biologiya', 'name_en': 'Biology', 'pct': 10},
    },
  };
  for (final entry in progressVariants.entries) {
    testWidgets(
      '${entry.key} preserves the established profile without an empty invitation',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mount(
          tester,
          const SkillProfileScreen(),
          profile: _profile(entry.value),
        );
        expect(find.byType(LearningInvitationCard), findsNothing);
        expect(find.byType(StreakCalendarWidget), findsOneWidget);
        expect(find.byType(ExpansionTile), findsNothing);
      },
    );
  }

  testWidgets('ranked league preserves real entries, XP and rank', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = <RequestOptions>[];
    final dio = _dio(requests, ranked: true);
    addTearDown(() => dio.close(force: true));
    await _mount(tester, const SkillLeaderboardScreen(), dio: dio);
    expect(find.byType(LearningInvitationCard), findsNothing);
    expect(find.text('UI review learner'), findsOneWidget);
    expect(find.text('42 XP'), findsOneWidget);
    expect(find.textContaining('Your rank: #1'), findsOneWidget);
    expect(requests.every((r) => r.method == 'GET'), true);
  });

  for (final profile in [false, true]) {
    testWidgets(
      'standalone ${profile ? 'profile' : 'league'} action uses existing learn route',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          initialLocation: '/account',
          routes: [
            GoRoute(
              path: '/account',
              builder: (_, _) => profile
                  ? const SkillProfileScreen()
                  : const SkillLeaderboardScreen(),
            ),
            GoRoute(
              path: '/learn',
              builder: (_, _) =>
                  const Scaffold(body: Text('Learning destination')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await _mount(tester, const SizedBox(), router: router);
        await _tap(tester, find.text(_pathAction('en')));
        expect(find.text('Learning destination'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'empty-state tab actions preserve course selection, goal and loaded tree',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <RequestOptions>[];
      final dio = _dio(requests);
      addTearDown(() => dio.close(force: true));
      final prefs = await _mount(
        tester,
        const SubjectHomeScreen(),
        dio: dio,
        saved: {'daily_goal_7': 30},
      );
      final treeCalls = requests.where((r) => r.path.endsWith('/tree')).length;
      for (final tab in ['Profile', 'League', 'Profile', 'League']) {
        await _tap(tester, find.text(tab).last);
        await _tap(tester, find.text(_pathAction('en')));
        expect(find.text('0/30 XP'), findsOneWidget);
        expect(prefs.getInt('daily_goal_7'), 30);
        expect(find.text('UI lesson 1'), findsOneWidget);
        expect(
          requests.where((r) => r.path.endsWith('/tree')).length,
          treeCalls,
        );
        expect(prefs.getString('class_7'), '5');
        expect(prefs.getString('subject_7'), 'biologiya');
      }
      expect(requests.every((r) => r.method == 'GET'), true);
    },
  );

  for (final dark in [false, true]) {
    for (final name in ['home', 'profile', 'league']) {
      testWidgets('polished $name golden ${dark ? 'dark' : 'light'}', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final screen = switch (name) {
          'home' => const SubjectHomeScreen(),
          'profile' => const SkillProfileScreen(),
          _ => const SkillLeaderboardScreen(),
        };
        await _mount(
          tester,
          RepaintBoundary(key: key, child: screen),
          dark: dark,
        );
        await expectLater(
          find.byKey(key),
          matchesGoldenFile(
            'goldens/polish_${name}_${dark ? 'dark' : 'light'}.png',
          ),
        );
      });
    }
  }
}
