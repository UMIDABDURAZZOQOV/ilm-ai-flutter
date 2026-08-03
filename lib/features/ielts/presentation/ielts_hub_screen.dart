import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/ielts_models.dart';
import '../data/ielts_repository.dart';
import 'ielts_reading_screen.dart';
import 'ielts_listening_screen.dart';
import 'ielts_writing_screen.dart';
import 'ielts_speaking_screen.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class IeltsHubScreen extends ConsumerStatefulWidget {
  const IeltsHubScreen({super.key});
  @override
  ConsumerState<IeltsHubScreen> createState() => _IeltsHubScreenState();
}

class _IeltsHubScreenState extends ConsumerState<IeltsHubScreen> {
  List<IeltsMockTest>? _mocks;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final m = await ref.read(ieltsRepositoryProvider).userMocks(userId);
      if (mounted) setState(() => _mocks = m);
    } catch (_) {
      if (mounted) setState(() => _mocks = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    final band = (_mocks != null && _mocks!.isNotEmpty) ? _mocks!.first.overallBand : null;

    final skills = [
      (
        icon: Icons.headphones_rounded, c: const Color(0xFF8B5CF6),
        title: _tr(lang, 'Tinglash', 'Аудирование', 'Listening'),
        desc: _tr(lang, 'Audio yozuvlar va savollar', 'Аудио и вопросы', 'Audio recordings & questions'),
        screen: () => const IeltsListeningScreen(),
      ),
      (
        icon: Icons.menu_book_rounded, c: const Color(0xFF22C55E),
        title: _tr(lang, 'O\'qish', 'Чтение', 'Reading'),
        desc: _tr(lang, 'Akademik matnlar', 'Академические тексты', 'Academic passages'),
        screen: () => const IeltsReadingScreen(),
      ),
      (
        icon: Icons.edit_note_rounded, c: const Color(0xFFF97316),
        title: _tr(lang, 'Yozish', 'Письмо', 'Writing'),
        desc: _tr(lang, 'AI band baholash', 'AI-оценка балла', 'Instant AI band feedback'),
        screen: () => const IeltsWritingScreen(),
      ),
      (
        icon: Icons.mic_rounded, c: const Color(0xFFEC4899),
        title: _tr(lang, 'Gapirish', 'Говорение', 'Speaking'),
        desc: _tr(lang, 'Ovoz yozib, AI tahlil', 'Запись и AI-анализ', 'Record & get AI feedback'),
        screen: () => const IeltsSpeakingScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'IELTS tayyorgarlik', 'Подготовка к IELTS', 'IELTS Preparation'),
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Band card
          PremiumGradientCard(
            padding: const EdgeInsets.all(24),
            gradientColors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
            borderRadius: 24,
            child: Row(children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3)),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(band != null ? band.toStringAsFixed(1) : '—', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const Text('BAND', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_tr(lang, 'Umumiy band', 'Общий балл', 'Overall band'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  Text('${_tr(lang, 'Sinov testlari', 'Пробные тесты', 'Mock tests')}: ${_mocks?.length ?? 0}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            ]),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 24),
          Text(_tr(lang, 'To\'rt ko\'nikma', 'Четыре навыка', 'The four skills'),
              style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 16),
          ...skills.asMap().entries.map((entry) {
            final index = entry.key;
            final s = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AnimatedPressable(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => s.screen())),
                child: PremiumCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 20,
                  child: Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: s.c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                      child: Icon(s.icon, color: s.c, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.title, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text(s.desc, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
                    ),
                  ]),
                ),
              ).animate().fadeIn(delay: (100 + index * 80).ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            );
          }),
        ],
      ),
    );
  }
}
