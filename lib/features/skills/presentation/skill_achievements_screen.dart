import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';

final _achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return [];
  return ref.read(skillExtrasRepositoryProvider).getAchievements(userId);
});

const _groupIcons = {
  'streak': Icons.local_fire_department_rounded,
  'lessons': Icons.menu_book_rounded,
  'perfect': Icons.star_rounded,
  'questions': Icons.help_outline_rounded,
  'xp': Icons.bolt_rounded,
};

const _groupColors = {
  'streak': Color(0xFFFF9600),
  'lessons': Color(0xFF58CC02),
  'perfect': Color(0xFFFFC800),
  'questions': Color(0xFF1CB0F6),
  'xp': Color(0xFFCE82FF),
};

class SkillAchievementsScreen extends ConsumerWidget {
  const SkillAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final async = ref.watch(_achievementsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(str3(lang, 'Yutuqlar', 'Достижения', 'Achievements'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(str3(lang, 'Xatolik', 'Ошибка', 'Error'))),
        data: (list) {
          final earned = list.where((a) => a.earned).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${str3(lang, 'Qo\'lga kiritilgan', 'Получено', 'Earned')}: $earned/${list.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
                children: [for (final a in list) _badge(lang, a)],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _badge(String lang, Achievement a) {
    final color = _groupColors[a.group] ?? const Color(0xFF58CC02);
    final icon = _groupIcons[a.group] ?? Icons.emoji_events_rounded;
    return Opacity(
      opacity: a.earned ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: a.earned ? color : Colors.black12, width: a.earned ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text('${a.target}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(_groupLabel(lang, a.group), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
            if (!a.earned && a.progress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('${a.progress}/${a.target}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              ),
          ],
        ),
      ),
    );
  }

  String _groupLabel(String lang, String group) {
    switch (group) {
      case 'streak':
        return str3(lang, 'kun seriya', 'дней подряд', 'day streak');
      case 'lessons':
        return str3(lang, 'dars', 'уроков', 'lessons');
      case 'perfect':
        return str3(lang, "3 yulduz", '3 звезды', '3 stars');
      case 'questions':
        return str3(lang, 'savol', 'вопросов', 'questions');
      case 'xp':
        return 'XP';
      default:
        return group;
    }
  }
}
