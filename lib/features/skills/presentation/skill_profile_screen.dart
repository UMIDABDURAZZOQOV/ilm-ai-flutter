import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';

final _profileProvider = FutureProvider.autoDispose<SkillProfile?>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(skillExtrasRepositoryProvider).getProfile(userId);
});

class SkillProfileScreen extends ConsumerWidget {
  const SkillProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final async = ref.watch(_profileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(str3(lang, 'Mening profilim', 'Мой профиль', 'My profile'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(str3(lang, 'Xatolik', 'Ошибка', 'Error'))),
        data: (p) => p == null
            ? const SizedBox()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    CircleAvatar(radius: 30, backgroundColor: const Color(0xFF58CC02).withValues(alpha: 0.2), child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF3A8A00)))),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: skillColor(p.league.color).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('${p.league.nameFor(lang)} ${str3(lang, 'ligasi', 'лига', 'league')}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: skillColor(p.league.color))),
                      ),
                    ]),
                  ]),
                  const SizedBox(height: 18),
                  Row(children: [
                    _tile(Icons.bolt_rounded, const Color(0xFFFFC800), '${p.xpTotal}', 'XP'),
                    const SizedBox(width: 10),
                    _tile(Icons.local_fire_department_rounded, const Color(0xFFFF9600), '${p.streakDays}', str3(lang, 'kun', 'дней', 'streak')),
                    const SizedBox(width: 10),
                    _tile(Icons.menu_book_rounded, const Color(0xFF58CC02), '${p.lessonsCompleted}', str3(lang, 'dars', 'уроков', 'lessons')),
                  ]),
                  if (p.strongest != null || p.weakest != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      if (p.strongest != null) Expanded(child: _sw(str3(lang, 'Eng kuchli', 'Сильнейший', 'Strongest'), p.strongest!.nameFor(lang), '${p.strongest!.pct}%', const Color(0xFF58CC02))),
                      if (p.strongest != null && p.weakest != null && p.weakest!.slug != p.strongest!.slug) const SizedBox(width: 10),
                      if (p.weakest != null && p.weakest!.slug != p.strongest?.slug) Expanded(child: _sw(str3(lang, 'Eng zaif', 'Слабейший', 'Weakest'), p.weakest!.nameFor(lang), '${p.weakest!.pct}%', const Color(0xFFFF4B4B))),
                    ]),
                  ],
                  const SizedBox(height: 18),
                  Text(str3(lang, 'Faollik (12 hafta)', 'Активность (12 недель)', 'Activity (12 weeks)'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _Heatmap(activity: p.activity, weeks: 12),
                  const SizedBox(height: 18),
                  Text(str3(lang, 'Fanlar bo\'yicha', 'По предметам', 'By subject'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final s in p.subjects) _subjectBar(lang, s),
                ],
              ),
      ),
    );
  }

  Widget _tile(IconData icon, Color color, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
          child: Column(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ]),
        ),
      );

  Widget _sw(String label, String subject, String pct, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
          Text(subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Text(pct, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ]),
      );

  Widget _subjectBar(String lang, SubjectProgress s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(s.nameFor(lang), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            Text('${s.completed}/${s.total} · ⭐${s.stars}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: s.total == 0 ? 0 : s.completed / s.total, minHeight: 9, color: skillColor(s.color), backgroundColor: Colors.black12),
          ),
        ]),
      );
}

class _Heatmap extends StatelessWidget {
  final Map<String, int> activity;
  final int weeks;
  const _Heatmap({required this.activity, required this.weeks});

  @override
  Widget build(BuildContext context) {
    final days = weeks * 7;
    final today = DateTime.now();
    final cols = <List<int>>[];
    var current = <int>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      current.add(activity[key] ?? 0);
      if (current.length == 7) {
        cols.add(current);
        current = <int>[];
      }
    }
    if (current.isNotEmpty) cols.add(current);

    Color shade(int c) {
      if (c == 0) return Colors.black12;
      if (c < 2) return const Color(0xFF86E01E);
      if (c < 4) return const Color(0xFF58CC02);
      return const Color(0xFF3A8A00);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final col in cols)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Column(
                children: [
                  for (final c in col)
                    Container(width: 12, height: 12, margin: const EdgeInsets.only(bottom: 3), decoration: BoxDecoration(color: shade(c), borderRadius: BorderRadius.circular(3))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
