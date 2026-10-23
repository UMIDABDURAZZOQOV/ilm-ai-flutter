/// Explicit debug/loopback QA only; the released Biology catalogue is unchanged.
const chemistryPreview = bool.fromEnvironment('CHEMISTRY_PREVIEW');

bool chemistryPreviewAllowed(
  String baseUrl, {
  bool enabled = chemistryPreview,
}) {
  if (!enabled) return false;
  final uri = Uri.tryParse(baseUrl);
  return uri != null &&
      {'http', 'https'}.contains(uri.scheme) &&
      uri.userInfo.isEmpty &&
      uri.query.isEmpty &&
      uri.fragment.isEmpty &&
      {
        'localhost',
        '127.0.0.1',
        '::1',
        '[::1]',
      }.contains(uri.host.toLowerCase());
}
