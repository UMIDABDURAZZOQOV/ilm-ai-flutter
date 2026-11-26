import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/widgets/animated_ilmo.dart';
import 'package:ilm_ai_flutter/core/widgets/ilmo_rig.dart' show IlmoRig;
import 'package:ilm_ai_flutter/core/widgets/mascot_image.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/study_help/subject_tutor.dart';

class TutorFake extends SubjectTutorRepository {
  TutorFake() : super(Dio());
  final calls = <String>[];
  final result = Completer<Map<String, dynamic>>();
  CancelToken? token;
  @override
  Future<Map<String, dynamic>> ask({
    required String subject,
    required int grade,
    required String conversation,
    required String request,
    required String message,
    required CancelToken cancel,
    String? lessonKey,
    Map<String, dynamic> questionContext = const {},
  }) {
    calls.add('$subject:$grade:$message');
    token = cancel;
    return result.future;
  }
}

void main() {
  for (final reduceMotion in [true, false]) {
    testWidgets(
      'subject tutor replaces the path without slide, reduced=$reduceMotion',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [currentUserIdProvider.overrideWithValue(42)],
            child: MaterialApp(
              theme: buildAppTheme(lightColors),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () =>
                        openSubjectTutor(context, subject: 'kimyo', grade: 7),
                    child: const Text('Open tutor'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open tutor'));
        await tester.pump();
        final context = tester.element(find.byType(SubjectTutorScreen));
        final route = ModalRoute.of(context)!;
        expect(route.transitionDuration, Duration.zero);
        expect(route.reverseTransitionDuration, Duration.zero);
        expect(find.text('Open tutor'), findsNothing);
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/mascot/ilmo_rig_v1.png'),
            tester.element(find.byType(IlmoRig)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 100));
        final rig = tester.widget<IlmoRig>(find.byType(IlmoRig));
        expect(rig.progress, reduceMotion ? 1 : inExclusiveRange(0, 1));
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Open tutor'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final locale in [
    ('ru', 'Отправить', 'Повторить'),
    ('en', 'Send', 'Retry'),
  ]) {
    testWidgets('chat ${locale.$1} retains retry and draft at large text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(640, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fake = TutorFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(42),
            subjectTutorRepositoryProvider.overrideWithValue(fake),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SubjectTutorScreen(
                subject: 'kimyo',
                grade: 7,
                language: locale.$1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('tutor_input')),
        'Modda nima?',
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedIlmo>(find.byType(AnimatedIlmo)).activity,
        IlmoActivity.listening,
      );
      await tester.tap(find.byTooltip(locale.$2));
      await tester.pump();
      fake.result.complete({
        'status': 'unavailable',
        'message': 'Synthetic unavailable',
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tutor_error')), findsOneWidget);
      final retry = find.text(locale.$3);
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(fake.calls, ['kimyo:7:Modda nima?', 'kimyo:7:Modda nima?']);
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.text('Modda nima?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final dark in [false, true]) {
    testWidgets(
      'send arrow remains contrasting before and after sending dark=$dark',
      (tester) async {
        final fake = TutorFake();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWithValue(42),
              subjectTutorRepositoryProvider.overrideWithValue(fake),
            ],
            child: MaterialApp(
              theme: buildAppTheme(dark ? darkColors : lightColors),
              home: const SubjectTutorScreen(subject: 'kimyo', grade: 7),
            ),
          ),
        );
        await tester.pumpAndSettle();
        void checkArrow({required bool enabled}) {
          final button = tester.widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Yuborish',
            ),
          );
          expect(button.onPressed != null, enabled);
          final states = button.onPressed == null
              ? {WidgetState.disabled}
              : <WidgetState>{};
          final foreground = button.style!.foregroundColor!.resolve(states)!;
          final background = button.style!.backgroundColor!.resolve(states)!;
          final light = foreground.computeLuminance();
          final dark = background.computeLuminance();
          final contrast = light > dark
              ? (light + .05) / (dark + .05)
              : (dark + .05) / (light + .05);
          expect(contrast, greaterThanOrEqualTo(3));
          final icon = find.descendant(
            of: find.byTooltip('Yuborish'),
            matching: find.byIcon(Icons.arrow_upward_rounded),
          );
          expect(icon, findsOneWidget);
          expect(IconTheme.of(tester.element(icon)).color, foreground);
        }

        checkArrow(enabled: false);
        await tester.enterText(find.byKey(const ValueKey('tutor_input')), '  ');
        await tester.pump();
        checkArrow(enabled: false);
        await tester.enterText(
          find.byKey(const ValueKey('tutor_input')),
          'Modda nima?',
        );
        await tester.pump();
        checkArrow(enabled: true);
        await tester.tap(find.byTooltip('Yuborish'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        checkArrow(enabled: false);
        fake.result.complete({
          'status': 'answered',
          'paragraphs': [
            {'text': 'Test izohi.'},
          ],
        });
        await tester.pumpAndSettle();
        checkArrow(enabled: false);
      },
    );
  }
  for (final topic in [null, 'Paskal qonuni']) {
    testWidgets('starters name the current lesson, topic=$topic', (
      tester,
    ) async {
      final fake = TutorFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(42),
            subjectTutorRepositoryProvider.overrideWithValue(fake),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: SubjectTutorScreen(
              subject: 'fizika',
              grade: 7,
              latestTopic: topic,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final latest = find.byKey(const ValueKey('tutor_starter_2'));
      if (topic == null) {
        // Without a known lesson a chip would only make Ilmo ask "which?".
        expect(find.byKey(const ValueKey('tutor_starter_0')), findsNothing);
        expect(latest, findsNothing);
        return;
      }
      expect(find.text('Mavzu: «Paskal qonuni»'), findsOneWidget);
      expect(find.text('Soddaroq tushuntir'), findsOneWidget);
      await tester.tap(latest);
      await tester.pump();
      expect(fake.calls, [
        'fizika:7:«Paskal qonuni» mavzusini soddaroq tushuntir',
      ]);
      fake.result.complete({
        'status': 'answered',
        'paragraphs': [
          {'text': 'Izoh.'},
        ],
      });
      await tester.pumpAndSettle();
    });
  }
  testWidgets('a slow answer is announced after 15 s, then replaced', (
    tester,
  ) async {
    final fake = TutorFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(42),
          subjectTutorRepositoryProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: const SubjectTutorScreen(subject: 'fizika', grade: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('tutor_input')),
      'Bosim nima?',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Yuborish'));
    await tester.pump();
    expect(find.text('Ilmo savolingiz ustida o‘ylayapti…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 16));
    expect(find.textContaining('odatdagidan uzoqroq'), findsOneWidget);
    fake.result.complete({
      'status': 'answered',
      'paragraphs': [
        {'text': 'Bosim izohi.'},
      ],
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('odatdagidan uzoqroq'), findsNothing);
    expect(find.text('Bosim izohi.'), findsOneWidget);
  });
  testWidgets(
    'real typed question is sent once and cancellation owns lifecycle',
    (tester) async {
      final fake = TutorFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(42),
            subjectTutorRepositoryProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(
            home: SubjectTutorScreen(subject: 'kimyo', grade: 7),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('tutor_input')),
        'Modda nima?',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Yuborish'));
      await tester.pump();
      await tester.tap(find.byTooltip('Yuborish'));
      expect(fake.calls, ['kimyo:7:Modda nima?']);
      fake.result.complete({
        'status': 'answered',
        'paragraphs': [
          {'text': 'Yangi izoh.'},
        ],
      });
      await tester.pumpAndSettle();
      expect(find.text('Yangi izoh.'), findsOneWidget);
      expect(find.text('Modda nima?'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(fake.token!.isCancelled, isTrue);
    },
  );

  testWidgets('chat fits short landscape with large text and keyboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserIdProvider.overrideWithValue(42)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 120),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const SubjectTutorScreen(subject: 'kimyo', grade: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Yuborish'), findsOneWidget);
  });

  testWidgets('Ilmo reactions settle and reduced motion stops thinking loop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AnimatedIlmo(pose: MascotPose.happy)),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AnimatedIlmo(pose: MascotPose.thinking, thinking: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
