import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../data/college_repository.dart';
import '../data/college_saved.dart';
import 'college_logo.dart';

enum _Region { all, us, europe }

enum _SortBy { top, name, acceptance, sat }

enum _TypeFilter { all, public, private }

enum _AcceptanceFilter { all, under25, from25to50, over50 }

/// Full filter panel (region/saved/search/sort/type/acceptance band) + a
/// virtualized ListView.builder, matching ilm-ai-mobile's CollegeListScreen.
class CollegeListScreen extends ConsumerStatefulWidget {
  const CollegeListScreen({super.key});

  @override
  ConsumerState<CollegeListScreen> createState() => _CollegeListScreenState();
}

class _CollegeListScreenState extends ConsumerState<CollegeListScreen> {
  _Region _region = _Region.all;
  bool _savedOnly = false;
  _SortBy _sort = _SortBy.top;
  _TypeFilter _typeFilter = _TypeFilter.all;
  _AcceptanceFilter _acceptanceFilter = _AcceptanceFilter.all;
  bool _filterPanelOpen = false;
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final collegesAsync = ref.watch(allCollegesProvider);
    final saved = ref.watch(savedCollegesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('college.title', language))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: t('college.search.placeholder', language),
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: colors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<_Region>(
                    segments: [
                      ButtonSegment(value: _Region.all, label: Text(t('college.region.all', language))),
                      ButtonSegment(value: _Region.us, label: Text(t('college.region.us', language))),
                      ButtonSegment(value: _Region.europe, label: Text(t('college.region.europe', language))),
                    ],
                    selected: {_region},
                    onSelectionChanged: (s) => setState(() => _region = s.first),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ChoiceChip(label: Text(t('college.tab.all', language)), selected: !_savedOnly, onSelected: (_) => setState(() => _savedOnly = false)),
                      const SizedBox(width: 8),
                      ChoiceChip(label: Text(t('college.tab.saved', language)), selected: _savedOnly, onSelected: (_) => setState(() => _savedOnly = true)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setState(() => _filterPanelOpen = !_filterPanelOpen),
                        icon: AnimatedRotation(
                          turns: _filterPanelOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: Icon(_filterPanelOpen ? Icons.keyboard_arrow_up_rounded : Icons.tune_rounded, size: 20),
                        ),
                        label: Text(t('college.filter.button', language)),
                      ),
                    ],
                  ),
                  if (_filterPanelOpen)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('college.sort.label', language), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FilterChip(label: t('college.sort.top', language), selected: _sort == _SortBy.top, onTap: () => setState(() => _sort = _SortBy.top), colors: colors),
                              _FilterChip(label: t('college.sort.name', language), selected: _sort == _SortBy.name, onTap: () => setState(() => _sort = _SortBy.name), colors: colors),
                              _FilterChip(label: t('college.sort.acc', language), selected: _sort == _SortBy.acceptance, onTap: () => setState(() => _sort = _SortBy.acceptance), colors: colors),
                              _FilterChip(label: t('college.sort.sat', language), selected: _sort == _SortBy.sat, onTap: () => setState(() => _sort = _SortBy.sat), colors: colors),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(t('college.type.label', language), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _FilterChip(label: t('college.type.all', language), selected: _typeFilter == _TypeFilter.all, onTap: () => setState(() => _typeFilter = _TypeFilter.all), colors: colors),
                              _FilterChip(label: t('college.type.public', language), selected: _typeFilter == _TypeFilter.public, onTap: () => setState(() => _typeFilter = _TypeFilter.public), colors: colors),
                              _FilterChip(label: t('college.type.private', language), selected: _typeFilter == _TypeFilter.private, onTap: () => setState(() => _typeFilter = _TypeFilter.private), colors: colors),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(t('college.acceptance.label', language), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FilterChip(label: t('college.type.all', language), selected: _acceptanceFilter == _AcceptanceFilter.all, onTap: () => setState(() => _acceptanceFilter = _AcceptanceFilter.all), colors: colors),
                              _FilterChip(label: t('college.acceptance.under25', language), selected: _acceptanceFilter == _AcceptanceFilter.under25, onTap: () => setState(() => _acceptanceFilter = _AcceptanceFilter.under25), colors: colors),
                              _FilterChip(label: t('college.acceptance.25to50', language), selected: _acceptanceFilter == _AcceptanceFilter.from25to50, onTap: () => setState(() => _acceptanceFilter = _AcceptanceFilter.from25to50), colors: colors),
                              _FilterChip(label: t('college.acceptance.50plus', language), selected: _acceptanceFilter == _AcceptanceFilter.over50, onTap: () => setState(() => _acceptanceFilter = _AcceptanceFilter.over50), colors: colors),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: collegesAsync.when(
                data: (all) {
                  var list = all.where((c) {
                    if (_region == _Region.us && c.region != 'US') return false;
                    if (_region == _Region.europe && c.region != 'EU') return false;
                    if (_savedOnly && !saved.contains(c.id)) return false;
                    if (_typeFilter == _TypeFilter.public && !c.type.toLowerCase().contains('public')) return false;
                    if (_typeFilter == _TypeFilter.private && !c.type.toLowerCase().contains('private')) return false;
                    if (_acceptanceFilter != _AcceptanceFilter.all) {
                      final rate = c.acceptanceRate;
                      if (rate == null) return false;
                      if (_acceptanceFilter == _AcceptanceFilter.under25 && rate >= 25) return false;
                      if (_acceptanceFilter == _AcceptanceFilter.from25to50 && (rate < 25 || rate > 50)) return false;
                      if (_acceptanceFilter == _AcceptanceFilter.over50 && rate <= 50) return false;
                    }
                    final q = _search.text.trim().toLowerCase();
                    if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
                    return true;
                  }).toList();

                  switch (_sort) {
                    case _SortBy.name:
                      list.sort((a, b) => a.name.compareTo(b.name));
                      break;
                    case _SortBy.acceptance:
                      list.sort((a, b) => (a.acceptanceRate ?? 999).compareTo(b.acceptanceRate ?? 999));
                      break;
                    case _SortBy.sat:
                      list.sort((a, b) => (b.medianSAT ?? 0).compareTo(a.medianSAT ?? 0));
                      break;
                    case _SortBy.top:
                      list.sort((a, b) => (a.acceptanceRate ?? 999).compareTo(b.acceptanceRate ?? 999));
                      break;
                  }

                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        _savedOnly ? t('college.empty.saved', language) : t('college.empty.search', language),
                        style: TextStyle(color: colors.textMuted),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(t('college.showing', language).replaceAll('{n}', '${list.length}'), style: TextStyle(fontSize: 12, color: colors.textMuted)),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: list.length,
                          // Virtualized by default via ListView.builder -- Flutter doesn't
                          // need the manual pagination workaround the RN-web version used.
                          itemBuilder: (context, i) {
                            final c = list[i];
                            final isSaved = saved.contains(c.id);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: AnimatedPressable(
                                onTap: () => context.push('/profile/college/${c.id}'),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                                  child: Row(
                                    children: [
                                      CollegeLogo(college: c, size: 44, fontSize: 14),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c.name, style: TextStyle(fontWeight: FontWeight.w700, color: colors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text('${c.city}${c.state.isNotEmpty ? ', ${c.state}' : ''}', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (c.acceptanceRate != null) Text('${t('college.card.acceptance', language)}: ${c.acceptanceRate}%', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                                                if (c.medianSAT != null) ...[
                                                  const SizedBox(width: 10),
                                                  Text('SAT: ${c.medianSAT}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? colors.primary : colors.textMuted),
                                        onPressed: () => ref.read(savedCollegesProvider.notifier).toggle(c.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e', style: TextStyle(color: colors.error))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeColors colors;
  const _FilterChip({required this.label, required this.selected, required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : colors.text, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
