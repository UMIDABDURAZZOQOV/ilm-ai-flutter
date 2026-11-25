import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/mascot_image.dart';
import '../../../core/widgets/animated_ilmo.dart';
import '../../auth/application/auth_controller.dart';
import '../../skills/data/skill_tree_models.dart';
import '../../skills/data/skill_tree_repository.dart';
import '../../skills/presentation/curriculum_learning_screen.dart';
import '../../skills/presentation/skill_ui.dart';

final assessmentPracticeProvider = FutureProvider.autoDispose
    .family<SkillTreeResponse, (String, int)>((ref, key) {
      final revision = ref.watch(studyRevisionProvider);
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null) throw StateError('Not authenticated');
      return ref
          .watch(skillTreeRepositoryProvider)
          .getTree(
            userId: uid,
            subjectSlug: key.$1,
            grade: key.$2,
            revision: revision,
          );
    });

/// Review reuses the existing lesson and its authoritative once-only XP rule.
/// No fabricated daily tests or Biology questions are served as another subject.
class AssessmentPracticeScreen extends ConsumerWidget {
  const AssessmentPracticeScreen({
    super.key,
    required this.subject,
    required this.onOpenLearning,
  });
  final SkillSubject subject;
  final VoidCallback onOpenLearning;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    String tr(String uz, String ru, String en) => str3(language, uz, ru, en);
    final selected = ref.watch(selectedCurriculumGradeProvider(subject.slug));
    final grade = subject.grades.contains(selected)
        ? selected!
        : subject.grades.first;
    final tree = ref.watch(assessmentPracticeProvider((subject.slug, grade)));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(tr('Mashq', 'Практика', 'Practice')),
      ),
      body: IlmReadingWidth(
        child: tree.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(
                assessmentPracticeProvider((subject.slug, grade)),
              ),
              child: Text(tr('Qayta urinish', 'Повторить', 'Retry')),
            ),
          ),
          data: (value) {
            final completed = value.units
                .expand((u) => u.lessons)
                .where((l) => l.status == LessonStatus.completed)
                .toList();
            final c = Theme.of(context).extension<AppColors>()!.colors;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Hero banner, Duolingo practice-hub style.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6754D4), Color(0xFF8B7CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF4A3AA8), offset: Offset(0, 5)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(
                                  'Bilimingizni mustahkamlang',
                                  'Закрепите знания',
                                  'Make your knowledge stick',
                                ),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                str3(
                                  language,
                                  '${subject.nameFor(language)} · $grade-sinf',
                                  '${subject.nameFor(language)} · $grade класс',
                                  '${subject.nameFor(language)} · Grade $grade',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const ExcludeSemantics(
                          child: AnimatedIlmo(
                            pose: MascotPose.thinking,
                            size: 120,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (completed.isEmpty) ...[
                  Text(
                    tr(
                      'Avval birinchi darsni yakunlang. Bajarilgan darslar shu yerda takrorlash uchun paydo bo‘ladi.',
                      'Сначала завершите первый урок. Здесь появятся уроки для повторения.',
                      'Complete your first lesson. Finished lessons will appear here for review.',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onOpenLearning,
                    child: Text(
                      tr('Darslarga o‘tish', 'К урокам', 'Go to lessons'),
                    ),
                  ),
                ],
                if (completed.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      tr(
                        'Takrorlash uchun darslar',
                        'Уроки для повторения',
                        'Lessons to review',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                for (final lesson in completed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: c.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: c.border, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.primary.withValues(alpha: .16),
                          ),
                          child: Icon(Icons.replay_rounded, color: c.primary),
                        ),
                        title: Text(
                          lesson.titleFor(language),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: lesson.stars > 0
                            ? Row(
                                children: [
                                  for (var i = 0; i < 3; i++)
                                    Icon(
                                      i < lesson.stars
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 18,
                                      color: i < lesson.stars
                                          ? c.warning
                                          : c.textMuted,
                                    ),
                                ],
                              )
                            : null,
                        trailing: Icon(Icons.chevron_right, color: c.primary),
                        onTap: () =>
                            context.push('/skills/lesson', extra: lesson),
                      ),
                    ),
                  ),
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                    decoration: BoxDecoration(
                      color: c.warning.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: c.warning.withValues(alpha: .45),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_rounded, color: c.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tr(
                                  'Yulduzi kam darslarni qayta ishlang va 3 yulduzga chiqaring. Yangi darslar o‘quv yo‘lida.',
                                  'Повторите уроки с малым числом звёзд и доведите их до трёх. Новые уроки ждут на учебном пути.',
                                  'Replay lessons with fewer stars to reach three. New lessons wait on your learning path.',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: onOpenLearning,
                            icon: const Icon(Icons.route_rounded),
                            label: Text(
                              tr(
                                'O‘quv yo‘liga',
                                'К учебному пути',
                                'To the learning path',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
