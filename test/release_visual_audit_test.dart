// Actual widgets, isolated transports and synthetic identity. No live AI claim.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/services/sound_service.dart';
import 'package:ilm_ai_flutter/core/splash/splash_screen.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/login_screen.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ilm_ai_flutter/features/settings/data/account_deletion_repository.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/account_deletion_button.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/settings_screen.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_home_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_switch_sheet.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_profile_screen.dart';
import 'package:ilm_ai_flutter/features/study_help/study_help.dart';
import 'release_hardening_test.dart' show Adapter, reply;
import 'subject_experience_test.dart' show FakeAuth;
import 'study_help_test.dart' show subjects, evidence;
import 'support/load_review_fonts.dart';
import 'support/offline_preferences.dart';
import 'uiux_visual_review_test.dart' show reviewDio, reviewFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('UIUX_CAPTURE');
  const stage = String.fromEnvironment(
    'UIUX_STAGE',
    defaultValue: 'final-audit',
  );
  setUpAll(() async {
    if (capture) await loadReviewFonts();
  });
  for (final dark in [false, true]) {
    for (final compact in [false, true]) {
      testWidgets('release screen visual audit dark=$dark compact200=$compact', (
        tester,
      ) async {
        final size = compact ? const Size(320, 568) : const Size(360, 800);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        FlutterSecureStorage.setMockInitialValues({});
        final dio = reviewDio();
        final deletionDio = Dio()
          ..httpClientAdapter = Adapter((r) {
            if (r.path.endsWith('/config')) {
              return reply(200, {'available': true, 'email_required': false});
            }
            if (r.path.endsWith('/options')) {
              return reply(200, {'method': 'google'});
            }
            throw StateError(
              'No deletion or reauthentication permitted in visual audit',
            );
          });
        final helpDio = Dio()
          ..httpClientAdapter = Adapter((_) => reply(200, evidence()));
        addTearDown(() {
          dio.close(force: true);
          deletionDio.close(force: true);
          helpDio.close(force: true);
        });
        final key = GlobalKey();
        Future<void> mount(
          Widget child, {
          bool loading = false,
          bool offline = false,
        }) async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          SharedPreferences.setMockInitialValues({
            PrefsKeys.language: 'uz',
            'subject_7': 'biologiya',
            'class_7': '5',
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
                skillTreeRepositoryProvider.overrideWithValue(
                  SkillTreeRepository(dio),
                ),
                skillExtrasRepositoryProvider.overrideWithValue(
                  SkillExtrasRepository(dio, 'uz'),
                ),
                learningPreferencesProvider.overrideWithValue(
                  OfflinePreferences(prefs),
                ),
                soundServiceProvider.overrideWithValue(FakeSoundService()),
                accountDeletionRepositoryProvider.overrideWithValue(
                  AccountDeletionRepository(deletionDio),
                ),
                studyHelpRepositoryProvider.overrideWithValue(
                  StudyHelpRepository(helpDio),
                ),
                subjectCatalogProvider.overrideWith(
                  (_) => offline
                      ? Future<List<SkillSubject>>.error(
                          TimeoutException('synthetic offline'),
                        )
                      : loading
                      ? Completer<List<SkillSubject>>().future
                      : Future.value([
                          SkillSubject.fromJson({
                            ...reviewFixture('biology_grade5_tree')['subject']
                                as Map<String, dynamic>,
                            'available': true,
                            'grades': [5, 6, 7, 8, 9, 10, 11],
                          }),
                          ...subjects.where((s) => s.slug != 'biologiya'),
                        ]),
                ),
              ],
              child: RepaintBoundary(
                key: key,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildAppTheme(dark ? darkColors : lightColors),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      disableAnimations: true,
                      textScaler: TextScaler.linear(compact ? 2 : 1),
                    ),
                    child: child!,
                  ),
                  home: child,
                ),
              ),
            ),
          );
          await tester.pump();
          for (var i = 0; i < 8; i++) {
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
              for (final img in tester.widgetList<Image>(find.byType(Image)))
                precacheImage(img.image, key.currentContext!),
            ]);
          });
          await tester.pump(const Duration(milliseconds: 500));
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              '.dart_tool/uiux-review/$stage/${dark ? 'dark' : 'light'}-${compact ? '320-200' : '360-100'}-$name.png',
            );
            file.parent.createSync(recursive: true);
            file.writeAsBytesSync(data!.buffer.asUint8List());
            image.dispose();
          });
          expect(tester.takeException(), isNull, reason: '$name capture');
        }

        await mount(const SplashScreen());
        await save('splash');
        await mount(const LoginScreen());
        await save('login');
        await mount(const OnboardingScreen());
        await save('onboarding');
        await mount(const SubjectHomeScreen(), loading: true);
        await save('home-loading');
        await mount(const SubjectHomeScreen(), offline: true);
        await save('home-offline');
        await mount(const SubjectHomeScreen());
        await save('home-path');
        await mount(const SkillProfileScreen());
        await save('profile');
        await mount(const SettingsScreen());
        await save('settings');
        await mount(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSubjectSwitcher(
                  context,
                  subjects: subjects,
                  language: 'uz',
                  grade: 5,
                  currentSubject: 'biologiya',
                ),
                child: const Text('Fanlar'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Fanlar'));
        await tester.pumpAndSettle();
        await save('subject-selection');
        await mount(const Scaffold(body: AccountDeletionButton()));
        await tester.tap(find.byKey(const ValueKey('delete_account_entry')));
        await tester.pumpAndSettle();
        await save('deletion');
        await tester.ensureVisible(
          find.byKey(const ValueKey('delete_account_submit')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('delete_account_submit')).hitTestable(),
          findsOneWidget,
        );
        await save('deletion-actions');
        await mount(
          const Scaffold(
            body: StudyHelpButton(
              contextData: StudyHelpContext(
                subject: 'kimyo',
                grade: 7,
                attemptId: 'owned',
                questionKey: 'q',
                checked: true,
              ),
              language: 'uz',
            ),
          ),
        );
        final entry = find.byKey(const ValueKey('question_study_help'));
        if (entry.evaluate().isNotEmpty) {
          await tester.tap(entry);
          await tester.pumpAndSettle();
          await save('ai-reviewed-fallback');
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }

  testWidgets(
    'catalogue error actions remain reachable in short landscape at 200%',
    (tester) async {
      tester.view.physicalSize = const Size(640, 240);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(FakeAuth.new),
            subjectCatalogProvider.overrideWith(
              (_) => Future.error(TimeoutException('synthetic offline')),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const SubjectHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final settings = find.text('Sozlamalar');
      await tester.ensureVisible(settings);
      await tester.pumpAndSettle();
      expect(settings.hitTestable(), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
