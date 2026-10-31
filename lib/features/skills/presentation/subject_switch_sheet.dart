import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/skill_tree_models.dart';
import 'skill_ui.dart';

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
  builder: (_) => _SubjectSwitcher(
    subjects: subjects,
    language: language,
    grade: grade,
    currentSubject: currentSubject,
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
    final colors = Theme.of(context).extension<AppColors>()!.colors;
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DropdownButtonFormField<int>(
              key: const ValueKey('switch_grade'),
              initialValue: _grade,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: tr('Sinf', 'Класс', 'Grade'),
              ),
              items: [
                for (var grade = 5; grade <= 11; grade++)
                  DropdownMenuItem(
                    value: grade,
                    child: Text(
                      tr('$grade-sinf', '$grade класс', 'Grade $grade'),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _grade = value);
                  if (_scroll.hasClients) _scroll.jumpTo(0);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              itemCount: widget.subjects.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
              itemBuilder: (context, index) {
                final subject = widget.subjects[index];
                final enabled =
                    subject.available && subject.grades.contains(_grade);
                final selected =
                    subject.slug == widget.currentSubject &&
                    _grade == widget.grade;
                final hint = !subject.available
                    ? tr('Tez kunda', 'Скоро', 'Coming soon')
                    : !enabled
                    ? tr(
                        '${subject.grades.join(', ')}-sinflarda mavjud',
                        'Доступные классы: ${subject.grades.join(', ')}',
                        'Available grades: ${subject.grades.join(', ')}',
                      )
                    : selected
                    ? tr('Hozirgi fan', 'Текущий предмет', 'Current subject')
                    : null;
                return ListTile(
                  key: ValueKey('switch_${subject.slug}'),
                  enabled: enabled,
                  selected: selected,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  leading: Icon(
                    subjectIcons[subject.slug] ?? Icons.menu_book_rounded,
                    color: enabled
                        ? skillColor(subject.color)
                        : colors.textSecondary,
                  ),
                  title: Text(subject.nameFor(widget.language)),
                  subtitle: hint == null ? null : Text(hint),
                  trailing: selected
                      ? const Icon(Icons.check_circle_rounded)
                      : enabled
                      ? const Icon(Icons.chevron_right_rounded)
                      : const Icon(Icons.lock_outline_rounded),
                  onTap: enabled
                      ? () => Navigator.pop(
                          context,
                          SubjectSelection(subject, _grade),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
