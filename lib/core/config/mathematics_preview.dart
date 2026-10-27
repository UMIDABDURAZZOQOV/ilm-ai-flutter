/// Mathematics remains an explicit debug-only local/test entrypoint.
const mathematicsPreview = bool.fromEnvironment('MATHEMATICS_PREVIEW');

bool mathematicsPreviewAllowed(
  String baseUrl, {
  bool enabled = mathematicsPreview,
}) {
  if (!enabled) return false;
  final uri = Uri.tryParse(baseUrl);
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.userInfo.isNotEmpty) {
    return false;
  }
  final host = uri.host.toLowerCase();
  if ({'localhost', '127.0.0.1', '::1', '[::1]'}.contains(host)) return true;
  final octets = host.split('.').map(int.tryParse).toList();
  if (octets.length != 4 || octets.any((n) => n == null || n < 0 || n > 255)) {
    return false;
  }
  return octets[0] == 10 ||
      (octets[0] == 192 && octets[1] == 168) ||
      (octets[0] == 172 && octets[1]! >= 16 && octets[1]! <= 31);
}
