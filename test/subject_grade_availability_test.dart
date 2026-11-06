import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/config/integrated_beta.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_grade_card.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_home_screen.dart';
import 'package:ilm_ai_flutter/features/onboarding/data/onboarding_draft.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/duo_onboarding_screen.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'release_hardening_test.dart' show Adapter, reply;

SkillSubject subject(String slug, List<int> grades, {bool available = true}) =>
    SkillSubject(
      id: 1,
      slug: slug,
      nameUz: slug,
      nameRu: slug,
      nameEn: slug,
      available: available,
      grades: grades,
    );

class _Learner extends AuthController {
  @override
  Future<StoredTokens?> build() async => const StoredTokens(
    accessToken: 'widget-access',
    refreshToken: 'widget-refresh',
    userId: 42,
  );
}

void main() {
  test('availability uses ready catalogue grades for every grade 5–11', () {
    for (final grades in [
      <int>[5, 6, 7, 8, 9, 10, 11],
      [6, 7, 8, 9, 10, 11],
      [7, 8, 9, 10, 11],
      <int>[],
    ]) {
      final item = subject('catalogue-subject', grades);
      for (var grade = 5; grade <= 11; grade++) {
        expect(
          SubjectGradeAvailability(item, grade).canStudy,
          grades.contains(grade),
        );
      }
    }
  });

  test(
    'future, earlier, missing and unavailable metadata never invent grades',
    () {
      final item = subject('sparse', [8, 6]);
      expect(
        SubjectGradeAvailability(item, 5).label('uz'),
        '6-sinfda ochiladi',
      );
      expect(
        SubjectGradeAvailability(item, 7).label('uz'),
        '8-sinfda ochiladi',
      );
      expect(SubjectGradeAvailability(item, 8).label('uz'), '8-sinfda mavjud');
      expect(
        SubjectGradeAvailability(item, 11).label('uz'),
        'Avvalgi sinflarda mavjud: 6, 8',
      );
      expect(SubjectGradeAvailability(item, null).canStudy, isFalse);
      expect(
        SubjectGradeAvailability(item, null).label('en'),
        'Choose a grade',
      );
      expect(
        SubjectGradeAvailability(subject('missing', []), 5).label('uz'),
        'Hozircha mavjud emas',
      );
      expect(
        SubjectGradeAvailability(
          subject('disabled', [5], available: false),
          5,
        ).canStudy,
        isFalse,
      );
      expect(item.grades, [8, 6]); // No catalogue mutation from sorting.
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'locked card explains without selecting; text 200%, dark=$dark',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 740));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var selections = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(dark ? darkColors : lightColors),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SubjectGradeCard(
                subject: subject('kimyo', [7, 8]),
                grade: 5,
                language: 'uz',
                onSelected: () => selections++,
              ),
            ),
          ),
        );
        expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
        await tester.tap(find.text('kimyo'));
        await tester.pump();
        expect(selections, 0);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('7-sinfda ochiladi'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  }

  if (!integratedBeta) return;
  testWidgets(
    'restored onboarding cannot continue with a locked saved subject',
    (tester) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();
      await OnboardingDraftStore(
        prefs,
      ).save(42, {'step': 3, 'class': '5', 'subject': 'kimyo'});
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_Learner.new),
          subjectCatalogProvider.overrideWith(
            (ref) async => [
              subject('kimyo', [7, 8]),
            ],
          ),
        ],
      );
      await container.read(authControllerProvider.future);
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
      expect(
        tester
            .widget<Duo3DButton>(
              find.byKey(const ValueKey('onboarding_continue_btn')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<SubjectGradeCard>(
              find.byKey(const ValueKey('onboarding_kimyo')),
            )
            .canStudy,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    },
  );
  testWidgets(
    'main catalogue keeps every subject and updates locks for grades 5–11',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        PrefsKeys.language: 'uz',
        'class_42': '5',
        'subject_99': 'kimyo',
        'assessment_draft_42': 'keep',
      });
      final prefs = await PrefsService.create();
      final items = [
        subject('biologiya', [5, 6, 7, 8, 9, 10, 11]),
        subject('fizika', [6, 7, 8, 9, 10, 11]),
        subject('kimyo', [7, 8, 9, 10, 11]),
        subject('jahon_tarixi', [6, 7, 8, 9, 10, 11]),
        subject('ozbekiston_tarixi', [7, 8, 9, 10, 11]),
        subject('matematika', [], available: false),
      ];
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..httpClientAdapter = Adapter((request) {
          requests.add(request);
          return reply(200, {'ok': true});
        });
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          dioProvider.overrideWithValue(dio),
          authControllerProvider.overrideWith(_Learner.new),
          subjectCatalogProvider.overrideWith((ref) async => items),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(dio.close);
      await container.read(authControllerProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const SubjectHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('kimyo'));
      await tester.pumpAndSettle();
      expect(prefs.getString('subject_42'), isNull);
      expect(requests, isEmpty);
      for (var grade = 5; grade <= 11; grade++) {
        if (grade != 5) {
          await tester.tap(find.byType(DropdownButtonFormField<int>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('$grade-sinf').last);
          await tester.pumpAndSettle();
        }
        for (final item in items) {
          final card = find.byKey(ValueKey('catalog_${item.slug}'));
          expect(card, findsOneWidget);
          expect(
            tester.widget<SubjectGradeCard>(card).canStudy,
            item.available && item.grades.contains(grade),
          );
        }
      }
      expect(prefs.getString('subject_99'), 'kimyo');
      expect(prefs.getString('assessment_draft_42'), 'keep');
      expect(prefs.getString('subject_42'), isNull);
      expect(requests.every((r) => r.path.endsWith('/preferences')), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
