import '../../../core/config/integrated_beta.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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
    this.pageSize,
  });
  final String storageKey, language;
  final List<SkillTreeUnit> units;
  final int? currentUnitId;

  /// Presentation only: the source order and prerequisite rules stay intact.
  final int? pageSize;
  final Widget leading;
  final Widget Function(SkillTreeUnit unit, SkillTreeLesson? lesson)
  itemBuilder;

  @override
  State<LearningPathSections> createState() => _LearningPathSectionsState();
}

class _LearningPathSectionsState extends State<LearningPathSections> {
  final _expanded = <int, bool>{};
  final _pages = <int, int>{};
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
                            reviewedLearning
                                ? str3(
                                    language,
                                    '$done dars bajarilgan',
                                    'Пройдено уроков: $done',
                                    done == 1
                                        ? '1 lesson completed'
                                        : '$done lessons completed',
                                  )
                                : str3(
                                    language,
                                    '$done/${unit.lessons.length} dars bajarilgan',
                                    'Пройдено уроков: $done/${unit.lessons.length}',
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
      final size = widget.pageSize ?? unit.lessons.length;
      final current = unit.lessons.indexWhere(
        (l) => l.status == LessonStatus.unlocked,
      );
      final page = size > 0
          ? (_pages[unit.id] ?? (current < 0 ? 0 : current ~/ size))
          : 0;
      final visible = widget.pageSize == null
          ? unit.lessons
          : unit.lessons.skip(page * size).take(size);
      rows.addAll(
        visible.map((lesson) => (unit: unit, lesson: lesson, header: false)),
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
                        final header = LearningUnitHeader(
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
                        final size = widget.pageSize;
                        if (!open ||
                            size == null ||
                            row.unit.lessons.length <= size) {
                          return header;
                        }
                        final current = row.unit.lessons.indexWhere(
                          (l) => l.status == LessonStatus.unlocked,
                        );
                        final page =
                            _pages[row.unit.id] ??
                            (current < 0 ? 0 : current ~/ size);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            // Lesson ranges as pills, like Duolingo's section
                            // pickers, instead of a form dropdown in the path.
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Semantics(
                                label: str3(
                                  language,
                                  'Darslar oralig‘i',
                                  'Диапазон уроков',
                                  'Lesson range',
                                ),
                                child: SingleChildScrollView(
                                  key: ValueKey('lesson_range_${row.unit.id}'),
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (
                                        var p = 0;
                                        p * size < row.unit.lessons.length;
                                        p++
                                      )
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: _RangePill(
                                            label:
                                                '${p * size + 1}–${((p + 1) * size).clamp(1, row.unit.lessons.length)}${reviewedLearning ? '' : ' / ${row.unit.lessons.length}'}',
                                            selected: p == page,
                                            onTap: () => setState(
                                              () => _pages[row.unit.id] = p,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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

class _RangePill extends StatelessWidget {
  const _RangePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.primary : c.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? c.primary : c.border, width: 2),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? scheme.onPrimary : c.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
