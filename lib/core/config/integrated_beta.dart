import 'package:flutter/foundation.dart';

const integratedBetaRequested = bool.fromEnvironment('INTEGRATED_BETA');
const integratedBeta = kDebugMode && integratedBetaRequested;
const betaApiOrigin = String.fromEnvironment(
  'BETA_API_ORIGIN',
  defaultValue: 'http://127.0.0.1:8930',
);
const mobileAppScheme = integratedBeta ? 'ilmai-beta' : 'ilmai';
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
      !isBetaOrigin(Uri.parse(api))) {
    throw StateError(
      'Integrated beta requires a debug build and its separate local/staging API origin.',
    );
  }
}
