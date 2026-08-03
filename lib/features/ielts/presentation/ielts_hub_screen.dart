import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
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
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Band card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 3)),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(band != null ? band.toStringAsFixed(1) : '—', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  const Text('BAND', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_tr(lang, 'Umumiy band', 'Общий балл', 'Overall band'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${_tr(lang, 'Sinov testlari', 'Пробные тесты', 'Mock tests')}: ${_mocks?.length ?? 0}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Text(_tr(lang, 'To\'rt ko\'nikma', 'Четыре навыка', 'The four skills'),
              style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...skills.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => s.screen())),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.border)),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: s.c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                        child: Icon(s.icon, color: s.c, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.title, style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(s.desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                    ]),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
