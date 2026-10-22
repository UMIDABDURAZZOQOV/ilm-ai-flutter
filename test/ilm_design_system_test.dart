import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/theme/ilm_design.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/core/widgets/ilm_state_view.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/study_exit_guard.dart';

double contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

void main() {
  test('semantic reading and action pairs exceed 4.5:1 in both themes', () {
    for (final base in [lightColors, darkColors]) {
      final c = learningPalette(base);
      final theme = buildAppTheme(base);
      final design = theme.extension<IlmDesign>()!;
      for (final surface in [c.background, c.surface, c.card]) {
        for (final foreground in [
          c.text,
          c.textSecondary,
          c.textMuted,
          c.primary,
        ]) {
          expect(contrast(foreground, surface), greaterThanOrEqualTo(4.5));
        }
      }
      for (final pair in [
        (c.success, c.successLight),
        (c.error, c.errorLight),
        (c.warning, c.warningLight),
        (design.onAction, design.action),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.bottomSheetTheme.backgroundColor, c.surface);
      expect(theme.colorScheme.onSurface, c.text);
    }
  });

  for (final lang in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'loading $lang/$dark fits 320dp at 200%, without motion or invented progress',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(dark ? darkColors : lightColors),
              home: MediaQuery(
                data: const MediaQueryData(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(2),
                ),
                child: Scaffold(body: IlmLoadingView(language: lang)),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(LinearProgressIndicator), findsNothing);
          expect(find.textContaining('XP'), findsNothing);
          semantics.dispose();
        },
      );
    }
    for (final saved in [true, false]) {
      testWidgets('exit $lang reports the actual local save outcome: $saved', (
        tester,
      ) async {
        var saves = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(lightColors),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => StudyExitGuard(
                        active: true,
                        saving: false,
                        language: lang,
                        saveBeforeExit: () async {
                          saves++;
                          return saved;
                        },
                        child: Scaffold(
                          body: TextButton(
                            onPressed: () => Navigator.maybePop(context),
                            child: const Text('Close'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(saves, 1);
        final expected = saved
            ? {
                'uz': 'shu qurilmada saqlandi',
                'ru': 'сохранена на этом устройстве',
                'en': 'saved on this device',
              }[lang]!
            : {
                'uz': 'saqlab bo‘lmadi',
                'ru': 'Не удалось сохранить',
                'en': 'could not be saved',
              }[lang]!;
        expect(find.textContaining(expected), findsOneWidget);
        expect(find.textContaining('will not be saved'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final dark in [false, true]) {
    testWidgets('ILM AI control golden ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(dark ? darkColors : lightColors),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ILM AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const DuoProgressBar(value: .4),
                    const SizedBox(height: 24),
                    const DuoChoiceCard(
                      text: 'Choice',
                      selected: false,
                      answered: false,
                      isCorrectOption: false,
                    ),
                    const DuoChoiceCard(
                      text: 'Selected',
                      selected: true,
                      answered: false,
                      isCorrectOption: false,
                    ),
                    Duo3DButton(
                      onPressed: () {},
                      child: const Text('Continue'),
                    ),
                    const SizedBox(height: 16),
                    const Duo3DButton(child: Text('Disabled')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(key),
        matchesGoldenFile(
          'goldens/ilm_controls_${dark ? 'dark' : 'light'}.png',
        ),
      );
    });
  }
}
