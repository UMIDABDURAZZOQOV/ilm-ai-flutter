import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/storage/prefs_service.dart';
import 'core/config/integrated_beta.dart';
import 'core/network/dio_client.dart' show apiBaseUrl;
import 'core/performance/beta_performance_probe.dart';

void main() async {
  if (integratedBetaRequested) requireBetaConfiguration(apiBaseUrl);
  if (reviewedMobileRelease || reviewedMobileStaging) {
    requireReviewedReleaseConfiguration(apiBaseUrl);
  }
  WidgetsFlutterBinding.ensureInitialized();
  BetaPerformanceProbe.start();

  // Edge-to-edge: draw behind the status & navigation bars and make them fully
  // transparent, so there are no grey strips at the top/bottom — the app's own
  // background flows all the way to the screen edges.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final prefs = await PrefsService.create();

  runApp(
    ProviderScope(
      overrides: [prefsServiceProvider.overrideWithValue(prefs)],
      child: const IlmAiApp(),
    ),
  );
}
