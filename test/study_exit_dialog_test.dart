import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/study_exit_dialog.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/study_exit_guard.dart';

const _keep = {'uz': 'Davom etish', 'ru': 'Продолжить', 'en': 'Keep learning'};
const _savedLeave = {
  'uz': 'Saqlab chiqish',
  'ru': 'Сохранить и выйти',
  'en': 'Save & leave',
};

Future<void> _open(
  WidgetTester tester, {
  String lang = 'ru',
  bool dark = false,
  double scale = 1,
  bool reduced = false,
  Future<bool> Function()? save,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(dark ? darkColors : lightColors),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
        ),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => StudyExitGuard(
                  active: true,
                  saving: false,
                  language: lang,
                  saveBeforeExit: save,
                  child: const Scaffold(body: Center(child: Text('Lesson'))),
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
  await tester.binding.handlePopRoute();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final config = File('.dart_tool/package_config.json');
    final packages =
        (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
    final flutter = packages.cast<Map>().singleWhere(
      (p) => p['name'] == 'flutter',
    );
    final sdk = Directory.fromUri(
      config.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    final loader = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '${sdk.path}/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
            ).readAsBytesSync(),
          ),
        ),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '${sdk.path}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
  });

  for (final lang in _keep.keys) {
    for (final dark in [false, true]) {
      for (final status in StudyExitStatus.values) {
        testWidgets('exit dialog $lang/$dark/$status at 320dp and 200%', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final handle = tester.ensureSemantics();
          await _open(
            tester,
            lang: lang,
            dark: dark,
            scale: 2,
            save: status == StudyExitStatus.unsaved
                ? null
                : () async => status == StudyExitStatus.saved,
          );
          await tester.pumpAndSettle();
          expect(
            tester.widget<StudyExitDialog>(find.byType(StudyExitDialog)).status,
            status,
          );
          expect(find.semantics.byLabel('Lesson'), findsNothing);
          await tester.ensureVisible(find.byType(FilledButton));
          await tester.pumpAndSettle();
          expect(
            tester.getSize(find.byType(FilledButton)).height,
            greaterThanOrEqualTo(52),
          );
          expect(
            tester.getSize(find.byType(OutlinedButton)).height,
            greaterThanOrEqualTo(48),
          );
          expect(
            tester.getSize(find.byType(FilledButton)).width,
            tester.getSize(find.byType(OutlinedButton)).width,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(_keep[lang]!));
          await tester.pumpAndSettle();
          expect(find.text('Lesson'), findsOneWidget);
          expect(find.byType(StudyExitDialog), findsNothing);
          handle.dispose();
        });
      }
      testWidgets('exit $lang/$dark landscape can reach both actions', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(568, 320);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _open(
          tester,
          lang: lang,
          dark: dark,
          scale: 2,
          save: () async => true,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(_keep[lang]!));
        await tester.pumpAndSettle();
        expect(find.text(_keep[lang]!).hitTestable(), findsOneWidget);
        await tester.ensureVisible(find.text(_savedLeave[lang]!));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_savedLeave[lang]!));
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
        expect(find.text('Lesson'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'waits for one final save, then dismissing preserves the lesson',
    (tester) async {
      final result = Completer<bool>();
      var saves = 0;
      await _open(
        tester,
        lang: 'en',
        save: () {
          saves++;
          return result.future;
        },
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(StudyExitDialog), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(saves, 1);
      result.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Save & leave'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Lesson'), findsOneWidget);
      expect(find.byType(StudyExitDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('save exception never claims success and leave still confirms', (
    tester,
  ) async {
    await _open(
      tester,
      lang: 'en',
      save: () async => throw StateError('disk full'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be saved'), findsOneWidget);
    expect(find.text('Save & leave'), findsNothing);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduce Motion uses no dialog transition', (tester) async {
    await _open(tester, reduced: true, save: () async => true);
    await tester.pump();
    final context = tester.element(find.byType(StudyExitDialog));
    expect(ModalRoute.of(context)!.animation!.value, 1);
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets('exit dialog golden ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _open(tester, dark: dark, save: () async => true);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(StudyExitDialog),
        matchesGoldenFile('goldens/study_exit_${dark ? 'dark' : 'light'}.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
