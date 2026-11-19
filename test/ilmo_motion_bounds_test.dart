import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/widgets/ilmo_rig.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every Ilmo activity keeps visible pixels inside its allocated box',
    () async {
      final data = await rootBundle.load('assets/mascot/ilmo_rig_v1.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final atlas = (await codec.getNextFrame()).image;
      addTearDown(atlas.dispose);
      addTearDown(codec.dispose);
      const padding = 48;
      const extent = 240;
      const canvasExtent = extent + padding * 2;
      final violations = <String>[];
      for (final activity in IlmoActivity.values) {
        for (var frame = 0; frame <= 20; frame++) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder)
            ..translate(padding.toDouble(), padding.toDouble());
          // Intentionally no clipping: a clipped widget would hide this defect.
          IlmoRigPainter(
            atlas,
            activity,
            frame / 20,
          ).paint(canvas, const ui.Size.square(240));
          final picture = recorder.endRecording();
          final image = await picture.toImage(canvasExtent, canvasExtent);
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          var outside = 0;
          var visible = 0;
          var minX = canvasExtent, minY = canvasExtent, maxX = 0, maxY = 0;
          for (var y = 0; y < canvasExtent; y++) {
            for (var x = 0; x < canvasExtent; x++) {
              if (pixels.getUint8((y * canvasExtent + x) * 4 + 3) == 0) {
                continue;
              }
              visible++;
              if (x < minX) minX = x;
              if (y < minY) minY = y;
              if (x > maxX) maxX = x;
              if (y > maxY) maxY = y;
              if (x < padding ||
                  y < padding ||
                  x >= padding + extent ||
                  y >= padding + extent) {
                outside++;
              }
            }
          }
          image.dispose();
          picture.dispose();
          expect(
            visible,
            greaterThan(100),
            reason: '${activity.name} frame $frame must actually render',
          );
          if (outside > 0) {
            violations.add(
              '${activity.name} frame $frame: $outside outside pixels; '
              'bounds ${minX - padding},${minY - padding} to ${maxX - padding},${maxY - padding}',
            );
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );
}
