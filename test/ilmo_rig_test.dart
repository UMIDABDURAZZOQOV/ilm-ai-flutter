import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/widgets/animated_ilmo.dart';
import 'package:ilm_ai_flutter/core/widgets/ilmo_rig.dart';
import 'package:ilm_ai_flutter/core/widgets/mascot_image.dart';

void main() {
  test('product screens use articulated Ilmo, not the static fallback', () {
    final screens = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final pattern = RegExp(r'MascotImage(?:\.hero|\.compact)?\(');
    for (final file in screens) {
      expect(
        pattern.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: '${file.path} must use the shared Ilmo motion system',
      );
    }
  });
  testWidgets(
    'decoded atlas signals readiness once, not on every motion frame',
    (tester) async {
      var ready = 0;
      Widget scene(double phase) => MaterialApp(
        home: IlmoRig(
          activity: IlmoActivity.greeting,
          staticProgress: phase,
          size: 96,
          fallback: const SizedBox(),
          onReady: () => ready++,
        ),
      );
      await tester.pumpWidget(scene(0));
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/mascot/ilmo_rig_v1.png'),
          tester.element(find.byType(IlmoRig)),
        ),
      );
      await tester.pumpAndSettle();
      expect(ready, 1);
      await tester.pumpWidget(scene(.5));
      await tester.pumpAndSettle();
      expect(ready, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('reactions replay only for new events and pause in background', (
    tester,
  ) async {
    Widget scene(int event) => MaterialApp(
      home: AnimatedIlmo(
        pose: MascotPose.happy,
        activity: IlmoActivity.celebrating,
        reactionKey: event,
      ),
    );
    double progress() => tester.widget<IlmoRig>(find.byType(IlmoRig)).progress;
    await tester.pumpWidget(scene(1));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/mascot/ilmo_rig_v1.png'),
        tester.element(find.byType(IlmoRig)),
      ),
    );
    await tester.pumpAndSettle();
    expect(progress(), 1);
    await tester.pumpWidget(scene(1));
    expect(progress(), 1);
    await tester.pumpWidget(scene(2));
    final rig = tester.widget<IlmoRig>(find.byType(IlmoRig));
    final canvas = find.descendant(
      of: find.byType(IlmoRig),
      matching: find.byType(CustomPaint),
    );
    final painter = tester.widget<CustomPaint>(canvas).painter;
    await tester.pump(const Duration(milliseconds: 300));
    expect(progress(), inExclusiveRange(0, 1));
    expect(tester.widget<IlmoRig>(find.byType(IlmoRig)), same(rig));
    expect(tester.widget<CustomPaint>(canvas).painter, same(painter));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(progress(), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(progress(), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('articulated Ilmo states render and export a review sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1050, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: boundary,
            child: ColoredBox(
              color: const Color(0xFFF5F3FA),
              child: Wrap(
                children: [
                  for (final activity in IlmoActivity.values)
                    SizedBox(
                      width: 150,
                      child: Column(
                        children: [
                          Text(activity.name),
                          for (final phase in [0.0, .5, 1.0])
                            IlmoRig(
                              activity: activity,
                              staticProgress: phase,
                              size: 290,
                              fallback: const SizedBox(),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/mascot/ilmo_rig_v1.png'),
        tester.element(find.byType(Wrap)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(IlmoRig), findsNWidgets(21));
    expect(tester.takeException(), isNull);
    final output = Platform.environment['ILM_VISUAL_OUTPUT'];
    if (output != null) {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$output/ilmo-rig-review.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  testWidgets('mascot pauses when route is hidden and reduced motion settles', (
    tester,
  ) async {
    Widget scene(bool enabled, bool reduced) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: TickerMode(
          enabled: enabled,
          child: const AnimatedIlmo(
            pose: MascotPose.thinking,
            thinking: true,
            size: 96,
          ),
        ),
      ),
    );
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await tester.pumpWidget(scene(true, false));
    final rig = tester.widget<IlmoRig>(find.byType(IlmoRig));
    expect(rig.progress, 1);
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/mascot/ilmo_rig_v1.png'),
        tester.element(find.byType(IlmoRig)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(scene(false, false));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(scene(true, true));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
