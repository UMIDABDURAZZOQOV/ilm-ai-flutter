import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import 'studio_text_tools.dart';

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
    ];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
        title: Row(children: [
          Icon(Icons.auto_awesome_rounded, color: colors.secondary, size: 20),
          const SizedBox(width: 6),
          Text('Ilm AI Studio', style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _tr(lang, 'Yuklagan materialingizni kuchli o\'quv vositalariga aylantiring.',
                'Превратите материалы в мощные учебные инструменты.',
                'Turn your materials into powerful study tools.'),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...tools.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => t.build())),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(color: t.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(14)),
                        child: Icon(t.icon, color: t.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title(lang), style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(t.sub(lang), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                          ],
                        ),
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
