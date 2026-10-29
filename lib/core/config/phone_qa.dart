import 'package:flutter/foundation.dart';

const phoneQaRequested = bool.fromEnvironment('PHONE_QA');
const phoneQaEnabled = kDebugMode && phoneQaRequested;

bool isPhoneQaUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      uri.scheme == 'http' &&
      uri.host == '127.0.0.1' &&
      uri.port == 8925 &&
      uri.userInfo.isEmpty &&
      uri.path.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment;
}

bool isPhoneQaRequest(Uri uri) =>
    uri.scheme == 'http' &&
    uri.host == '127.0.0.1' &&
    uri.port == 8925 &&
    uri.userInfo.isEmpty;

void requirePhoneQaConfiguration(String url) {
  if (!phoneQaEnabled ||
      !isPhoneQaUrl(url) ||
      !const bool.fromEnvironment('PHYSICS_PREVIEW') ||
      !const bool.fromEnvironment('CHEMISTRY_PREVIEW') ||
      !const bool.fromEnvironment('WORLD_HISTORY_PREVIEW') ||
      !const bool.fromEnvironment('UZBEKISTAN_HISTORY_PREVIEW')) {
    throw StateError(
      'Phone QA requires debug, all preview gates and USB loopback API.',
    );
  }
}
