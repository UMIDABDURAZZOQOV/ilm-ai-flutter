import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/skill_tree_models.dart';
import 'skill_ui.dart';
import 'subject_grade_card.dart';

class SubjectSelection {
  const SubjectSelection(this.subject, this.grade);
  final SkillSubject subject;
  final int grade;
}

Future<SubjectSelection?> showSubjectSwitcher(
  BuildContext context, {
  required List<SkillSubject> subjects,
  required String language,
  required int grade,
  required String? currentSubject,
}) => showModalBottomSheet<SubjectSelection>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .8,
    // Availability feedback belongs above this modal, not on the obscured
    // underlying page. It does not select a subject or write preferences.
    child: ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
        body: _SubjectSwitcher(
          subjects: subjects,
          language: language,
          grade: grade,
          currentSubject: currentSubject,
        ),
      ),
    ),
  ),
);

class _SubjectSwitcher extends StatefulWidget {
  const _SubjectSwitcher({
    required this.subjects,
    required this.language,
    required this.grade,
    required this.currentSubject,
  });
  final List<SkillSubject> subjects;
  final String language;
  final int grade;
  final String? currentSubject;
  @override
  State<_SubjectSwitcher> createState() => _SubjectSwitcherState();
}

class _SubjectSwitcherState extends State<_SubjectSwitcher> {
  late int _grade = widget.grade >= 5 && widget.grade <= 11 ? widget.grade : 5;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String tr(String uz, String ru, String en) =>
      str3(widget.language, uz, ru, en);
  @override
  Widget build(BuildContext context) {
    final gradeChips = Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      // The same grade chips as onboarding; every grade stays visible.
      child: Wrap(
        key: const ValueKey('switch_grade'),
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var grade = 5; grade <= 11; grade++)
            _GradeChip(
              key: ValueKey('switch_grade_$grade'),
              label: tr('$grade-sinf', '$grade класс', 'Grade $grade'),
              selected: grade == _grade,
              onTap: () {
                if (grade == _grade) return;
                setState(() => _grade = grade);
                if (_scroll.hasClients) _scroll.jumpTo(0);
              },
            ),
        ],
      ),
    );
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              tr(
                'Fan va sinfni tanlang',
                'Выберите предмет и класс',
                'Choose subject and grade',
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              // Keep cards off the screen edges; a narrower gutter keeps
              // tall 200%-text cards tappable on small phones.
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              // Grade chips scroll with the list, so 200% text still fits.
              itemCount: widget.subjects.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) return gradeChips;
                final subject = widget.subjects[index - 1];
                return SubjectGradeCard(
                  key: ValueKey('switch_${subject.slug}'),
                  subject: subject,
                  grade: _grade,
                  language: widget.language,
                  selected:
                      subject.slug == widget.currentSubject &&
                      _grade == widget.grade,
                  onSelected: () =>
                      Navigator.pop(context, SubjectSelection(subject, _grade)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? BrandPalette.turquoise.withValues(alpha: dark ? .2 : .12)
                  : colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? BrandPalette.turquoise : colors.border,
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? (dark ? Colors.white : const Color(0xFF0F766E))
                    : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
