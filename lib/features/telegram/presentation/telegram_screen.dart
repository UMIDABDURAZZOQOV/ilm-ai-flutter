import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/duo_icon.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/application/auth_controller.dart';
import '../data/telegram_repository.dart';

const _telegramBot = String.fromEnvironment('TELEGRAM_BOT', defaultValue: 'ILM_AI_HELPER_bot');

const _botFeatures = [
  (
    cmd: '/quiz',
    desc: {
      'uz': 'Materiallaringizdan 5 ta savol',
      'ru': '5 вопросов из ваших материалов',
      'en': '5 questions from your uploaded materials',
    },
  ),
  (
    cmd: '/reminder 09:00',
    desc: {
      'uz': 'Kunlik eslatma vaqtini o\'rnatish',
      'ru': 'Установить время ежедневного напоминания',
      'en': 'Set daily reminder time',
    },
  ),
  (
    cmd: '/streak',
    desc: {
      'uz': 'Ketma-ket o\'qish kunlari sonini ko\'rish',
      'ru': 'Посмотреть количество дней подряд',
      'en': 'View consecutive study days',
    },
  ),
  (
    cmd: '/link',
    desc: {
      'uz': 'Veb akkauntingiz bilan bog\'lash',
      'ru': 'Связать с вашим веб-аккаунтом',
      'en': 'Link with your web account',
    },
  ),
];

String _pick(String language, String uz, String ru, String en) {
  switch (language) {
    case 'uz':
      return uz;
    case 'ru':
      return ru;
    default:
      return en;
  }
}

final _telegramStatusProvider = FutureProvider.autoDispose<TelegramStatus?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(telegramRepositoryProvider).getStatus(userId);
});

class TelegramScreen extends ConsumerStatefulWidget {
  const TelegramScreen({super.key});

  @override
  ConsumerState<TelegramScreen> createState() => _TelegramScreenState();
}

class _TelegramScreenState extends ConsumerState<TelegramScreen> {
  final _reminderTime = TextEditingController();
  bool _saving = false;
  bool _saved = false;
  String? _error;
  bool _initialized = false;

  Future<void> _openBot() async {
    final uri = Uri.parse('https://t.me/$_telegramBot');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _saveReminder() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final valid = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(_reminderTime.text.trim());
    if (!valid) {
      setState(() => _error = 'HH:MM');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });
    try {
      await ref.read(telegramRepositoryProvider).saveReminder(userId: userId, reminderTime: _reminderTime.text.trim());
      ref.invalidate(_telegramStatusProvider);
      setState(() => _saved = true);
    } catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final statusAsync = ref.watch(_telegramStatusProvider);

    statusAsync.whenData((status) {
      if (!_initialized && status?.reminderTime != null) {
        _initialized = true;
        _reminderTime.text = status!.reminderTime!;
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(t('telegram.title', language))),
      body: SafeArea(
        child: statusAsync.when(
          data: (status) {
            final linked = status?.linked == true;
            final streakDays = status?.streakDays ?? 0;
            final streakIcon = streakDays >= 7
                ? Icons.local_fire_department_rounded
                : streakDays >= 3
                    ? Icons.star_rounded
                    : Icons.trending_up_rounded;
            final streakIconColor = streakDays >= 7
                ? const Color(0xFFF59E0B)
                : streakDays >= 3
                    ? colors.secondary
                    : colors.success;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: linked ? colors.success.withValues(alpha: 0.08) : colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: linked ? colors.success : colors.primary),
                  ),
                  child: Column(
                    children: [
                      DuoIcon(linked ? Icons.check_circle_rounded : Icons.link_rounded, size: 40, color: linked ? colors.success : colors.primary)
                          .animate(onPlay: (c) => linked ? null : c.repeat(reverse: true))
                          .scaleXY(begin: 1, end: linked ? 1 : 1.08, duration: 900.ms, curve: Curves.easeInOut),
                      const SizedBox(height: 10),
                      Text(
                        linked
                            ? _pick(language, 'Telegram ulangan', 'Telegram подключён', 'Telegram Connected')
                            : _pick(language, 'Telegram ulanmagan', 'Telegram не подключён', 'Telegram Not Connected'),
                        style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        linked
                            ? _pick(language, 'Siz Telegram bot bilan bog\'langansiz', 'Вы подключены к Telegram боту', 'You are connected to the Telegram bot')
                            : _pick(language, 'Botga /link buyrug\'i bilan ulaning', 'Подключитесь через команду /link в боте', 'Connect using /link command in the bot'),
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
                if (linked)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                    child: Row(
                      children: [
                        DuoIcon(streakIcon, color: streakIconColor, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$streakDays', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: colors.text)),
                            Text(
                              _pick(language, 'kunlik streak', 'дней подряд', 'day streak'),
                              style: TextStyle(color: colors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        if (status?.lastStudyDate != null) ...[
                          const Spacer(),
                          Text(
                            '${_pick(language, 'Oxirgi: ', 'Последний: ', 'Last: ')}${status!.lastStudyDate}',
                            style: TextStyle(color: colors.textMuted, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 80.ms, duration: 320.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 16),
                GradientButton(
                  onPressed: _openBot,
                  child: Text(
                    linked
                        ? _pick(language, 'Botni ochish', 'Открыть бот', 'Open Bot')
                        : _pick(language, 'Botga o\'tish va /link qilish', 'Перейти к боту и /link', 'Go to Bot & /link'),
                  ),
                ),
                const SizedBox(height: 24),
                ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
                Row(
                  children: [
                    Icon(Icons.alarm_rounded, size: 18, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _pick(language, 'Kunlik eslatma vaqti', 'Время ежедневного напоминания', 'Daily Reminder Time'),
                      style: TextStyle(fontWeight: FontWeight.w700, color: colors.text),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _pick(
                    language,
                    'Har kuni shu vaqtda Telegram orqali o\'qish eslatmasi keladi (Toshkent vaqti)',
                    'Ежедневное напоминание об учёбе придёт в это время (время Ташкента)',
                    'Daily study reminder will arrive at this time (Tashkent time)',
                  ),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _reminderTime,
                        decoration: InputDecoration(
                          hintText: '09:00',
                          filled: true,
                          fillColor: colors.inputBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saving ? null : _saveReminder,
                      style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
                      child: Text(_saved ? _pick(language, 'Saqlandi!', 'Сохранено!', 'Saved!') : t('common.save', language)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Icon(Icons.memory_rounded, size: 18, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _pick(language, 'Bot nima qila oladi?', 'Что умеет бот?', 'What can the bot do?'),
                      style: TextStyle(fontWeight: FontWeight.w700, color: colors.text),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < _botFeatures.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                          child: Text(_botFeatures[i].cmd, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: colors.primary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_botFeatures[i].desc[language] ?? _botFeatures[i].desc['en']!, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
                      ],
                    ),
                  ).animate().fadeIn(delay: (240 + i * 60).ms, duration: 260.ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(extractError(e), style: TextStyle(color: colors.error))),
        ),
      ),
    );
  }
}
