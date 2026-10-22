// Real widgets with isolated, labelled test fixtures. Never contacts a backend.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/i18n/app_localizations.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/services/sound_service.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/login_screen.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/duo_onboarding_screen.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/settings_screen.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_home_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_lesson_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_profile_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_quests_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_leaderboard_screen.dart';
import 'release_hardening_test.dart' show Adapter, reply;
import 'subject_experience_test.dart' show FakeAuth;
import 'support/offline_preferences.dart';

Map<String, dynamic> reviewFixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const reviewLeague = {
  'id': 'bronze',
  'name_uz': 'Bronza',
  'name_ru': 'Бронза',
  'name_en': 'Bronze',
  'min_xp': 0,
  'color': '#CD7F32',
};

Dio reviewDio({bool loading = false}) =>
    Dio(BaseOptions(baseUrl: 'https://ui.example.test'))
      ..httpClientAdapter = Adapter((request) {
        final path = request.path;
        if (loading && path.endsWith('/subjects')) return reply(503, {});
        if (path.endsWith('/subjects')) {
          return reply(200, [reviewFixture('biology_grade5_tree')['subject']]);
        }
        if (path.endsWith('/grades')) {
          return reply(200, reviewFixture('biology_complete_grades'));
        }
        if (path.endsWith('/tree')) {
          return reply(200, reviewFixture('biology_grade5_tree'));
        }
        if (path.endsWith('/curriculum')) {
          return reply(200, reviewFixture('biology_grade5_outline'));
        }
        if (path.endsWith('/start')) {
          return reply(200, reviewFixture('biology_first_lesson'));
        }
        if (path.endsWith('/complete')) {
          return reply(200, reviewFixture('biology_first_result'));
        }
        if (path.endsWith('/profile')) {
          return reply(200, {
            'name': 'UI review learner',
            'league': reviewLeague,
            'xp_total': 0,
            'streak_days': 0,
            'lessons_completed': 0,
            'activity': <String, int>{},
            'subjects': <dynamic>[],
          });
        }
        if (path.endsWith('/league')) {
          return reply(200, {
            'league': reviewLeague,
            'weekly_xp': 0,
            'xp_to_next': 100,
            'next_league': {
              ...reviewLeague,
              'id': 'silver',
              'name_ru': 'Серебро',
            },
            'all_tiers': [reviewLeague],
          });
        }
        if (path.endsWith('/weekly')) {
          return reply(200, {'entries': [], 'total_participants': 0});
        }
        if (path.endsWith('/daily-challenge')) {
          return reply(200, {'completed': false, 'questions': []});
        }
        if (path.endsWith('/streak-freezes')) return reply(200, {'count': 0});
        if (path.endsWith('/summary')) {
          return reply(200, {
            'xp_total': 0,
            'streak_days': 0,
            'today_xp': 0,
            'daily_goal_xp': 20,
          });
        }
        if (path == '/health') return reply(200, {'status': 'ok'});
        throw StateError('Unexpected isolated UI request: $path');
      });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('UIUX_CAPTURE');
  const stage = String.fromEnvironment('UIUX_STAGE', defaultValue: 'current');
  setUpAll(() async {
    if (capture) {
      final font = File(
        'C:/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
      );
      if (font.existsSync()) {
        for (final family in ['Roboto', 'Ahem']) {
          final loader = FontLoader(family);
          for (final weight in ['regular', 'medium', 'bold']) {
            loader.addFont(
              Future.value(
                ByteData.sublistView(
                  File(
                    'C:/flutter/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
                  ).readAsBytesSync(),
                ),
              ),
            );
          }
          await loader.load();
        }
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  'C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
                ).readAsBytesSync(),
              ),
            ),
          );
        await icons.load();
      }
    }
  });

  for (final dark in [false, true]) {
    testWidgets(
      'important screens ${dark ? 'dark' : 'light'} use real widgets and isolated fixtures',
      (tester) async {
        tester.view.physicalSize = const Size(720, 1600);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final dio = reviewDio();
        addTearDown(() => dio.close(force: true));
        final key = GlobalKey();
        Future<void> mount(
          Widget screen, {
          bool grade = true,
          String lang = 'ru',
        }) async {
          // A new route tree, not a global-key reparent of a visited tab.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          SharedPreferences.setMockInitialValues({
            PrefsKeys.language: lang,
            'subject_7': 'biologiya',
            if (grade) 'class_7': '5',
          });
          final prefs = await PrefsService.create();
          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                prefsServiceProvider.overrideWithValue(prefs),
                currentUserIdProvider.overrideWithValue(7),
                authControllerProvider.overrideWith(FakeAuth.new),
                dioProvider.overrideWithValue(dio),
                learningPreferencesProvider.overrideWithValue(
                  OfflinePreferences(prefs),
                ),
                skillTreeRepositoryProvider.overrideWithValue(
                  SkillTreeRepository(dio),
                ),
                skillExtrasRepositoryProvider.overrideWithValue(
                  SkillExtrasRepository(dio, lang),
                ),
                soundServiceProvider.overrideWithValue(FakeSoundService()),
              ],
              child: RepaintBoundary(
                key: key,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildAppTheme(dark ? darkColors : lightColors),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(disableAnimations: true),
                    child: child!,
                  ),
                  home: screen,
                ),
              ),
            ),
          );
          await tester.pump();
          // Nested providers and Dio response transforms can span more than
          // one frame. Do not mislabel the loading frame as a populated home.
          for (var frame = 0; frame < 8; frame++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        Future<void> save(String name) async {
          expect(tester.takeException(), isNull, reason: name);
          if (!capture) return;
          await tester.runAsync(() async {
            await Future.wait([
              for (final image in tester.widgetList<Image>(find.byType(Image)))
                precacheImage(image.image, key.currentContext!),
            ]);
          });
          await tester.pump(const Duration(milliseconds: 500));
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              '.dart_tool/uiux-review/$stage/${dark ? 'dark' : 'light'}-$name.png',
            );
            file.parent.createSync(recursive: true);
            file.writeAsBytesSync(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        Future<void> tapText(String text) async {
          final target = find.text(text).first;
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        await mount(const SubjectHomeScreen());
        expect(find.text('0/20 XP'), findsOneWidget);
        await save('home');
        await tapText('Темы');
        await save('outline');
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
        final node = find.byIcon(Icons.star_rounded).first;
        await tester.ensureVisible(node);
        await tester.tap(node);
        await tester.pumpAndSettle();
        await save('start');
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
        await tapText('Практика');
        await save('practice');
        await mount(const SubjectHomeScreen(), grade: false);
        expect(find.text('С какого класса начнём?'), findsOneWidget);
        await save('grades');
        await mount(const SkillProfileScreen());
        await save('profile');
        await mount(const SkillQuestsScreen());
        await save('quests');
        await mount(const SkillLeaderboardScreen());
        await save('league');
        await mount(const SettingsScreen());
        await save('settings');
        await mount(const LoginScreen());
        await save('login');
        await mount(const DuoOnboardingScreen(initialStep: 11));
        await save('onboarding');
        final tree = SkillTreeResponse.fromJson(
          reviewFixture('biology_grade5_tree'),
        );
        final lesson = tree.units.first.lessons.first;
        await mount(SkillLessonScreen(lesson: lesson));
        await save('theory');
        final start = LessonStartResult.fromJson(
          reviewFixture('biology_first_lesson'),
        );
        for (var i = 0; i < start.theory.length; i++) {
          await tapText(
            i + 1 == start.theory.length
                ? t('skills.start_quiz', 'ru')
                : t('skills.lesson.continue', 'ru'),
          );
        }
        await save('quiz');
        await tapText(
          start.questions.first.options.firstWhere(
            (s) => s != start.questions.first.correctAnswer,
          ),
        );
        await tapText('ПРОВЕРИТЬ');
        await save('feedback');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}
