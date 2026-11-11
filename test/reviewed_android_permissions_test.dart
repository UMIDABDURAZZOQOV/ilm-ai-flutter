import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final main = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final reviewed = File(
    'android/app/src/reviewedMobile/AndroidManifest.xml',
  ).readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  const capture = [
    'CAMERA',
    'RECORD_AUDIO',
    'READ_EXTERNAL_STORAGE',
    'WRITE_EXTERNAL_STORAGE',
  ];

  test('legacy main manifest retains its capture capabilities', () {
    for (final permission in capture) {
      expect(main, contains('android.permission.$permission'));
    }
    expect(main, contains(r'${oauthRedirectScheme}'));
    expect(main, contains('android:allowBackup="false"'));
  });

  test('reviewed overlay removes every unused capture permission', () {
    for (final permission in capture) {
      final tag = RegExp(
        '<uses-permission[^>]*android.permission.$permission"[^>]*/>',
      ).firstMatch(reviewed)?.group(0);
      expect(tag, isNotNull, reason: permission);
      expect(tag, contains('tools:node="remove"'), reason: permission);
    }
    expect(reviewed, contains('android:usesCleartextTraffic="false"'));
    expect(reviewed, isNot(contains('<activity')));
  });

  test(
    'permission overlay is scoped to reviewed subjects in all build modes',
    () {
      expect(
        gradle,
        contains('if (reviewedReleaseEnabled && subjectsOnlyEnabled)'),
      );
      expect(gradle, contains('listOf("debug", "profile", "release")'));
      expect(
        gradle,
        contains('manifest.srcFile("src/reviewedMobile/AndroidManifest.xml")'),
      );
      expect(
        gradle,
        contains('subjectsOnlyOverride?.toBooleanStrictOrNull() ?: true'),
      );
      expect(
        gradle,
        contains('.lastOrNull { it.startsWith("SUBJECTS_ONLY=") }'),
      );
    },
  );

  test(
    'legacy USB preview manifests retain their explicit local transport',
    () {
      for (final mode in ['debug', 'profile']) {
        final manifest = File(
          'android/app/src/$mode/AndroidManifest.xml',
        ).readAsStringSync();
        expect(manifest, contains('@xml/qa_network_security_config'));
      }
    },
  );
}
