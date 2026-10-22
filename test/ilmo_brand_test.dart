import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/theme/ilmo_tokens.dart';
import 'package:ilm_ai_flutter/core/widgets/ilmo_speech_header.dart';
import 'package:ilm_ai_flutter/core/widgets/mascot_image.dart';

class _MissingImages extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => key.endsWith('.png')
      ? Future.error(StateError('missing image'))
      : rootBundle.load(key);
}

void main() {
  test(
    'approved originals retain hashes, square masters and transparency roles',
    () {
      final report =
          jsonDecode(
                File('docs/brand/ilmo_asset_audit.json').readAsStringSync(),
              )
              as Map;
      expect((report['assets'] as List).length, 8);
      for (final row in report['assets'] as List) {
        final bytes = File(row['file'] as String).readAsBytesSync();
        expect(
          sha256.convert(bytes).toString(),
          row['sha256'],
          reason: row['file'] as String,
        );
        final header = ByteData.sublistView(bytes);
        expect([header.getUint32(16), header.getUint32(20)], [1024, 1024]);
        if ((row['file'] as String).contains('ilmo_')) {
          expect(row['transparent_fraction'] as num, greaterThan(.6));
          expect(row['nontransparent_border_pixels'], 0);
        }
      }
    },
  );

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    double dpr = 3,
    bool reduced = false,
    double scale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          learningPalette(
            brightness == Brightness.dark ? darkColors : lightColors,
          ),
        ),
        home: MediaQuery(
          data: MediaQueryData(
            devicePixelRatio: dpr,
            disableAnimations: reduced,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final pose in MascotPose.values) {
    testWidgets(
      '${pose.name} uses the approved full image at physical pixel density',
      (tester) async {
        await mount(tester, MascotImage.compact(pose: pose, animate: false));
        final image = tester.widget<Image>(find.byType(Image));
        final provider = image.image as ResizeImage;
        expect(
          (provider.imageProvider as AssetImage).assetName,
          pose.assetPath,
        );
        expect(provider.width, 264);
        expect(provider.height, 264);
        expect(image.fit, BoxFit.contain);
        expect(image.excludeFromSemantics, true);
        expect(tester.getSize(find.byType(Image)), const Size.square(88));
      },
    );
  }

  testWidgets(
    'tight parent keeps Ilmo square; decode never exceeds the master',
    (tester) async {
      await mount(
        tester,
        const SizedBox(
          width: 64,
          height: 48,
          child: MascotImage.hero(pose: MascotPose.hello),
        ),
        dpr: 30,
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(tester.getSize(find.byType(Image)), const Size.square(48));
      expect((image.image as ResizeImage).width, 1024);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reduce Motion renders a static Ilmo without an animation wrapper',
    (tester) async {
      await mount(
        tester,
        const MascotImage.hero(pose: MascotPose.happy),
        reduced: true,
      );
      expect(find.byType(Animate), findsNothing);
      expect(tester.binding.hasScheduledFrame, false);
    },
  );

  testWidgets('meaningful image has one opt-in label', (tester) async {
    final semantics = tester.ensureSemantics();
    await mount(
      tester,
      const MascotImage.compact(
        pose: MascotPose.hello,
        semanticLabel: 'Ilmo salomlashmoqda',
      ),
    );
    expect(find.bySemanticsLabel('Ilmo salomlashmoqda'), findsOneWidget);
    expect(
      tester.widget<Image>(find.byType(Image)).excludeFromSemantics,
      false,
    );
    semantics.dispose();
  });

  testWidgets('missing artwork shows ILM AI instead of a replacement robot', (
    tester,
  ) async {
    await mount(
      tester,
      DefaultAssetBundle(
        bundle: _MissingImages(),
        child: const MascotImage.compact(pose: MascotPose.hello),
      ),
    );
    expect(find.text('ILM AI'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(tester.takeException(), isNull);
  });

  final messages = [
    'Shoshilmang, birga o‘ylab ko‘ramiz. Qulay sur’atda davom eting.',
    'Не спешите, давайте подумаем вместе. Продолжайте в удобном темпе.',
    'Take your time. Let’s think it through together and continue at your own pace.',
  ];
  for (final (index, message) in messages.indexed) {
    for (final size in [const Size(320, 568), const Size(640, 360)]) {
      testWidgets('speech $index fits $size at 200 percent without clipping', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(
          tester,
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: IlmoSpeechHeader(pose: MascotPose.thinking, text: message),
          ),
          scale: 2,
          reduced: true,
        );
        expect(find.text(message), findsOneWidget);
        final image = tester.getRect(find.byType(Image));
        final bubble = tester.getRect(find.text(message));
        expect(bubble.top, greaterThan(image.bottom));
        await tester.ensureVisible(find.text(message));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'wide speech keeps the image beside text and uses standard spacing',
    (tester) async {
      await mount(
        tester,
        SizedBox(
          width: 400,
          child: IlmoSpeechHeader(pose: MascotPose.hello, text: messages.first),
        ),
        reduced: true,
      );
      final image = tester.getRect(find.byType(Image));
      final text = tester.getRect(find.text(messages.first));
      expect(
        text.left - image.right,
        greaterThanOrEqualTo(IlmoSpacing.standard),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('light and dark brand gallery', (tester) async {
    tester.view.physicalSize = const Size(900, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await mount(
      tester,
      RepaintBoundary(
        key: key,
        child: SizedBox(
          width: 860,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final color in [Colors.white, BrandPalette.indigoDarkBg])
                ColoredBox(
                  color: color,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final pose in MascotPose.values)
                          Column(
                            children: [
                              MascotImage.hero(pose: pose, animate: false),
                              Text(
                                pose.name,
                                style: TextStyle(
                                  color: color == Colors.white
                                      ? BrandPalette.indigo
                                      : BrandPalette.creamWhite,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      reduced: true,
      dpr: 2,
    );
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('ILMO_QA_CAPTURE')) {
      await tester.runAsync(() async {
        await Future.wait([
          for (final widget in tester.widgetList<Image>(find.byType(Image)))
            precacheImage(widget.image, key.currentContext!),
        ]);
      });
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = File('.dart_tool/ilmo-audit/flutter-gallery.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
