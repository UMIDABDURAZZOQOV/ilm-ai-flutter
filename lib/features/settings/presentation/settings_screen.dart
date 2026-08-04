import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t('settings.title', language), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(t('settings.account', language), style: TextStyle(fontWeight: FontWeight.w800, color: colors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            PremiumCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('settings.name.label', language), style: TextStyle(fontSize: 13, color: colors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(user?.name ?? '—', style: TextStyle(fontSize: 16, color: colors.text, fontWeight: FontWeight.w800)),
                ],
              ),
            ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 28),
            Text(t('settings.appearance', language), style: TextStyle(fontWeight: FontWeight.w800, color: colors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            PremiumCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  for (final mode in ['light', 'dark', 'system'])
                    Expanded(
                      child: _SegButton(
                        label: t('settings.theme.$mode', language),
                        selected: themeMode == mode,
                        colors: colors,
                        leading: Icon(
                          mode == 'light' ? Icons.light_mode_rounded : mode == 'dark' ? Icons.dark_mode_rounded : Icons.brightness_auto_rounded,
                          size: 20, color: themeMode == mode ? Colors.white : colors.text,
                        ),
                        onTap: () => ref.read(themeModeProvider.notifier).setMode(mode),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 60.ms, duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 28),
            Text(t('settings.language.label', language), style: TextStyle(fontWeight: FontWeight.w800, color: colors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            PremiumCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  for (final lang in ['uz', 'ru', 'en'])
                    Expanded(
                      child: _SegButton(
                        label: t('language.$lang', language),
                        selected: language == lang,
                        colors: colors,
                        leading: Text(
                          lang == 'uz' ? '🇺🇿' : lang == 'ru' ? '🇷🇺' : '🇬🇧',
                          style: const TextStyle(fontSize: 20),
                        ),
                        onTap: () => ref.read(languageProvider.notifier).setLanguage(lang),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 120.ms, duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 36),
            PremiumButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(t('settings.logout', language)),
                    content: Text(t('settings.logout.confirm', language)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('common.cancel', language))),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('settings.logout', language), style: TextStyle(color: colors.error))),
                    ],
                  ),
                );
                if (confirmed == true) await ref.read(authControllerProvider.notifier).logout();
              },
              backgroundColor: colors.error,
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(t('settings.logout', language), style: const TextStyle(fontSize: 15)),
            ).animate().fadeIn(delay: 180.ms, duration: 280.ms),
          ],
        ),
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeColors colors;
  final VoidCallback onTap;
  final Widget? leading;

  const _SegButton({required this.label, required this.selected, required this.colors, required this.onTap, this.leading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? colors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(height: 4)],
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(color: selected ? Colors.white : colors.text, fontWeight: FontWeight.w600, fontSize: 12.5),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
