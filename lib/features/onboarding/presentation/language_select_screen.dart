import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);

    const options = [
      ('uz', 'language.uz', '🇺🇿'),
      ('ru', 'language.ru', '🇷🇺'),
      ('en', 'language.en', '🇬🇧'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t('language.select.title', language),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.text),
              ),
              const SizedBox(height: 8),
              Text(
                t('language.select.subtitle', language),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: colors.textSecondary),
              ),
              const SizedBox(height: 32),
              for (final (code, key, flag) in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      ref.read(languageProvider.notifier).setLanguage(code);
                      context.go('/onboarding');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: language == code ? colors.primary : colors.border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Text(flag, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(child: Text(t(key, language == code ? code : language), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.text))),
                          if (language == code) Icon(Icons.check_circle, color: colors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
