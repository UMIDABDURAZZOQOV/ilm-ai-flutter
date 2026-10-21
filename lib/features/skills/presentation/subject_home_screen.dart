import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/network/error_message.dart';
import '../../../core/config/mobile_release.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import '../application/learning_preferences.dart';
import 'mascot.dart';
import 'skill_path_screen.dart';
import 'skill_practice_screen.dart';
import 'skill_leaderboard_screen.dart';
import 'skill_profile_screen.dart';
import 'skill_quests_screen.dart';
import 'skill_ui.dart';
import 'curriculum_learning_screen.dart';

final subjectCatalogProvider = FutureProvider<List<SkillSubject>>(
  (ref) => ref.watch(skillTreeRepositoryProvider).getSubjects(),
);

/// Selection belongs to the signed-in learner, not to the device's last user.
final selectedSubjectProvider = StateProvider<String?>((ref) {
  ref.watch(studyRevisionProvider);
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
  final int _revision = 0;
  /// Lazy-mount tabs so Quests/League/Profile do not fire network (+18s
  /// timeout timers) until the user opens them. Once visited, IndexedStack
  /// keeps them alive (no spinner on return).
  final Set<int> _visitedTabs = {0};

  Future<void> _select(SkillSubject subject) async {
    final user = ref.read(currentUserIdProvider);
    if (user == null) return;
    await ref.read(learningPreferencesProvider).save(user, {'subject': subject.slug});
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
      error: (error, _) => Scaffold(
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
                Text(extractError(error,language:lang),textAlign:TextAlign.center),
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
                  const Center(
                    child: MascotImage(pose: MascotPose.hello, size: 120),
                  ),
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
          tr('Liga', 'Лига', 'League'),
          tr('Profil', 'Профиль', 'Profile'),
        ];
        const icons = [
          Icons.home_rounded,
          Icons.fitness_center_rounded,
          Icons.assignment_rounded,
          Icons.shield_rounded,
          Icons.person_rounded,
        ];
        // IndexedStack keeps visited tab state/cache alive so Quests/Profile
        // do not flash a spinner every time the user returns to them.
        // Local copy so closures do not see the outer nullable `subject`.
        final SkillSubject activeSubject = subject;
        final tabBuilders = <Widget Function()>[
          () => activeSubject.slug == 'biologiya' ? CurriculumLearningScreen(
            key:ValueKey('curriculum:${ref.watch(currentUserIdProvider)}'),
            subject:activeSubject,onChangeSubject:()=>setState(()=>_choosing=true),
          ) : SkillPathScreen(
            key: ValueKey('${activeSubject.slug}:$_revision'),
            subject: activeSubject,
            onChangeSubject: () => setState(() => _choosing = true),
          ),
          () => Scaffold(
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
                  biologyOnly ? tr(
                    'Biologiya bo‘yicha bilimingizni takrorlang va mustahkamlang.',
                    'Повторяйте и закрепляйте знания по биологии.',
                    'Review and strengthen your biology knowledge.',
                  ) : tr(
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
                  color:
                      Theme.of(context).extension<AppColors>()?.colors.secondary ??
                      const Color(0xFFF9A825),
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
          ),
          () => const SkillQuestsScreen(),
          () => const SkillLeaderboardScreen(),
          () => Column(
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
          ),
        ];
        final tabs = [
          for (var i = 0; i < tabBuilders.length; i++)
            _visitedTabs.contains(i)
                ? TickerMode(enabled: _tab == i, child: tabBuilders[i]())
                : const SizedBox.shrink(),
        ];
        return Scaffold(
          body: IndexedStack(index: _tab, children: tabs),
          bottomNavigationBar: DuoBottomNav(
            index: _tab,
            onChanged: (index) {
              // Only switch tab — do NOT bump _revision (that remounted Learn).
              if (index == _tab) return;
              setState(() {
                _visitedTabs.add(index);
                _tab = index;
              });
            },
            items: [
              for (var i = 0; i < labels.length; i++)
                DuoNavItem(icon: icons[i], label: labels[i]),
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()?.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors?.card ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 2.4),
        boxShadow: [
          BoxShadow(color: duoShadowOf(color), offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 26),
          ),
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
}
