import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(int, int, Uint8List)> decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = (image.width, image.height, data!.buffer.asUint8List());
  image.dispose();
  codec.dispose();
  return result;
}

void expectOpaqueIndigoEdges(
  int width,
  int height,
  Uint8List pixels, {
  bool allEdges = true,
}) {
  var translucent = 0;
  var incorrectEdge = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final offset = (y * width + x) * 4;
      if (pixels[offset + 3] != 255) translucent++;
      final horizontal = x == 0 || x == width - 1;
      final vertical = y == 0 || y == height - 1;
      // At tiny native sizes the Lanczos filter reaches the outermost edge
      // near the ears/antenna. The four background corners remain exact.
      if (allEdges ? horizontal || vertical : horizontal && vertical) {
        if (pixels[offset] != 42 ||
            pixels[offset + 1] != 31 ||
            pixels[offset + 2] != 107) {
          incorrectEdge++;
        }
      }
    }
  }
  expect(translucent, 0);
  expect(incorrectEdge, 0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the supplied Ilmo PNG is byte-for-byte unchanged', () {
    final bytes = File('assets/mascot/ilmo_app_icon_new.png').readAsBytesSync();
    expect(
      sha256.convert(bytes).toString(),
      '13a5e77618906ab89d8f0c48d68dd6b46214f058b2d535ebc778479f76ea67ea',
    );
    final header = ByteData.sublistView(bytes);
    expect([header.getUint32(16), header.getUint32(20)], [1254, 1254]);
  });

  test(
    'derived files match the reviewed manifest; originals remain backups',
    () {
      final manifest =
          jsonDecode(
                File(
                  'docs/brand/launcher_icon_manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['background'], '#2A1F6B');
      expect(manifest['adaptive_inset_percent'], 0);
      for (final row in manifest['outputs'] as List) {
        final bytes = File(row['file'] as String).readAsBytesSync();
        expect(sha256.convert(bytes).toString(), row['sha256']);
        expect(bytes.length, row['bytes']);
      }
      for (final entry in (manifest['original_backups'] as Map).entries) {
        expect(
          sha256
              .convert(File('assets/mascot/${entry.key}').readAsBytesSync())
              .toString(),
          entry.value,
        );
      }
    },
  );

  for (final (path, side) in [
    ('assets/mascot/launcher_icon.png', 1024),
    ('artwork/icons/ilm_ai_play_store_512.png', 512),
  ]) {
    test(
      '$path is square, opaque and has the exact indigo background',
      () async {
        final (width, height, pixels) = await decode(path);
        expect([width, height], [side, side]);
        expectOpaqueIndigoEdges(width, height, pixels);
        if (side == 512) {
          final bytes = File(path).readAsBytesSync();
          expect(bytes.length, lessThanOrEqualTo(1024 * 1024));
          expect(bytes[24], 8); // 8 bits per channel.
          expect(bytes[25], 6); // PNG color type RGBA: 32 bits per pixel.
          expect(latin1.decode(bytes).contains('sRGB'), true);
        }
      },
    );
  }

  for (final (directory, side) in [
    ('assets/mascot', 1024),
    ('android/app/src/main/res/drawable-mdpi', 108),
    ('android/app/src/main/res/drawable-hdpi', 162),
    ('android/app/src/main/res/drawable-xhdpi', 216),
    ('android/app/src/main/res/drawable-xxhdpi', 324),
    ('android/app/src/main/res/drawable-xxxhdpi', 432),
  ]) {
    final name = side == 1024
        ? 'launcher_icon_foreground'
        : 'ic_launcher_foreground';
    test(
      '$directory keeps every nonzero alpha pixel in the 66dp safe circle',
      () async {
        final (width, height, pixels) = await decode('$directory/$name.png');
        expect([width, height], [side, side]);
        var visible = 0;
        var maxRadius = 0.0;
        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            if (pixels[(y * width + x) * 4 + 3] == 0) continue;
            visible++;
            final dx = x + .5 - side / 2;
            final dy = y + .5 - side / 2;
            maxRadius = math.max(maxRadius, math.sqrt(dx * dx + dy * dy));
          }
        }
        expect(visible, greaterThan(side * side * .10));
        expect(maxRadius, lessThanOrEqualTo(side * 33 / 108));
      },
    );
  }

  test('adaptive XML uses indigo and no second foreground inset', () {
    final xml = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    final colors = File(
      'android/app/src/main/res/values/colors.xml',
    ).readAsStringSync();
    expect(xml, contains('@color/ic_launcher_background'));
    expect(xml, contains('@drawable/ic_launcher_foreground'));
    expect(xml, contains('android:inset="0%"'));
    expect(
      colors,
      contains('<color name="ic_launcher_background">#2A1F6B</color>'),
    );
    final yaml = File('pubspec.yaml').readAsStringSync();
    expect(yaml, contains('image_path: "assets/mascot/launcher_icon.png"'));
    expect(yaml, contains('adaptive_icon_foreground_inset: 0'));
  });

  test(
    'generated Android legacy and iOS launcher resources use the new background',
    () async {
      for (final (density, side) in [
        ('mdpi', 48),
        ('hdpi', 72),
        ('xhdpi', 96),
        ('xxhdpi', 144),
        ('xxxhdpi', 192),
      ]) {
        final (width, height, pixels) = await decode(
          'android/app/src/main/res/mipmap-$density/ic_launcher.png',
        );
        expect([width, height], [side, side]);
        expectOpaqueIndigoEdges(width, height, pixels, allEdges: false);
      }
      const directory = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      final contents =
          jsonDecode(File('$directory/Contents.json').readAsStringSync())
              as Map;
      for (final icon in contents['images'] as List) {
        final file = icon['filename'];
        if (file == null) continue;
        final expected =
            double.parse((icon['size'] as String).split('x').first) *
            double.parse((icon['scale'] as String).replaceAll('x', ''));
        final (width, height, pixels) = await decode('$directory/$file');
        expect([width, height], [expected.toInt(), expected.toInt()]);
        expectOpaqueIndigoEdges(width, height, pixels, allEdges: false);
      }
    },
  );
}
