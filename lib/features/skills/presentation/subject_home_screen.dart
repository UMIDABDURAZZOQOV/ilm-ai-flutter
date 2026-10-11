import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import 'mascot.dart';
import 'skill_path_screen.dart';
import 'skill_practice_screen.dart';
import 'skill_leaderboard_screen.dart';
import 'skill_profile_screen.dart';
import 'skill_quests_screen.dart';
import 'skill_ui.dart';

final subjectCatalogProvider = FutureProvider<List<SkillSubject>>(
  (ref) => ref.watch(skillTreeRepositoryProvider).getSubjects(),
);

/// Selection belongs to the signed-in learner, not to the device's last user.
final selectedSubjectProvider = StateProvider<String?>((ref) {
  final user = ref.watch(currentUserIdProvider);
  return user == null
      ? null
      : ref.read(prefsServiceProvider).getString('subject_$user');
});

class SubjectHomeScreen extends ConsumerStatefulWidget {
  const SubjectHomeScreen({super.key});
  @override
  ConsumerState<SubjectHomeScreen> createState() => _SubjectHomeScreenState();
}

class _SubjectHomeScreenState extends ConsumerState<SubjectHomeScreen> {
  int _tab = 0;
  bool _choosing = false;
  int _revision = 0;

  Future<void> _select(SkillSubject subject) async {
    final user = ref.read(currentUserIdProvider);
    if (user == null) return;
    await ref
        .read(prefsServiceProvider)
        .setString('subject_$user', subject.slug);
    if (!mounted || ref.read(currentUserIdProvider) != user) return;
    ref.read(selectedSubjectProvider.notifier).state = subject.slug;
    setState(() {
      _choosing = false;
      _tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    String tr(String uz, String ru, String en) => str3(lang, uz, ru, en);
    final selected = ref.watch(selectedSubjectProvider);
    final catalog = ref.watch(subjectCatalogProvider);
    return catalog.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr(
                    'Fanlarni yuklab bo‘lmadi',
                    'Не удалось загрузить предметы',
                    'Could not load subjects',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(subjectCatalogProvider),
                  child: Text(tr('Qayta urinish', 'Повторить', 'Try again')),
                ),
                TextButton(
                  onPressed: () => context.push('/settings'),
                  child: Text(tr('Sozlamalar', 'Настройки', 'Settings')),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (subjects) {
        SkillSubject? subject;
        for (final item in subjects) {
          if (item.slug == selected) subject = item;
        }
        if (subject == null || _choosing) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: subject == null
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => _choosing = false),
                      icon: const Icon(Icons.close),
                    ),
              title: const Text('Ilm AI'),
              actions: [
                IconButton(
                  onPressed: () => context.push('/settings'),
                  tooltip: tr('Sozlamalar', 'Настройки', 'Settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  const Center(child: Mascot(mood: MascotMood.happy, size: 96)),
                  const SizedBox(height: 20),
                  Text(
                    tr(
                      'Qaysi fanni o‘rganamiz?',
                      'Какой предмет будем изучать?',
                      'What will you learn?',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(
                      'Bir fan tanlang. Har kuni kichik qadam — katta bilim.',
                      'Выберите предмет. Маленькие шаги каждый день — большие знания.',
                      'Choose a subject. Small steps every day build lasting knowledge.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  if (subjects.isEmpty) ...[
                    Text(
                      tr(
                        'Fanlar tayyorlanmoqda',
                        'Предметы готовятся',
                        'Subjects are being prepared',
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(subjectCatalogProvider),
                      child: Text(tr('Yangilash', 'Обновить', 'Refresh')),
                    ),
                  ],
                  for (final item in subjects)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LearningTile(
                        icon:
                            subjectIcons[item.slug] ?? Icons.menu_book_rounded,
                        color: skillColor(item.color),
                        title: item.nameFor(lang),
                        subtitle: item.slug == selected
                            ? tr(
                                'Hozirgi fan',
                                'Текущий предмет',
                                'Current subject',
                              )
                            : null,
                        onTap: () => _select(item),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
        final labels = [
          tr('O‘rganish', 'Учиться', 'Learn'),
          tr('Mashq', 'Практика', 'Practice'),
          tr('Vazifalar', 'Задания', 'Quests'),
          tr('Reyting', 'Рейтинг', 'League'),
          tr('Profil', 'Профиль', 'Profile'),
        ];
        const icons = [
          Icons.home_rounded,
          Icons.fitness_center_rounded,
          Icons.assignment_rounded,
          Icons.shield_rounded,
          Icons.person_rounded,
        ];
        Widget body;
        switch (_tab) {
          case 0:
            body = SkillPathScreen(
              key: ValueKey('${subject.slug}:$_revision'),
              subject: subject,
              onChangeSubject: () => setState(() => _choosing = true),
            );
          case 1:
            body = Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(labels[1]),
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    tr(
                      'Bilimingizni mustahkamlang',
                      'Закрепите знания',
                      'Make your knowledge stick',
                    ),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      'Takrorlash barcha o‘rgangan fanlaringizni qamrab oladi.',
                      'Повторение охватывает все изученные предметы.',
                      'Review covers all the subjects you have studied.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _LearningTile(
                    icon: Icons.auto_fix_high_rounded,
                    color: const Color(0xFFCE82FF),
                    title: tr(
                      'Xatolar ustida ishlash',
                      'Работа над ошибками',
                      'Review mistakes',
                    ),
                    onTap: () => context.push(
                      '/skills/practice',
                      extra: {'mode': PracticeMode.mistakes},
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LearningTile(
                    icon: Icons.today_rounded,
                    color: const Color(0xFF58CC02),
                    title: tr('Kunlik sinov', 'Вызов дня', 'Daily challenge'),
                    onTap: () => context.push(
                      '/skills/practice',
                      extra: {'mode': PracticeMode.daily},
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LearningTile(
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFF9600),
                    title: tr(
                      'Tezlik mashqi',
                      'На скорость',
                      'Lightning practice',
                    ),
                    onTap: () => context.push(
                      '/skills/practice',
                      extra: {'mode': PracticeMode.lightning},
                    ),
                  ),
                ],
              ),
            );
          case 2:
            body = const SkillQuestsScreen();
          case 3:
            body = const SkillLeaderboardScreen();
          default:
            body = Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(tr('Sozlamalar', 'Настройки', 'Settings')),
                    ),
                  ),
                ),
                const Expanded(child: SkillProfileScreen()),
              ],
            );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (index) => setState(() {
              _tab = index;
              _revision++;
            }),
            indicatorColor: const Color(0xFF58CC02).withValues(alpha: 0.18),
            destinations: [
              for (var i = 0; i < labels.length; i++)
                NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
            ],
          ),
        );
      },
    );
  }
}

class _LearningTile extends StatelessWidget {
  const _LearningTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.18),
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: Icon(icon, color: color, size: 34),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    ),
  );
}
