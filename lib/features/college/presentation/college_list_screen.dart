import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_loading.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t('college.title', language), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: t('college.search.placeholder', language),
                      hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: colors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<_Region>(
                    segments: [
                      ButtonSegment(value: _Region.all, label: Text(t('college.region.all', language))),
                      ButtonSegment(value: _Region.us, label: Text(t('college.region.us', language))),
                      ButtonSegment(value: _Region.europe, label: Text(t('college.region.europe', language))),
                    ],
                    selected: {_region},
                    onSelectionChanged: (s) => setState(() => _region = s.first),
                  ),
                  const SizedBox(height: 12),
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
                    PremiumCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('college.sort.label', language), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.textSecondary)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _FilterChip(label: t('college.sort.top', language), selected: _sort == _SortBy.top, onTap: () => setState(() => _sort = _SortBy.top), colors: colors),
                              _FilterChip(label: t('college.sort.name', language), selected: _sort == _SortBy.name, onTap: () => setState(() => _sort = _SortBy.name), colors: colors),
                              _FilterChip(label: t('college.sort.acc', language), selected: _sort == _SortBy.acceptance, onTap: () => setState(() => _sort = _SortBy.acceptance), colors: colors),
                              _FilterChip(label: t('college.sort.sat', language), selected: _sort == _SortBy.sat, onTap: () => setState(() => _sort = _SortBy.sat), colors: colors),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(t('college.type.label', language), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.textSecondary)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: [
                              _FilterChip(label: t('college.type.all', language), selected: _typeFilter == _TypeFilter.all, onTap: () => setState(() => _typeFilter = _TypeFilter.all), colors: colors),
                              _FilterChip(label: t('college.type.public', language), selected: _typeFilter == _TypeFilter.public, onTap: () => setState(() => _typeFilter = _TypeFilter.public), colors: colors),
                              _FilterChip(label: t('college.type.private', language), selected: _typeFilter == _TypeFilter.private, onTap: () => setState(() => _typeFilter = _TypeFilter.private), colors: colors),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(t('college.acceptance.label', language), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.textSecondary)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
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
                        style: TextStyle(color: colors.textMuted, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(t('college.showing', language).replaceAll('{n}', '${list.length}'), style: TextStyle(fontSize: 13, color: colors.textMuted, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final c = list[i];
                            final isSaved = saved.contains(c.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AnimatedPressable(
                                onTap: () => context.push('/profile/college/${c.id}'),
                                child: PremiumCard(
                                  borderRadius: 18,
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CollegeLogo(college: c, size: 48, fontSize: 15),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c.name, style: TextStyle(fontWeight: FontWeight.w800, color: colors.text, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text('${c.city}${c.state.isNotEmpty ? ', ${c.state}' : ''}', style: TextStyle(fontSize: 13, color: colors.textMuted, fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                if (c.acceptanceRate != null) Text('${t('college.card.acceptance', language)}: ${c.acceptanceRate}%', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600)),
                                                if (c.medianSAT != null) ...[
                                                  const SizedBox(width: 12),
                                                  Text('SAT: ${c.medianSAT}', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600)),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedPressable(
                                        onTap: () => ref.read(savedCollegesProvider.notifier).toggle(c.id),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isSaved ? colors.primary.withValues(alpha: 0.1) : colors.border.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? colors.primary : colors.textMuted, size: 22),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: (i * 30).ms, duration: 300.ms);
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: PremiumLoading()),
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
