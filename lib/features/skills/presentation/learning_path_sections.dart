import 'package:flutter/material.dart';

import '../../../core/theme/ilm_design.dart';
import '../data/skill_tree_models.dart';
import 'learning_journey_widgets.dart';
import 'skill_ui.dart';

/// Local navigation state only. Expanding a unit never changes lesson access.
class LearningPathSections extends StatefulWidget {
  const LearningPathSections({
    super.key,
    required this.storageKey,
    required this.language,
    required this.units,
    required this.leading,
    required this.itemBuilder,
    this.currentUnitId,
  });
  final String storageKey, language;
  final List<SkillTreeUnit> units;
  final int? currentUnitId;
  final Widget leading;
  final Widget Function(SkillTreeUnit unit, SkillTreeLesson? lesson)
  itemBuilder;

  @override
  State<LearningPathSections> createState() => _LearningPathSectionsState();
}

class _LearningPathSectionsState extends State<LearningPathSections> {
  final _expanded = <int, bool>{};
  final _scroll = ScrollController();
  int? _focusedUnit;

  @override
  void didUpdateWidget(covariant LearningPathSections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUnitId != widget.currentUnitId &&
        widget.currentUnitId != null) {
      _expanded[widget.currentUnitId!] = true;
      if (_focusedUnit == oldWidget.currentUnitId) {
        _focusedUnit = widget.currentUnitId;
      }
    }
    if (_focusedUnit != null &&
        !widget.units.any((u) => u.id == _focusedUnit)) {
      _focusedUnit = null;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _isExpanded(SkillTreeUnit unit) =>
      _expanded[unit.id] ??
      (widget.units.length == 1 ||
          unit.id == (widget.currentUnitId ?? widget.units.firstOrNull?.id));

  void _focus(int? id) {
    setState(() {
      _focusedUnit = id;
      if (id != null) _expanded[id] = true;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _chooseUnit() async {
    final language = widget.language;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  str3(
                    language,
                    'Bobga o‘tish',
                    'Перейти к разделу',
                    'Go to a section',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.units.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 68),
                  itemBuilder: (context, index) {
                    final unit = widget.units[index];
                    final done = unit.lessons
                        .where((l) => l.status == LessonStatus.completed)
                        .length;
                    return ListTile(
                      selected:
                          unit.id == (_focusedUnit ?? widget.currentUnitId),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('${index + 1}'),
                          ),
                        ),
                      ),
                      title: Text(unit.titleFor(language)),
                      subtitle: Text(
                        [
                          if (unit.lessons.isEmpty)
                            !unit.coverageComplete
                                ? str3(
                                    language,
                                    'Darslar tayyorlanmoqda',
                                    'Уроки готовятся',
                                    'Lessons in preparation',
                                  )
                                : str3(
                                    language,
                                    'Hozircha darslar yo‘q',
                                    'Пока нет уроков',
                                    'No lessons yet',
                                  )
                          else
                            str3(
                              language,
                              '$done/${unit.lessons.length} dars bajarilgan',
                              '$done/${unit.lessons.length} уроков пройдено',
                              '$done/${unit.lessons.length} lessons completed',
                            ),
                          if (unit.id == widget.currentUnitId)
                            str3(
                              language,
                              'Joriy bob',
                              'Текущий раздел',
                              'Current section',
                            ),
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, unit.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted ||
        selected == null ||
        !widget.units.any((u) => u.id == selected)) {
      return;
    }
    _focus(selected);
  }

  Widget _navigation() {
    final language = widget.language;
    final sections = str3(language, 'Boblar', 'Разделы', 'Sections');
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('path_sections'),
              onPressed: _focusedUnit == null
                  ? _chooseUnit
                  : () => _focus(null),
              icon: Icon(
                _focusedUnit == null
                    ? Icons.format_list_bulleted_rounded
                    : Icons.arrow_back_rounded,
                size: 20,
              ),
              label: Text(
                _focusedUnit == null
                    ? sections
                    : str3(
                        language,
                        'Barcha boblar',
                        'Все разделы',
                        'All sections',
                      ),
              ),
            ),
          ),
        ),
        if (_focusedUnit != null)
          IconButton(
            tooltip: sections,
            onPressed: _chooseUnit,
            icon: const Icon(Icons.format_list_bulleted_rounded),
          ),
        if (widget.currentUnitId != null &&
            _focusedUnit != widget.currentUnitId)
          IconButton(
            tooltip: str3(
              language,
              'Joriy bob',
              'Текущий раздел',
              'Current section',
            ),
            onPressed: () => _focus(widget.currentUnitId),
            icon: const Icon(Icons.my_location_rounded),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    final rows =
        <({SkillTreeUnit unit, SkillTreeLesson? lesson, bool header})>[];
    for (final unit in widget.units) {
      if (_focusedUnit != null && unit.id != _focusedUnit) continue;
      rows.add((unit: unit, lesson: null, header: true));
      if (!_isExpanded(unit)) continue;
      rows.addAll(
        unit.lessons.map(
          (lesson) => (unit: unit, lesson: lesson, header: false),
        ),
      );
      if (unit.examStatus != 'none') {
        rows.add((unit: unit, lesson: null, header: false));
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = ((constraints.maxWidth - IlmDesign.readingWidth) / 2)
            .clamp(16.0, double.infinity);
        return Column(
          children: [
            if (widget.units.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: _navigation(),
              ),
            Expanded(
              child: CustomScrollView(
                key: PageStorageKey(widget.storageKey),
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      12,
                      horizontal,
                      24,
                    ),
                    sliver: SliverList.builder(
                      itemCount: rows.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _focusedUnit == null
                              ? widget.leading
                              : const SizedBox.shrink();
                        }
                        final row = rows[index - 1];
                        if (!row.header) {
                          return widget.itemBuilder(row.unit, row.lesson);
                        }
                        final open = _isExpanded(row.unit);
                        return LearningUnitHeader(
                          key: ValueKey('section_${row.unit.id}'),
                          title: row.unit.titleFor(language),
                          language: language,
                          completed: row.unit.lessons
                              .where((l) => l.status == LessonStatus.completed)
                              .length,
                          total: row.unit.lessons.length,
                          coverageComplete: row.unit.coverageComplete,
                          expanded: open,
                          current: row.unit.id == widget.currentUnitId,
                          onToggle: () =>
                              setState(() => _expanded[row.unit.id] = !open),
                        );
                      },
                      findChildIndexCallback: (key) {
                        if (key is! ValueKey<String>) return null;
                        final index = rows.indexWhere(
                          (row) =>
                              row.header &&
                              key.value == 'section_${row.unit.id}',
                        );
                        return index < 0 ? null : index + 1;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
