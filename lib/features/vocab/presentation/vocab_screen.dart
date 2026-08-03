import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/vocab_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class VocabScreen extends ConsumerStatefulWidget {
  const VocabScreen({super.key});
  @override
  ConsumerState<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends ConsumerState<VocabScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  VocabDefinition? _def;
  List<VocabExample> _examples = [];
  List<StarredWord> _starred = [];
  bool _notFound = false;

  @override
  void initState() { super.initState(); _loadStarred(); }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadStarred() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final s = await ref.read(vocabRepositoryProvider).listStarred(userId);
      if (mounted) setState(() => _starred = s);
    } catch (_) {}
  }

  bool get _isStarred => _def != null && _starred.any((s) => s.word == _def!.word.toLowerCase());

  Future<void> _lookup([String? preset]) async {
    final word = (preset ?? _ctrl.text).trim();
    if (word.isEmpty || _busy) return;
    if (preset != null) _ctrl.text = preset;
    setState(() { _busy = true; _notFound = false; _def = null; _examples = []; });
    final repo = ref.read(vocabRepositoryProvider);
    try {
      final def = await repo.define(word);
      List<VocabExample> ex = [];
      try { ex = await repo.examples(word); } catch (_) {}
      if (mounted) setState(() { _def = def; _examples = ex; _notFound = !def.found; });
    } catch (_) {
      if (mounted) setState(() => _notFound = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleStar() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _def == null) return;
    final w = _def!.word.toLowerCase();
    final repo = ref.read(vocabRepositoryProvider);
    if (_isStarred) {
      await repo.unstar(userId, w);
      setState(() => _starred.removeWhere((s) => s.word == w));
    } else {
      await repo.star(userId, w);
      setState(() => _starred.insert(0, StarredWord(word: w)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'Lug\'at', 'Словарь', 'Vocabulary'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _lookup(),
                style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: _tr(lang, 'So\'zni kiriting (ingliz)', 'Введите слово (англ.)', 'Enter a word'),
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                  filled: true, fillColor: colors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            PremiumIconButton(
              onPressed: _busy ? null : () => _lookup(),
              icon: _busy ? Icons.hourglass_empty : Icons.search_rounded,
              iconColor: Colors.white,
              backgroundColor: colors.primary,
              size: 52,
              borderRadius: 16,
            ),
          ]),
        ),
        Expanded(
          child: _def == null && !_notFound
              ? _buildStarredView(colors, lang)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    if (_notFound)
                      Padding(padding: const EdgeInsets.all(24), child: Text(_tr(lang, 'So\'z topilmadi.', 'Слово не найдено.', 'Word not found.'), style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)))
                    else if (_def != null) ...[
                      Row(children: [
                        Expanded(child: Text(_def!.word, style: TextStyle(color: colors.text, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
                        const SizedBox(width: 8),
                        AnimatedPressable(
                          onTap: _toggleStar,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isStarred ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : colors.border.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(_isStarred ? Icons.star_rounded : Icons.star_border_rounded, color: _isStarred ? const Color(0xFFF59E0B) : colors.textSecondary, size: 24),
                          ),
                        ),
                      ]),
                      if (_def!.phonetic != null && _def!.phonetic!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_def!.phonetic!, style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      const SizedBox(height: 16),
                      ..._def!.senses.asMap().entries.map((entry) => _senseCard(entry.value, colors, entry.key)),
                      if (_examples.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(_tr(lang, 'IELTS matnlaridan misollar', 'Примеры из IELTS', 'Examples from IELTS passages'), style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                        const SizedBox(height: 12),
                        ..._examples.asMap().entries.map((entry) => PremiumCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              borderRadius: 16,
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(entry.value.sentence, style: TextStyle(color: colors.text, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Text(entry.value.source, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                              ]),
                            ).animate().fadeIn(delay: (entry.key * 50).ms, duration: 300.ms)),
                      ],
                    ],
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _senseCard(VocabSense s, ThemeColors colors, int index) => PremiumCard(
        margin: const EdgeInsets.only(bottom: 14),
        borderRadius: 18,
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (s.partOfSpeech != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(s.partOfSpeech!, style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 12),
          Text(s.definition, style: TextStyle(color: colors.text, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
          if (s.example != null && s.example!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${s.example}"', style: TextStyle(color: colors.textSecondary, fontSize: 14, fontStyle: FontStyle.italic)),
          ],
          if (s.synonyms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: s.synonyms.asMap().entries.map((synEntry) => AnimatedPressable(
                  onTap: () => _lookup(synEntry.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.border)),
                    child: Text(synEntry.value, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                )).toList()),
          ],
        ]),
      ).animate().fadeIn(delay: (index * 60).ms, duration: 350.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);

  Widget _buildStarredView(ThemeColors colors, String lang) {
    if (_starred.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.menu_book_rounded, size: 40, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(_tr(lang, 'So\'z qidirib, yulduzcha bilan saqlang.', 'Ищите слова и сохраняйте звёздочкой.', 'Search words and star them to build your list.'),
                textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(_tr(lang, 'Saqlangan so\'zlar', 'Сохранённые слова', 'My starred words'), style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: _starred.asMap().entries.map((entry) => AnimatedPressable(
              onTap: () => _lookup(entry.value.word),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                child: Text(entry.value.word, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ).animate().fadeIn(delay: (entry.key * 40).ms, duration: 300.ms)).toList()),
      ],
    );
  }
}
