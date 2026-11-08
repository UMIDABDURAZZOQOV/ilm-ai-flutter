import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/performance/beta_performance_probe.dart';

void main() {
  for (final profile in [false, true]) {
    for (final requested in [false, true]) {
      for (final beta in [false, true]) {
        for (final reviewed in [false, true]) {
          for (final staging in [false, true]) {
            test(
              'metrics gate $profile/$requested/$beta/$reviewed/$staging',
              () {
                expect(
                  performanceProbeAllowed(
                    profileMode: profile,
                    requested: requested,
                    localBeta: beta,
                    reviewedRelease: reviewed,
                    staging: staging,
                  ),
                  profile && requested && (beta || (reviewed && staging)),
                );
              },
            );
          }
        }
      }
    }
  }
}
