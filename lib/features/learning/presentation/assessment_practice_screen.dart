import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/mascot_image.dart';
import '../../auth/application/auth_controller.dart';
import '../../skills/data/skill_tree_models.dart';
import '../../skills/data/skill_tree_repository.dart';
import '../../skills/presentation/curriculum_learning_screen.dart';
import '../../skills/presentation/skill_ui.dart';

final assessmentPracticeProvider = FutureProvider.autoDispose
    .family<SkillTreeResponse, (String, int)>((ref, key) {
      ref.watch(studyRevisionProvider);
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null) throw StateError('Not authenticated');
      return ref
          .watch(skillTreeRepositoryProvider)
          .getTree(userId: uid, subjectSlug: key.$1, grade: key.$2);
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
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  tr(
                    'Bilimingizni mustahkamlang',
                    'Закрепите знания',
                    'Make your knowledge stick',
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('${subject.nameFor(language)} · $grade'),
                const MascotImage(pose: MascotPose.thinking, size: 96),
                if (completed.isEmpty) ...[
                  Text(
                    tr(
                      'Avval birinchi darsni yakunlang. Bajarilgan darslar shu yerda takrorlash uchun paydo bo‘ladi.',
                      'Сначала завершите первый урок. Здесь появятся уроки для повторения.',
                      'Complete your first lesson. Finished lessons will appear here for review.',
                    ),
                  ),
                  FilledButton(
                    onPressed: onOpenLearning,
                    child: Text(
                      tr('Darslarga o‘tish', 'К урокам', 'Go to lessons'),
                    ),
                  ),
                ],
                for (final lesson in completed)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.replay_rounded),
                      title: Text(lesson.titleFor(language)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/skills/lesson', extra: lesson),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
