import 'package:flutter/foundation.dart';

const integratedBetaRequested = bool.fromEnvironment('INTEGRATED_BETA');
const betaPerformanceRequested = bool.fromEnvironment('BETA_PERFORMANCE');
const integratedBeta =
    integratedBetaRequested &&
    (kDebugMode || (kProfileMode && betaPerformanceRequested));
const betaApiOrigin = String.fromEnvironment(
  'BETA_API_ORIGIN',
  defaultValue: 'http://127.0.0.1:8930',
);
const mobileAppScheme = integratedBeta
    ? (kProfileMode ? 'ilmai-beta-perf' : 'ilmai-beta')
    : 'ilmai';
const betaSubjectSlugs = {
  'biologiya',
  'fizika',
  'kimyo',
  'ozbekiston_tarixi',
  'jahon_tarixi',
};

bool isBetaOrigin(Uri uri) {
  final origin = Uri.tryParse(betaApiOrigin);
  if (origin == null ||
      uri.userInfo.isNotEmpty ||
      origin.userInfo.isNotEmpty ||
      origin.path.isNotEmpty ||
      origin.hasQuery ||
      origin.hasFragment ||
      origin.host == 'ilm-ai-backend-256x.onrender.com') {
    return false;
  }
  final safeTransport =
      origin.scheme == 'https' ||
      (origin.scheme == 'http' &&
          origin.host == '127.0.0.1' &&
          origin.port == 8930);
  return safeTransport &&
      uri.scheme == origin.scheme &&
      uri.host == origin.host &&
      uri.port == origin.port;
}

void requireBetaConfiguration(String api) {
  if (!integratedBeta ||
      api != betaApiOrigin ||
      !isBetaOrigin(Uri.parse(api)) ||
      (kProfileMode && api != 'http://127.0.0.1:8930')) {
    throw StateError(
      'Integrated beta requires debug or explicitly opted-in local profile mode; release is forbidden.',
    );
  }
}
