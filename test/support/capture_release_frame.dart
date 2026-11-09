import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opt-in local QA artifact, never production/backend/provider traffic.
Future<void> captureReleaseFrame(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!const bool.fromEnvironment('UIUX_CAPTURE')) return;
  const stage = String.fromEnvironment(
    'UIUX_STAGE',
    defaultValue: 'final-audit',
  );
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
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.dart_tool/uiux-review/$stage/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
  expect(tester.takeException(), isNull, reason: name);
}
