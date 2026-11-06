import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/features/settings/presentation/privacy_policy_button.dart';

void main() {
  for (final language in ['uz', 'ru', 'en']) {
    testWidgets('public policy opens once, $language, large text', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: language});
      final prefs = await PrefsService.create();
      final done = Completer<bool>();
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            privacyPolicyLauncherProvider.overrideWithValue(() {
              calls++;
              return done.future;
            }),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: SizedBox(width: 280, child: PrivacyPolicyButton()),
            ),
          ),
        ),
      );
      final button = find.byKey(const ValueKey('privacy_policy'));
      final press = tester.widget<TextButton>(button).onPressed!;
      press();
      press();
      await tester.pump();
      expect(calls, 1);
      expect(tester.widget<TextButton>(button).onPressed, isNull);
      done.complete(true);
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(button).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      expect(privacyPolicyUri.scheme, 'https');
      expect(privacyPolicyUri.host, 'ilm-ai-edu.vercel.app');
      expect(privacyPolicyUri.hasQuery, false);
    });
  }
  for (final throws in [false, true]) {
    testWidgets('browser failure is visible and retryable, throws=$throws', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
      final prefs = await PrefsService.create();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            privacyPolicyLauncherProvider.overrideWithValue(() async {
              if (throws) throw StateError('no handler');
              return false;
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: PrivacyPolicyButton())),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('privacy_policy')));
      await tester.pumpAndSettle();
      expect(
        find.text('Sahifani ochib bo‘lmadi. Qayta urining.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('privacy_policy')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
