import 'package:dio/dio.dart';
import '../config/mobile_release.dart';
import '../config/integrated_beta.dart';

/// Mobile publication never changes the website's /skills namespace.
class MobileApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (integratedBeta && options.path.startsWith('/skills/')) {
      options.path = '/beta${options.path}';
    } else if ((biologyOnly || reviewedMobileRelease) &&
        options.path.startsWith('/skills/')) {
      options.path = '/mobile${options.path}';
    }
    handler.next(options);
  }
}

String normalizeApiBaseUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw ArgumentError(
      'API_URL must be an HTTP(S) origin without credentials or query',
    );
  }
  return uri.toString().replaceFirst(RegExp(r'/+$'), '');
}
