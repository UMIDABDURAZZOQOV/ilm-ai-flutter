import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android identity and deep link match the mobile OAuth protocol (static check)',
    () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(gradle, contains('applicationId = "com.ilmai.app"'));
      expect(
        manifest,
        contains('com.linusu.flutter_web_auth_2.CallbackActivity'),
      );
      expect(
        manifest,
        contains(
          'android:scheme="ilmai" android:host="auth" android:path="/callback"',
        ),
      );
      expect(manifest, contains('android:launchMode="singleTop"'));
      expect(manifest, isNot(contains('android:taskAffinity')));
      expect(
        gradle,
        contains('Release signing requires android/key.properties'),
      );
    },
  );

  test(
    'local HTTP allowance is confined to debug, not the release manifest',
    () {
      final debug = File(
        'android/app/src/debug/AndroidManifest.xml',
      ).readAsStringSync();
      final main = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(debug, contains('android:usesCleartextTraffic="true"'));
      expect(main, isNot(contains('android:usesCleartextTraffic="true"')));
    },
  );
}
