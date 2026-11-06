import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/skill_tree_models.dart';
import 'skill_ui.dart';

/// Availability comes only from the server's grades with ready lesson content.
/// Missing metadata fails closed; grade changes never substitute another grade.
class SubjectGradeAvailability {
  SubjectGradeAvailability(this.subject, this.grade);
  final SkillSubject subject;
  final int? grade;

  bool get canStudy =>
      subject.available && grade != null && subject.grades.contains(grade);

  String label(String language) {
    String tr(String uz, String ru, String en) => str3(language, uz, ru, en);
    if (!subject.available || subject.grades.isEmpty) {
      return tr('Hozircha mavjud emas', 'Пока недоступно', 'Not available yet');
    }
    if (grade == null) {
      return tr('Sinfni tanlang', 'Выберите класс', 'Choose a grade');
    }
    if (canStudy) {
      return tr(
        '$grade-sinfda mavjud',
        'Доступно в $grade классе',
        'Available in grade $grade',
      );
    }
    final future = subject.grades.where((g) => g > grade!).toList()..sort();
    if (future.isNotEmpty) {
      final next = future.first;
      return tr(
        '$next-sinfda ochiladi',
        'Откроется в $next классе',
        'Opens in grade $next',
      );
    }
    final earlier = subject.grades.toSet().toList()..sort();
    final range = earlier.join(', ');
    return tr(
      'Avvalgi sinflarda mavjud: $range',
      'Доступно в предыдущих классах: $range',
      'Available in earlier grades: $range',
    );
  }
}

/// Shared by onboarding, the catalogue and the in-course subject switcher.
/// A locked tap explains availability without selecting or writing preferences.
class SubjectGradeCard extends StatelessWidget {
  const SubjectGradeCard({
    super.key,
    required this.subject,
    required this.grade,
    required this.language,
    required this.onSelected,
    this.selected = false,
  });

  final SkillSubject subject;
  final int? grade;
  final String language;
  final VoidCallback onSelected;
  final bool selected;

  bool get canStudy => SubjectGradeAvailability(subject, grade).canStudy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final availability = SubjectGradeAvailability(subject, grade);
    final open = availability.canStudy;
    final active = selected && open;
    final status = availability.label(language);
    final accent = open ? skillColor(subject.color) : colors.textSecondary;
    return Card(
      margin: EdgeInsets.zero,
      color: active ? colors.primary.withValues(alpha: .10) : colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: active ? colors.primary : colors.border,
          width: active ? 2 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 96),
        child: ListTile(
          selected: active,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          leading: CircleAvatar(
            backgroundColor: accent.withValues(alpha: .13),
            child: Icon(
              subjectIcons[subject.slug] ?? Icons.menu_book_rounded,
              color: accent,
            ),
          ),
          title: Text(
            subject.nameFor(language),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: open ? colors.text : colors.textSecondary,
            ),
          ),
          subtitle: Text(status, style: TextStyle(color: colors.textSecondary)),
          trailing: Icon(
            !open
                ? Icons.lock_outline_rounded
                : active
                ? Icons.check_circle_rounded
                : Icons.chevron_right_rounded,
            color: active ? colors.primary : colors.textSecondary,
          ),
          onTap: () {
            if (open) {
              onSelected();
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(status)));
            }
          },
        ),
      ),
    );
  }
}
