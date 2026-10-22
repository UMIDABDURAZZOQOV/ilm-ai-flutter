import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

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

/// Heuristic: backend authors content in Uzbek and translates ru/en best-effort.
/// When translation fails the original Uzbek is returned — surface a small badge.
bool looksLikeUntranslatedUzbek(String text, String lang) {
  final trimmed = text.trim();
  if (lang == 'uz' || trimmed.isEmpty) return false;
  if (lang == 'ru') {
    final cyrillic = RegExp(r'[\u0400-\u04FF]').allMatches(trimmed).length;
    final letters = RegExp(
      r'[A-Za-zА-Яа-яЁё\u0400-\u04FF]',
    ).allMatches(trimmed).length;
    if (letters < 8) return false;
    return cyrillic / letters < 0.25;
  }
  // English UI but content still has Uzbek-specific letters / common particles.
  return RegExp(r"[ʻʼ‘’']").hasMatch(trimmed) &&
      RegExp(
        r"\b(va|uchun|bilan|bo'lishi|qilish|emas|kerak)\b",
        caseSensitive: false,
      ).hasMatch(trimmed);
}

/// Small notice when lesson body stayed in Uzbek while the UI language is ru/en.
class ContentLanguageBadge extends StatelessWidget {
  final String language;
  const ContentLanguageBadge({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          str3(
            language,
            'Bu dars hozircha faqat o‘zbek tilida',
            'Этот урок пока только на узбекском',
            'This lesson is currently only in Uzbek',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

Color skillColor(String? hex, [Color fallback = const Color(0xFF2A1F6B)]) {
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
      return const Color(0xFF059669);
    case 'B+':
    case 'B':
      return const Color(0xFF2DD4BF);
    case 'C+':
      return const Color(0xFFFFC800);
    case 'C':
      return const Color(0xFFF9A825);
    case 'Sertifikatsiz':
      return const Color(0xFFFF4B4B);
    default:
      return const Color(0xFF94A3B8);
  }
}
