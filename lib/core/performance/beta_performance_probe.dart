import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../config/integrated_beta.dart';

/// Bounded, read-only metrics on the authenticated localhost profile VM service.
/// No content, credentials, user data, heap snapshots or UI controls are exposed.
class BetaPerformanceProbe {
  static void start() {
    if (!performanceProbeAllowed(
      profileMode: kProfileMode,
      requested: betaPerformanceRequested,
      localBeta: integratedBeta,
      reviewedRelease: reviewedMobileRelease,
      staging: reviewedMobileStaging,
    )) {
      return;
    }
    final clock = Stopwatch()..start();
    final frames = <Map<String, int>>[];
    int? firstFrameMs;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      firstFrameMs ??= clock.elapsedMilliseconds;
      for (final frame in timings) {
        if (frames.length == 10000) frames.removeRange(0, 1000);
        frames.add({
          'build_us': frame.buildDuration.inMicroseconds,
          'raster_us': frame.rasterDuration.inMicroseconds,
          'total_us': frame.totalSpan.inMicroseconds,
        });
      }
    });
    developer.registerExtension('ext.ilmai.performance', (
      method,
      params,
    ) async {
      final snapshot = List.of(frames);
      if (params['reset'] == 'true') frames.clear();
      return developer.ServiceExtensionResponse.result(
        jsonEncode({
          'mode': 'local_profile',
          'first_frame_callback_ms': firstFrameMs,
          'elapsed_ms': clock.elapsedMilliseconds,
          'frames': snapshot,
        }),
      );
    });
  }
}

/// Metrics remain opt-in and profile-only; ordinary production has no extension.
bool performanceProbeAllowed({
  required bool profileMode,
  required bool requested,
  required bool localBeta,
  required bool reviewedRelease,
  required bool staging,
}) => profileMode && requested && (localBeta || (reviewedRelease && staging));
