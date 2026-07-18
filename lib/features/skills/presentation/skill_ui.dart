import 'package:flutter/material.dart';

/// Trilingual inline string helper (uz/ru/en) — avoids adding dozens of i18n
/// keys for the skill-tree extras, matching the models' own nameFor() approach.
String str3(String lang, String uz, String ru, String en) {
  switch (lang) {
    case 'ru':
      return ru;
    case 'en':
      return en;
    default:
      return uz;
  }
}

Color skillColor(String? hex, [Color fallback = const Color(0xFF58CC02)]) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  try {
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return fallback;
  }
}

/// Shared subject-slug → icon map, used across the hub, pickers and cards.
const subjectIcons = <String, IconData>{
  'ona_tili': Icons.menu_book_rounded,
  'matematika': Icons.calculate_rounded,
  'ingliz_tili': Icons.translate_rounded,
  'biologiya': Icons.eco_rounded,
  'kimyo': Icons.science_rounded,
  'fizika': Icons.bolt_rounded,
  'jahon_tarixi': Icons.public_rounded,
  'tarix': Icons.account_balance_rounded,
  'ozbek_adabiyoti': Icons.history_edu_rounded,
  'jahon_adabiyoti': Icons.auto_stories_rounded,
  'koreys_tili': Icons.language_rounded,
  'fransuz_tili': Icons.g_translate_rounded,
};

/// DTM-style certificate grade → accent colour.
Color gradeColor(String? grade) {
  switch (grade) {
    case 'A+':
    case 'A':
      return const Color(0xFF58CC02);
    case 'B+':
    case 'B':
      return const Color(0xFF1CB0F6);
    case 'C+':
      return const Color(0xFFFFC800);
    case 'C':
      return const Color(0xFFFF9600);
    case 'Sertifikatsiz':
      return const Color(0xFFFF4B4B);
    default:
      return const Color(0xFF94A3B8);
  }
}
