import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_pressable.dart';
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
      appBar: AppBar(title: Text(t('settings.title', language))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(t('settings.account', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('settings.name.label', language), style: TextStyle(fontSize: 12, color: colors.textMuted)),
                  const SizedBox(height: 2),
                  Text(user?.name ?? '—', style: TextStyle(fontSize: 15, color: colors.text, fontWeight: FontWeight.w600)),
                ],
              ),
            ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 24),
            Text(t('settings.appearance', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
              child: Row(
                children: [
                  for (final mode in ['light', 'dark', 'system'])
                    Expanded(
                      child: _SegButton(
                        label: t('settings.theme.$mode', language),
                        selected: themeMode == mode,
                        colors: colors,
                        onTap: () => ref.read(themeModeProvider.notifier).setMode(mode),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 60.ms, duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 24),
            Text(t('settings.language.label', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
              child: Row(
                children: [
                  for (final lang in ['uz', 'ru', 'en'])
                    Expanded(
                      child: _SegButton(
                        label: t('language.$lang', language),
                        selected: language == lang,
                        colors: colors,
                        onTap: () => ref.read(languageProvider.notifier).setLanguage(lang),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 120.ms, duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 32),
            AnimatedPressable(
              onTap: () async {
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
              child: Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.errorLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.error)),
                child: Text(t('settings.logout', language), style: TextStyle(color: colors.error, fontWeight: FontWeight.w700)),
              ),
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

  const _SegButton({required this.label, required this.selected, required this.colors, required this.onTap});

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
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(color: selected ? Colors.white : colors.text, fontWeight: FontWeight.w600, fontSize: 13),
          child: Text(label),
        ),
      ),
    );
  }
}
