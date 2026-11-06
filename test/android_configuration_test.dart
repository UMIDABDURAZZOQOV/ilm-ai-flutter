import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'launch styles gate platform attributes by API without hiding lint errors',
    () {
      const resources = 'android/app/src/main/res';
      for (final base in ['values', 'values-night']) {
        final minimum = File('$resources/$base/styles.xml').readAsStringSync();
        expect(minimum, contains('name="LaunchThemeBase"'));
        expect(minimum, contains('parent="LaunchThemeBase"'));
        expect(minimum, isNot(contains('android:forceDarkAllowed')));
        expect(
          minimum,
          isNot(contains('android:windowLayoutInDisplayCutoutMode')),
        );
        final cutout = File(
          '$resources/$base-v28/styles.xml',
        ).readAsStringSync();
        expect(cutout, contains('parent="LaunchThemeBase"'));
        expect(cutout, contains('android:windowLayoutInDisplayCutoutMode'));
        expect(cutout, isNot(contains('android:forceDarkAllowed')));
        final dark = File('$resources/$base-v29/styles.xml').readAsStringSync();
        expect(dark, contains('parent="LaunchThemeBase"'));
        expect(dark, contains('android:forceDarkAllowed'));
      }
    },
  );

  test(
    'capture hardware is optional and authentication data is not transferred',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      for (final hardware in ['camera', 'camera.autofocus', 'microphone']) {
        expect(
          manifest,
          contains(
            'android:name="android.hardware.$hardware" android:required="false"',
          ),
        );
      }
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:fullBackupContent="false"'));
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      final rules = File(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      ).readAsStringSync();
      for (final channel in ['cloud-backup', 'device-transfer']) {
        final section = RegExp(
          '<$channel>([\\s\\S]*?)</$channel>',
        ).firstMatch(rules)!.group(1)!;
        for (final domain in [
          'root',
          'file',
          'database',
          'sharedpref',
          'external',
          'device_root',
          'device_file',
          'device_database',
          'device_sharedpref',
        ]) {
          expect(section, contains('<exclude domain="$domain" path="."/>'));
        }
      }
    },
  );

  test(
    'existing upload signing is reused only through an explicit private path',
    () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('System.getenv("ILM_ANDROID_KEY_PROPERTIES")'));
      expect(gradle, contains('File(keystorePropertiesFile.parentFile, "app/'));
      expect(gradle, contains('applicationId = "com.ilmai.app"'));
      expect(gradle, contains('signingConfigs.getByName("release")'));
      expect(gradle, contains('Integrated beta is an internal debug build.'));
    },
  );
  test(
    'Beta profile gate targets app artifacts without rejecting DebugArtProfile metadata',
    () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(
        gradle,
        contains(
          'it.project == project && it.name in betaProfileArtifactTasks',
        ),
      );
      for (final task in [
        'assembleProfile',
        'bundleProfile',
        'packageProfile',
        'compileFlutterBuildProfile',
        'installProfile',
      ]) {
        expect(gradle, contains('"$task"'));
      }
      expect(
        gradle,
        isNot(contains('allTasks.any { it.name.contains("Profile") }')),
      );
      expect(gradle, contains('!betaPerformanceEnabled'));
      expect(
        gradle,
        contains('Beta profile requires explicit BETA_PERFORMANCE=true'),
      );
      expect(
        gradle,
        contains(
          'Integrated beta is an internal debug build. Production release is a separate task.',
        ),
      );
    },
  );
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
        // Check the actual cross-file default; the preview build overrides the
        // placeholder. This remains a static check, not native manifest merging.
        manifest.replaceAll(
          r'${oauthRedirectScheme}',
          RegExp(
            r'manifestPlaceholders\["oauthRedirectScheme"\] = "([^"]+)"',
          ).firstMatch(gradle)!.group(1)!,
        ),
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
      expect(
        debug,
        contains(
          'android:networkSecurityConfig="@xml/qa_network_security_config"',
        ),
      );
      final network = File(
        'android/app/src/debug/res/xml/qa_network_security_config.xml',
      ).readAsStringSync();
      expect(
        network,
        contains('<base-config cleartextTrafficPermitted="false"'),
      );
      expect(
        network,
        contains('<domain-config cleartextTrafficPermitted="true">'),
      );
      final domains = RegExp(
        r'<domain[^>]*>([^<]+)</domain>',
      ).allMatches(network).map((m) => m.group(1)).toSet();
      expect(domains, {'127.0.0.1', 'localhost'});
      expect(debug, isNot(contains('android:usesCleartextTraffic="true"')));
      expect(main, isNot(contains('android:usesCleartextTraffic="true"')));
      expect(main, isNot(contains('qa_network_security_config')));
    },
  );
}
