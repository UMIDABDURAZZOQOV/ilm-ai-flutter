import '../../../core/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/physics_preview.dart';
import '../../../core/network/dio_client.dart' show apiBaseUrl;

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/duo_chrome.dart' show foregroundOn;
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../auth/application/auth_controller.dart';
import '../../skills/presentation/skill_profile_screen.dart';
import '../../skills/presentation/skill_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final language = ref.read(languageProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _NameDialog(initialName: current),
    );
    if (saved == true && context.mounted) {
      ref.invalidate(skillProfileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              str3(language, 'Ism saqlandi', 'Имя сохранено', 'Name saved'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final soundEnabled = ref.watch(soundEffectsProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t('settings.title', language),
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (physicsPreviewAllowed(apiBaseUrl)) ...[
              ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('Fizika sinovi • 6-sinf'),
                subtitle: const Text('Faqat lokal sinov • §1–7 • O‘zbekcha'),
                onTap: () => context.push('/physics-preview'),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              t('settings.account', language),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            PremiumCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  onTap: () => _editName(context, ref, user?.name ?? ''),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('settings.name.label', language),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.name ?? '—',
                              style: TextStyle(
                                fontSize: 16,
                                color: colors.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_rounded,
                        color: colors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                )
                .motion(context)
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 28),
            Text(
              t('settings.appearance', language),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
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
                              mode == 'light'
                                  ? Icons.light_mode_rounded
                                  : mode == 'dark'
                                  ? Icons.dark_mode_rounded
                                  : Icons.brightness_auto_rounded,
                              size: 20,
                              color: themeMode == mode
                                  ? foregroundOn(colors.primary)
                                  : colors.text,
                            ),
                            onTap: () => ref
                                .read(themeModeProvider.notifier)
                                .setMode(mode),
                          ),
                        ),
                    ],
                  ),
                )
                .motion(context)
                .fadeIn(delay: 60.ms, duration: 280.ms)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 28),
            Text(
              t('settings.language.label', language),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
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
                              lang == 'uz'
                                  ? '🇺🇿'
                                  : lang == 'ru'
                                  ? '🇷🇺'
                                  : '🇬🇧',
                              style: const TextStyle(fontSize: 20),
                            ),
                            onTap: () => ref
                                .read(languageProvider.notifier)
                                .setLanguage(lang),
                          ),
                        ),
                    ],
                  ),
                )
                .motion(context)
                .fadeIn(delay: 120.ms, duration: 280.ms)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 28),
            Text(
              language == 'uz'
                  ? 'Ovoz'
                  : language == 'ru'
                  ? 'Звук'
                  : 'Audio',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            PremiumCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: soundEnabled ? colors.primary : colors.textMuted,
                      ),
                      title: Text(
                        language == 'uz'
                            ? 'Ovoz effektlari'
                            : language == 'ru'
                            ? 'Звуковые эффекты'
                            : 'Sound effects',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      subtitle: Text(
                        language == 'uz'
                            ? 'Dars vaqtida to‘g‘ri/xato tovushlar'
                            : language == 'ru'
                            ? 'Звуки при ответах на вопросы'
                            : 'Feedback sounds during lessons',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      value: soundEnabled,
                      activeThumbColor: colors.primary,
                      onChanged: (val) => ref
                          .read(soundEffectsProvider.notifier)
                          .setEnabled(val),
                    ),
                  ),
                )
                .motion(context)
                .fadeIn(delay: 150.ms, duration: 280.ms)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 36),
            PremiumButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(t('settings.logout', language)),
                    content: Text(t('settings.logout.confirm', language)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(t('common.cancel', language)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          t('settings.logout', language),
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authControllerProvider.notifier).logout();
                }
              },
              backgroundColor: colors.error,
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                t('settings.logout', language),
                style: const TextStyle(fontSize: 15),
              ),
            ).motion(context).fadeIn(delay: 180.ms, duration: 280.ms),
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

  const _SegButton({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: motionDuration(context, 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(height: 4)],
              AnimatedDefaultTextStyle(
                duration: motionDuration(context, 220),
                style: TextStyle(
                  color: selected ? foregroundOn(colors.primary) : colors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameDialog extends ConsumerStatefulWidget {
  final String initialName;
  const _NameDialog({required this.initialName});
  @override
  ConsumerState<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends ConsumerState<_NameDialog> {
  late final TextEditingController _name;
  late final int? _owner;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _owner = ref.read(currentUserIdProvider);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (ref.read(currentUserIdProvider) != _owner) {
      Navigator.pop(context, false);
      return;
    }
    final lang = ref.read(languageProvider);
    final value = _name.text.trim();
    if (value.length < 2) {
      setState(
        () => _error = str3(
          lang,
          'Kamida 2 ta belgi kerak',
          'Нужно минимум 2 символа',
          'At least 2 characters required',
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).updateDisplayName(value);
      if (mounted) {
        Navigator.pop(context, ref.read(currentUserIdProvider) == _owner);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = str3(
            lang,
            'Saqlab bo‘lmadi. Qayta urinib ko‘ring.',
            'Не удалось сохранить. Попробуйте ещё раз.',
            'Could not save. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return AlertDialog(
      scrollable: true,
      title: Text(str3(lang, 'Ism / familiya', 'Имя / фамилия', 'Name')),
      content: TextField(
        controller: _name,
        enabled: !_saving,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: str3(
            lang,
            'Ismingizni yozing',
            'Введите имя',
            'Enter your name',
          ),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t('common.cancel', lang)),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(str3(lang, 'Saqlash', 'Сохранить', 'Save')),
        ),
      ],
    );
  }
}
