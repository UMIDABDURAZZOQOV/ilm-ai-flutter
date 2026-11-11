import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'support/platform_golden.dart';

Future<Uint8List> _probeImage({bool changeOnePixel = false}) async {
  final rgba = Uint8List(4 * 4 * 4);
  for (var i = 3; i < rgba.length; i += 4) {
    rgba[i] = 255;
  }
  if (changeOnePixel) rgba[0] = 255;
  final ready = Completer<ui.Image>();
  ui.decodeImageFromPixels(rgba, 4, 4, ui.PixelFormat.rgba8888, ready.complete);
  final image = await ready.future;
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'host uses separate exact references, without replacing Windows paths',
    () {
      expect(
        platformGolden('auth_login_light.png', operatingSystem: 'windows'),
        'goldens/auth_login_light.png',
      );
      expect(
        platformGolden('auth_login_light.png', operatingSystem: 'linux'),
        'goldens/linux/auth_login_light.png',
      );
      expect(
        platformGolden('auth_login_light.png'),
        platformGolden(
          'auth_login_light.png',
          operatingSystem: Platform.operatingSystem,
        ),
      );
    },
  );

  test(
    'unsupported host and invalid paths fail instead of skipping a comparison',
    () {
      expect(
        () => platformGolden('auth_login_light.png', operatingSystem: 'macos'),
        throwsUnsupportedError,
      );
      for (final invalid in [
        '../auth.png',
        '/auth.png',
        'linux/auth.png',
        'auth.jpg',
      ]) {
        expect(() => platformGolden(invalid), throwsArgumentError);
      }
    },
  );

  test('all sixteen reviewed host references exist independently', () {
    for (final stem in [
      'auth_login',
      'ilm_controls',
      'ilm_navigation',
      'lesson_completion',
      'polish_home',
      'polish_profile',
      'polish_league',
      'study_exit',
    ]) {
      for (final theme in ['light', 'dark']) {
        for (final host in ['windows', 'linux']) {
          final file = File(
            'test/${platformGolden('${stem}_$theme.png', operatingSystem: host)}',
          );
          expect(
            file.existsSync(),
            isTrue,
            reason: '${file.path} must not fall back',
          );
          expect(file.readAsBytesSync().take(8), [
            137,
            80,
            78,
            71,
            13,
            10,
            26,
            10,
          ]);
        }
      }
    }
  });

  test(
    'unchanged exact Flutter comparator rejects even one changed pixel',
    () async {
      expect(goldenFileComparator, isA<LocalFileComparator>());
      final baseline = await _probeImage();
      final same = await GoldenFileComparator.compareLists(baseline, baseline);
      final different = await GoldenFileComparator.compareLists(
        baseline,
        await _probeImage(changeOnePixel: true),
      );
      try {
        expect(same.passed, isTrue);
        expect(different.passed, isFalse);
        expect(different.diffPercent, 1 / 16);
      } finally {
        same.dispose();
        different.dispose();
      }
    },
  );
}
