import 'translations.dart';

/// Ported from ilm-ai-mobile/src/utils/i18n.ts's `t()` helper. Fallback
/// semantics must match exactly: missing key -> return the raw key; key
/// exists but locale missing -> fall back to 'en' -> then the raw key.
/// Intentionally not using Flutter's default intl/ARB machinery, which
/// doesn't support this exact fallback chain.
String t(String key, String locale) {
  final entry = kTranslations[key];
  if (entry == null) return key;
  return entry[locale] ?? entry['en'] ?? key;
}
