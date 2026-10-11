import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import '../data/skill_extras_repository.dart';
import 'skill_practice_screen.dart';
import 'skill_ui.dart';
import 'daily_goal_bottom_sheet.dart';

final learningGoalsProvider = FutureProvider.autoDispose((ref) async {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) throw StateError('Not signed in');
  final results = await Future.wait<dynamic>([
    ref.watch(skillTreeRepositoryProvider).getSummary(id),
    ref.watch(skillExtrasRepositoryProvider).getDailyChallenge(id),
    ref.watch(dioProvider).get('/skills/$id/streak-freezes'),
  ]);
  return (
    summary: results[0] as GamificationSummary,
    completed: results[1].completed as bool,
    freezes: (results[2].data['count'] as num).toInt(),
  );
});

class SkillQuestsScreen extends ConsumerWidget {
  const SkillQuestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    String tr(String uz, String ru, String en) => str3(lang, uz, ru, en);
    final goals = ref.watch(learningGoalsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(tr('Vazifalar', 'Задания', 'Quests')),
        actions: [
          IconButton(
            tooltip: tr('Yutuqlar', 'Награды', 'Awards'),
            onPressed: () => context.push('/skills/achievements'),
            icon: const Icon(Icons.military_tech_rounded),
          ),
        ],
      ),
      body: goals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(learningGoalsProvider),
            child: Text(tr('Qayta urinish', 'Повторить', 'Try again')),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(learningGoalsProvider);
            await ref.read(learningGoalsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9600).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 80,
                      color: Color(0xFFFF9600),
                    ),
                    Text(
                      '${data.summary.streakDays}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF9600),
                      ),
                    ),
                    Text(
                      tr('kunlik seriya', 'дней подряд', 'day streak'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr(
                        'Har kuni o‘rganib, seriyani davom ettiring.',
                        'Учитесь каждый день, чтобы продолжать серию.',
                        'Learn every day to keep your streak going.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.ac_unit_rounded,
                          color: Color(0xFF2DD4BF),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            tr(
                              'Seriya himoyasi: ${data.freezes}',
                              'Заморозки: ${data.freezes}',
                              'Streak freezes: ${data.freezes}',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                tr('Bugungi vazifalar', 'Задания на сегодня', 'Today’s quests'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              () {
                final customGoal = ref.watch(userDailyGoalProvider);
                final goalXp = customGoal > 0 ? customGoal : data.summary.dailyGoalXp;
                return _Quest(
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFFFFC800),
                  title: tr(
                    '$goalXp XP to‘plang',
                    'Наберите $goalXp XP',
                    'Earn $goalXp XP',
                  ),
                  progress: data.summary.todayXp,
                  target: goalXp,
                );
              }(),
              const SizedBox(height: 14),
              _Quest(
                icon: Icons.flag_rounded,
                color: const Color(0xFFCE82FF),
                title: tr(
                  'Kunlik sinovni bajaring',
                  'Завершите вызов дня',
                  'Complete the daily challenge',
                ),
                progress: data.completed ? 1 : 0,
                target: 1,
                onTap: data.completed
                    ? null
                    : () async {
                        await context.push(
                          '/skills/practice',
                          extra: {'mode': PracticeMode.daily},
                        );
                        if (context.mounted) {
                          ref.invalidate(learningGoalsProvider);
                        }
                      },
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push('/skills/achievements'),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(
                  tr('Barcha yutuqlar', 'Все достижения', 'All achievements'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Quest extends StatelessWidget {
  const _Quest({
    required this.icon,
    required this.color,
    required this.title,
    required this.progress,
    required this.target,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final int progress;
  final int target;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Theme.of(context).dividerColor.withValues(alpha: .25),
        width: 2,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              progress >= target ? Icons.check_circle_rounded : icon,
              color: color,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: target <= 0
                        ? 0
                        : (progress / target).clamp(0.0, 1.0),
                    color: color,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 6),
                  Text('${progress.clamp(0, target)}/$target'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
