import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/application/google_auth.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_models.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_repository.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/duo_onboarding_screen.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';

class _MockAuthRepo extends AuthRepository {
  _MockAuthRepo() : super(Dio());

  int? savedUserId;
  String? savedName;
  int? savedAge;

  @override
  Future<void> completeOnboarding({
    required int userId,
    required String name,
    required int age,
  }) async {
    savedUserId = userId;
    savedName = name;
    savedAge = age;
  }

  @override
  Future<String> updateProfile(UpdateProfileRequest req) async => 'OK';
}

class _MockSkillTreeRepo extends SkillTreeRepository {
  _MockSkillTreeRepo() : super(Dio());

  @override
  Future<List<SkillSubject>> getSubjects() async => [
        SkillSubject(
          id: 1,
          slug: 'math',
          nameUz: 'Matematika',
          nameRu: 'Математика',
          nameEn: 'Mathematics',
          icon: 'math',
          color: '#2A1F6B',
        ),
        SkillSubject(
          id: 2,
          slug: 'physics',
          nameUz: 'Fizika',
          nameRu: 'Физика',
          nameEn: 'Physics',
          icon: 'physics',
          color: '#2DD4BF',
        ),
      ];
}

class _MockSkillExtrasRepo extends SkillExtrasRepository {
  _MockSkillExtrasRepo() : super(Dio(), 'uz');

  @override
  Future<List<PracticeQuestion>> getPlacement(
          int userId, String subject) async =>
      [];
}

class _MockAuthController extends AuthController {
  @override
  Future<StoredTokens?> build() async => const StoredTokens(
        accessToken: 'mock_access',
        refreshToken: 'mock_refresh',
        userId: 99,
        name: 'Ali Valiyev',
      );

  @override
  Future<void> updateDisplayName(String name) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Duolingo Onboarding Flow Tests (Stage 0B)', () {
    testWidgets('Step 0: Language selection updates language immediately', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title in Uzbek
      expect(find.text("Qaysi tilda o'rganishni xohlaysiz?"), findsOneWidget);

      // Select Russian
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();

      // Speech bubble updates to Russian immediately
      expect(
          find.text('На каком языке вы хотите учиться?'), findsOneWidget);
      expect(container.read(languageProvider), 'ru');

      // Select English
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(
          find.text('Which language do you want to learn in?'), findsOneWidget);
      expect(container.read(languageProvider), 'en');
    });

    testWidgets('Step 1 to Step 2 flow: Hello Ilmo -> 6 Questions intro', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Hello Ilmo
      expect(find.text('Salom! Men Ilmoman'), findsOneWidget);
      final continueBtn = find.byKey(const ValueKey('onboarding_continue_btn'));
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 2: 6 short questions
      expect(
          find.text(
              '6 ta qisqa savolga javob bering — va birinchi darsni boshlaymiz!'),
          findsOneWidget);
    });

    testWidgets(
        'Step 3 (Subject): Continue button disabled until subject selected', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 3),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Subject screen
      expect(find.text("Qaysi fanni o'rganmoqchisiz?"), findsOneWidget);
      expect(find.text('Matematika'), findsOneWidget);

      final continueBtn = find.byKey(const ValueKey('onboarding_continue_btn'));

      // Tapping continue before selecting does not advance
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(find.text("Qaysi fanni o'rganmoqchisiz?"), findsOneWidget);

      // Tap 'Matematika'
      await tester.tap(find.text('Matematika'));
      await tester.pumpAndSettle();

      // Now tap Continue -> advances to Step 4
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Ilmo haqida qayerdan bildingiz?'), findsOneWidget);
    });

    testWidgets(
        'Step 4 (Source): Continue button disabled until source selected', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 4),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final continueBtn = find.byKey(const ValueKey('onboarding_continue_btn'));

      // Tapping before selecting does not advance
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(find.text('Ilmo haqida qayerdan bildingiz?'), findsOneWidget);

      // Select 'Telegram'
      await tester.tap(find.text('Telegram'));
      await tester.pumpAndSettle();

      // Advance
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 5: Level (Bilim darajasi)
      expect(find.text('Bu fandan qanchalik bilasiz?'), findsOneWidget);
    });

    testWidgets(
        'Step 5 (Level): Disabled until level selected, shows 5 levels, advances to Step 6', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 5),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final continueBtn = find.byKey(const ValueKey('onboarding_continue_btn'));

      // Check all 5 levels exist
      expect(find.text('Yangi boshlovchi'), findsOneWidget);
      expect(find.text('Asoslarini bilaman'), findsOneWidget);
      expect(find.text("O'rtacha"), findsOneWidget);
      expect(find.text('Yaxshi bilaman'), findsOneWidget);
      expect(find.text("A'lo", skipOffstage: false), findsOneWidget);

      // Before selecting, continue button does not advance
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(find.text('Bu fandan qanchalik bilasiz?'), findsOneWidget);

      // Tap "O'rtacha"
      await tester.tap(find.text("O'rtacha"));
      await tester.pumpAndSettle();

      // Advance to Step 6 (Ishonch oraliq ekrani)
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Ajoyib! Bilimni mustahkamlaymiz.'), findsOneWidget);
    });

    testWidgets(
        'Step 6 (Confidence) to Step 7 (Reason): Interstitial advances to multi-choice reasons', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 6),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Only Ilmo and speech bubble present
      expect(find.text('Ajoyib! Bilimni mustahkamlaymiz.'), findsOneWidget);

      final continueBtn = find.byKey(const ValueKey('onboarding_continue_btn'));
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Advances to Step 7: Reason (Sabab)
      expect(find.text("Nima uchun o'rganasiz?"), findsOneWidget);
    });

    testWidgets(
        'Step 7 (Reason): Multi-choice disabled when empty, enabled when >= 1', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 7),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final continueBtn = find.byKey(const ValueKey('onboarding_continue_btn'));

      // Initially empty -> tapping does not advance
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(find.text("Nima uchun o'rganasiz?"), findsOneWidget);

      // Select first reason
      await tester.tap(find.text('Imtihonlarga tayyorlanish'));
      await tester.pumpAndSettle();

      // Select second reason (multi-selection)
      await tester.tap(find.text('Baholarimni yaxshilash'));
      await tester.pumpAndSettle();

      // Advance to Step 8 (Sur'at oraliq ekrani)
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(
          find.text('Keling, qanday sur\'atda o\'qishni hal qilaylik!'),
          findsOneWidget);
    });

    testWidgets(
        'Step 8 (Pace) & Step 9 (Daily Goal): Sets goal with MAQSADGA KETDIK button', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 8),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final continueBtn = find.byKey(const ValueKey('onboarding_continue_btn'));

      // Step 8: Sur'at
      expect(
          find.text('Keling, qanday sur\'atda o\'qishni hal qilaylik!'),
          findsOneWidget);

      // Advance to Step 9
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 9: Kunlik maqsad
      expect(find.text('Kunlik maqsadingiz qanday?'), findsOneWidget);
      expect(find.text('5 daqiqa / kun'), findsOneWidget);
      expect(find.text('10 daqiqa / kun'), findsOneWidget);
      expect(find.text('15 daqiqa / kun'), findsOneWidget);
      expect(find.text('20 daqiqa / kun'), findsOneWidget);

      // Button says "MAQSADGA KETDIK"
      expect(find.text('MAQSADGA KETDIK'), findsOneWidget);

      // Before selection, tapping continue does not advance
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(find.text('Kunlik maqsadingiz qanday?'), findsOneWidget);

      // Select '10 daqiqa / kun' (Odatiy 20 XP)
      await tester.tap(find.text('10 daqiqa / kun'));
      await tester.pumpAndSettle();

      // Tap 'MAQSADGA KETDIK'
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Advances to Step 10: Roadmap / Natija ekrani
      expect(find.text('Mana nimaga erishasiz!'), findsOneWidget);
      expect(find.text('Mavzuni chuqur tushunish'), findsOneWidget);
      expect(
          find.text('Imtihonga ishonch bilan tayyorgarlik'), findsOneWidget);
      expect(find.text("Muntazam o'qish odati"), findsOneWidget);
    });

    testWidgets(
        'Step 10 (Roadmap) to Step 11 (Name & Age) to Step 12 (Loading): Completes flow', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();
      final mockAuth = _MockAuthRepo();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(mockAuth),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
          needsProfileSetupProvider.overrideWith((ref) => true),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 10),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final continueBtn = find.byKey(const ValueKey('onboarding_continue_btn'));

      // Step 10: Roadmap
      expect(find.text('Mana nimaga erishasiz!'), findsOneWidget);

      // Advance to Step 11: Name & Age
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text("O'zingiz haqingizda ayting"), findsOneWidget);

      // Ali Valiyev is prefilled from mock auth
      expect(find.text('Ali Valiyev'), findsOneWidget);

      // Age is initially empty -> tapping continue does not submit
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(mockAuth.savedUserId, isNull);

      // Enter valid age: 16
      await tester.enterText(
          find.widgetWithText(TextField, 'Yoshingiz (5–100)'), '16');
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify backend was called with correct data
      expect(mockAuth.savedUserId, 99);
      expect(mockAuth.savedName, 'Ali Valiyev');
      expect(mockAuth.savedAge, 16);

      // Verify flags in SharedPreferences
      expect(prefs.getBool('onboarding_completed_99'), isTrue);
      expect(container.read(needsProfileSetupProvider), isFalse);

      // Advances to Step 12 (Loading)
      expect(find.text('REJA TAYYORLANMOQDA...'), findsOneWidget);

      // Drain completion timer
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Back button navigates to previous step', (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();

      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_MockAuthController.new),
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          skillTreeRepositoryProvider.overrideWithValue(_MockSkillTreeRepo()),
          skillExtrasRepositoryProvider
              .overrideWithValue(_MockSkillExtrasRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(initialStep: 2),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.text(
              '6 ta qisqa savolga javob bering — va birinchi darsni boshlaymiz!'),
          findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Returns to Step 1
      expect(find.text('Salom! Men Ilmoman'), findsOneWidget);

      // Tap back button again
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Returns to Step 0 (Language)
      expect(find.text("Qaysi tilda o'rganishni xohlaysiz?"), findsOneWidget);
    });
  });
}
