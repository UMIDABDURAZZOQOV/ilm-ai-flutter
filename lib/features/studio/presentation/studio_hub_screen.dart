import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/animated_pressable.dart';
import 'studio_text_tools.dart';
import 'studio_more_tools.dart';
import 'studio_media_tools.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class _Tool {
  final IconData icon;
  final Color color;
  final String Function(String) title;
  final String Function(String) sub;
  final Widget Function() build;
  const _Tool({required this.icon, required this.color, required this.title, required this.sub, required this.build});
}

class StudioHubScreen extends ConsumerWidget {
  const StudioHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);

    final tools = <_Tool>[
      _Tool(
        icon: Icons.search_rounded,
        color: const Color(0xFF06B6D4),
        title: (l) => _tr(l, 'Daftaringizni qidirish', 'Поиск по заметкам', 'Search your notes'),
        sub: (l) => _tr(l, 'Ma\'no bo\'yicha materialdan qidirish', 'Смысловой поиск', 'Semantic search'),
        build: () => const StudioSearchScreen(),
      ),
      _Tool(
        icon: Icons.description_rounded,
        color: const Color(0xFFF59E0B),
        title: (l) => _tr(l, 'Bir sahifa shpargalka', 'Шпаргалка', 'Cheat sheet'),
        sub: (l) => _tr(l, 'Eng muhim faktlar bir sahifada', 'Ключевые факты', 'Key facts on one page'),
        build: () => const StudioMarkdownScreen(kind: 'cheat'),
      ),
      _Tool(
        icon: Icons.translate_rounded,
        color: const Color(0xFF6366F1),
        title: (l) => _tr(l, 'Tarjima + tushuntirish', 'Перевод + объяснение', 'Translate & explain'),
        sub: (l) => _tr(l, 'Chet tilidagi materialni tarjima', 'Перевод материала', 'Translate foreign material'),
        build: () => const StudioMarkdownScreen(kind: 'translate'),
      ),
      _Tool(
        icon: Icons.assignment_rounded,
        color: const Color(0xFF10B981),
        title: (l) => _tr(l, 'Sinov imtihoni', 'Пробный тест', 'Mock test'),
        sub: (l) => _tr(l, 'Materialdan 15 savollik imtihon', 'Экзамен из 15 вопросов', '15-question exam'),
        build: () => const StudioMockScreen(),
      ),
      _Tool(
        icon: Icons.account_tree_rounded,
        color: const Color(0xFF3B82F6),
        title: (l) => _tr(l, 'AI diagramma', 'AI-диаграмма', 'AI diagram'),
        sub: (l) => _tr(l, 'Mavzuni sxema qilib chizish', 'Схема темы', 'Visualize a topic'),
        build: () => const StudioDiagramScreen(),
      ),
      _Tool(
        icon: Icons.headphones_rounded,
        color: const Color(0xFFEC4899),
        title: (l) => _tr(l, 'Audio xulosa', 'Аудио-обзор', 'Audio recap'),
        sub: (l) => _tr(l, 'Materialni tinglab o\'rganing', 'Слушайте материал', 'Listen to your material'),
        build: () => const StudioAudioRecapScreen(),
      ),
      _Tool(
        icon: Icons.podcasts_rounded,
        color: const Color(0xFFF43F5E),
        title: (l) => _tr(l, 'Podkast', 'Подкаст', 'Podcast'),
        sub: (l) => _tr(l, 'Ikki boshlovchili suhbat', 'Диалог двух ведущих', 'Two-host conversation'),
        build: () => const StudioPodcastScreen(),
      ),
      _Tool(
        icon: Icons.photo_camera_rounded,
        color: const Color(0xFF14B8A6),
        title: (l) => _tr(l, 'Rasmdan komplekt', 'Комплект из фото', 'Photo study kit'),
        sub: (l) => _tr(l, 'Sahifani suratga oling — kit tayyor', 'Сфотографируйте страницу', 'Snap a page → full kit'),
        build: () => const StudioPhotoKitScreen(),
      ),
      _Tool(
        icon: Icons.note_add_rounded,
        color: const Color(0xFF22C55E),
        title: (l) => _tr(l, 'Daftardan kutubxonaga', 'Заметки в библиотеку', 'Notes to library'),
        sub: (l) => _tr(l, 'Qo\'lyozmani materialga aylantiring', 'Рукопись в материалы', 'Turn notes into material'),
        build: () => const StudioNotesUploadScreen(),
      ),
      _Tool(
        icon: Icons.hub_rounded,
        color: const Color(0xFFA855F7),
        title: (l) => _tr(l, 'Bilim xaritasi', 'Карта знаний', 'Knowledge map'),
        sub: (l) => _tr(l, 'Tushunchalar bog\'lanishi', 'Связи понятий', 'How concepts connect'),
        build: () => const StudioKnowledgeMapScreen(),
      ),
      _Tool(
        icon: Icons.folder_rounded,
        color: const Color(0xFF8B5CF6),
        title: (l) => _tr(l, 'Materiallarim', 'Мои материалы', 'My materials'),
        sub: (l) => _tr(l, 'Yuklangan hujjatlarni boshqarish', 'Управление документами', 'Manage uploaded docs'),
        build: () => const StudioDocsScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
        title: Row(children: [
          Icon(Icons.auto_awesome_rounded, color: colors.secondary, size: 24),
          const SizedBox(width: 8),
          Text('Ilm AI Studio', style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _tr(lang, 'Yuklagan materialingizni kuchli o\'quv vositalariga aylantiring.',
                'Превратите материалы в мощные учебные инструменты.',
                'Turn your materials into powerful study tools.'),
            style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
          ),
          const SizedBox(height: 20),
          ...tools.asMap().entries.map((entry) {
            final index = entry.key;
            final t = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AnimatedPressable(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => t.build())),
                child: PremiumCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: t.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                      child: Icon(t.icon, color: t.color, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title(lang), style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text(t.sub(lang), style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
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
              ).animate().fadeIn(delay: (index * 50).ms, duration: 350.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            );
          }),
        ],
      ),
    );
  }
}
