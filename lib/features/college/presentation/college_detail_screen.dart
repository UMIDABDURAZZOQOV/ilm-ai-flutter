import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/charts/bell_curve_painter.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../data/college_models.dart';
import '../data/college_repository.dart';
import '../data/college_saved.dart';
import 'college_logo.dart';

enum _DetailTab { admissions, academics, students }

class CollegeDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const CollegeDetailScreen({super.key, required this.id});

  @override
  ConsumerState<CollegeDetailScreen> createState() => _CollegeDetailScreenState();
}

class _CollegeDetailScreenState extends ConsumerState<CollegeDetailScreen> {
  _DetailTab _tab = _DetailTab.admissions;
  final Set<int> _expandedFaq = {};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final collegesAsync = ref.watch(allCollegesProvider);
    final saved = ref.watch(savedCollegesProvider);

    return Scaffold(
      body: collegesAsync.when(
        data: (all) {
          College? college;
          for (final c in all) {
            if (c.id == widget.id) {
              college = c;
              break;
            }
          }
          if (college == null) {
            return SafeArea(child: Center(child: Text(t('college.detail.not.found', language))));
          }
          final c = college;
          final isSaved = saved.contains(c.id);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    CollegeLogo(college: c, size: 48, fontSize: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: colors.text)),
                          if (c.aka != null) Text('${t('college.detail.also.known', language)}: ${c.aka}', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? colors.primary : colors.textMuted, size: 26),
                      onPressed: () => ref.read(savedCollegesProvider.notifier).toggle(c.id),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${c.city}${c.state.isNotEmpty ? ', ${c.state}' : ''}, ${c.country}', style: TextStyle(color: colors.textSecondary)),
                const SizedBox(height: 20),

                if (c.medianSAT != null) ...[
                  Text(t('college.detail.scores', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
                    child: Column(
                      children: [
                        Center(child: BellCurveChart(medianSat: c.medianSAT!)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${t('college.detail.sat.median', language)}: ${c.medianSAT}', style: TextStyle(fontWeight: FontWeight.w700, color: colors.primary)),
                            if (c.medianACT != null) ...[
                              const SizedBox(width: 16),
                              Text('${t('college.detail.act.median', language)}: ${c.medianACT}', style: TextStyle(fontWeight: FontWeight.w700, color: colors.secondary)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(t('college.detail.sat.na', language), style: TextStyle(color: colors.textMuted, fontStyle: FontStyle.italic)),
                  ),

                // Tabs
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                  child: Row(
                    children: [
                      for (final tab in _DetailTab.values)
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _tab = tab),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _tab == tab ? colors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tab == _DetailTab.admissions
                                    ? t('college.detail.tab.admissions', language)
                                    : tab == _DetailTab.academics
                                        ? t('college.detail.tab.academics', language)
                                        : t('college.detail.tab.students', language),
                                style: TextStyle(color: _tab == tab ? Colors.white : colors.text, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildTabContent(c, colors, language),

                const SizedBox(height: 20),
                if (c.professors.isNotEmpty) ...[
                  Text(t('college.detail.professors.title', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: c.professors.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5),
                    itemBuilder: (context, i) {
                      final p = c.professors[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: TextStyle(fontWeight: FontWeight.w700, color: colors.text, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(p.field, style: TextStyle(fontSize: 11, color: colors.primary)),
                            if (p.note != null) ...[
                              const SizedBox(height: 4),
                              Text(p.note!, style: TextStyle(fontSize: 11, color: colors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(t('college.detail.professors.empty', language), style: TextStyle(color: colors.textMuted, fontSize: 13)),
                  ),

                if (c.website != null)
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(c.website!), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(t('college.detail.visit.website', language)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: colors.border)),
                  ),
                const SizedBox(height: 20),

                // FAQ accordion (generic guidance content, not college-specific)
                Text(t('college.detail.faq.title', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                const SizedBox(height: 10),
                for (var i = 0; i < _genericFaq(language).length; i++) _FaqTile(
                  index: i,
                  question: _genericFaq(language)[i].$1,
                  answer: _genericFaq(language)[i].$2,
                  expanded: _expandedFaq.contains(i),
                  colors: colors,
                  onTap: () => setState(() => _expandedFaq.contains(i) ? _expandedFaq.remove(i) : _expandedFaq.add(i)),
                ),

                const SizedBox(height: 20),
                Text(t('college.detail.disclaimer', language), style: TextStyle(fontSize: 11, color: colors.textMuted, height: 1.4)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SafeArea(child: Center(child: Text('$e'))),
      ),
    );
  }

  Widget _buildTabContent(College c, ThemeColors colors, String language) {
    switch (_tab) {
      case _DetailTab.admissions:
        return Column(
          children: [
            if (c.acceptanceRate != null) _StatRow(label: t('college.detail.acceptance.rate', language), value: '${c.acceptanceRate}%', pct: (100 - c.acceptanceRate!) / 100, colors: colors),
            if (c.yieldRate != null) _StatRow(label: t('college.detail.yield.rate', language), value: '${c.yieldRate}%', pct: c.yieldRate! / 100, colors: colors),
            if (c.testPolicy != null) _InfoLine(label: t('college.detail.test.policy', language), value: c.testPolicy!, colors: colors),
          ],
        );
      case _DetailTab.academics:
        return Column(
          children: [
            if (c.gpa != null) _InfoLine(label: t('college.detail.gpa', language), value: c.gpa!, colors: colors),
            _InfoLine(label: t('college.detail.institution.type', language), value: c.type, colors: colors),
            if (c.nobelAffiliated != null) _InfoLine(label: t('college.detail.nobel', language), value: '${c.nobelAffiliated}', colors: colors),
          ],
        );
      case _DetailTab.students:
        return Column(
          children: [
            if (c.size != null) _InfoLine(label: t('college.detail.undergrads', language), value: c.size!, colors: colors),
            if (c.setting != null) _InfoLine(label: t('college.detail.setting', language), value: c.setting!, colors: colors),
            _InfoLine(label: t('college.detail.location', language), value: '${c.city}, ${c.state}', colors: colors),
          ],
        );
    }
  }

  List<(String, String)> _genericFaq(String language) {
    if (language == 'uz') {
      return [
        ("Qabul darajasi nimani anglatadi?", "Qabul darajasi — arizachilarning qanchasi qabul qilinganini ko'rsatadi. Past foiz — universitet ancha tanlab qabul qilishini bildiradi."),
        ("SAT/ACT balim yetarli emas, ariza topshirsam bo'ladimi?", "Ha. Ko'plab universitetlar bir nechta omillarni (insho, tavsiyalar, faoliyat) hisobga oladi. O'rtacha ball faqat mo'ljal, talab emas."),
        ("Necha ta universitetga ariza topshirish tavsiya etiladi?", "Odatda 8-12 ta: bir nechtasi orzu (reach), bir nechtasi mos (match) va bir nechtasi ishonchli (safety) tanlovlar bo'lishi kerak."),
      ];
    }
    if (language == 'ru') {
      return [
        ("Что означает уровень приёма?", "Уровень приёма показывает долю принятых абитуриентов. Низкий процент означает более избирательный университет."),
        ("Можно ли подавать заявку с баллами ниже медианы?", "Да. Многие университеты учитывают эссе, рекомендации и внеучебную деятельность. Медиана — ориентир, а не требование."),
        ("Сколько университетов стоит выбрать?", "Обычно 8-12: несколько амбициозных, несколько подходящих и несколько надёжных вариантов."),
      ];
    }
    return [
      ("What does acceptance rate mean?", "Acceptance rate is the share of applicants who are admitted. A lower percentage means a more selective school."),
      ("Can I apply with scores below the median?", "Yes. Most schools weigh essays, recommendations, and activities too. The median is a guide, not a requirement."),
      ("How many colleges should I apply to?", "Typically 8-12: a mix of reach, match, and safety schools."),
    ];
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final double pct;
  final ThemeColors colors;
  const _StatRow({required this.label, required this.value, required this.pct, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(value, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct.clamp(0, 1), backgroundColor: colors.border, color: colors.primary, minHeight: 6),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors colors;
  const _InfoLine({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: colors.text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final int index;
  final String question;
  final String answer;
  final bool expanded;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _FaqTile({required this.index, required this.question, required this.answer, required this.expanded, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(child: Text(question, style: TextStyle(fontWeight: FontWeight.w600, color: colors.text, fontSize: 13))),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Align(alignment: Alignment.centerLeft, child: Text(answer, style: TextStyle(color: colors.textSecondary, fontSize: 12.5, height: 1.4))),
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
