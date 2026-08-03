import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
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
        title: Text(_tr(lang, 'Lug\'at', 'Словарь', 'Vocabulary'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _lookup(),
                decoration: InputDecoration(
                  hintText: _tr(lang, 'So\'zni kiriting (ingliz)', 'Введите слово (англ.)', 'Enter a word'),
                  filled: true, fillColor: colors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _busy ? null : () => _lookup(),
              style: IconButton.styleFrom(backgroundColor: colors.primary),
              icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search_rounded, color: Colors.white),
            ),
          ]),
        ),
        Expanded(
          child: _def == null && !_notFound
              ? _buildStarredView(colors, lang)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    if (_notFound)
                      Padding(padding: const EdgeInsets.all(20), child: Text(_tr(lang, 'So\'z topilmadi.', 'Слово не найдено.', 'Word not found.'), style: TextStyle(color: colors.textSecondary)))
                    else if (_def != null) ...[
                      Row(children: [
                        Expanded(child: Text(_def!.word, style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.w900))),
                        IconButton(
                          onPressed: _toggleStar,
                          icon: Icon(_isStarred ? Icons.star_rounded : Icons.star_border_rounded, color: _isStarred ? const Color(0xFFF59E0B) : colors.textSecondary),
                        ),
                      ]),
                      if (_def!.phonetic != null && _def!.phonetic!.isNotEmpty)
                        Text(_def!.phonetic!, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 12),
                      ..._def!.senses.map((s) => _senseCard(s, colors)),
                      if (_examples.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_tr(lang, 'IELTS matnlaridan misollar', 'Примеры из IELTS', 'Examples from IELTS passages'), style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ..._examples.map((e) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(e.sentence, style: TextStyle(color: colors.text, fontSize: 13, height: 1.4)),
                                const SizedBox(height: 4),
                                Text(e.source, style: TextStyle(color: colors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
                              ]),
                            )),
                      ],
                    ],
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _senseCard(VocabSense s, ThemeColors colors) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (s.partOfSpeech != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(s.partOfSpeech!, style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 8),
          Text(s.definition, style: TextStyle(color: colors.text, fontSize: 14, height: 1.4)),
          if (s.example != null && s.example!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"${s.example}"', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
          ],
          if (s.synonyms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: s.synonyms.map((syn) => GestureDetector(
                  onTap: () => _lookup(syn),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
                    child: Text(syn, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ),
                )).toList()),
          ],
        ]),
      );

  Widget _buildStarredView(ThemeColors colors, String lang) {
    if (_starred.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.menu_book_rounded, size: 44, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(_tr(lang, 'So\'z qidirib, yulduzcha bilan saqlang.', 'Ищите слова и сохраняйте звёздочкой.', 'Search words and star them to build your list.'),
                textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
          ]),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text('⭐ ${_tr(lang, 'Saqlangan so\'zlar', 'Сохранённые слова', 'My starred words')}', style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _starred.map((s) => ActionChip(
              label: Text(s.word, style: TextStyle(color: colors.text, fontSize: 13)),
              backgroundColor: colors.card,
              side: BorderSide(color: colors.border),
              onPressed: () => _lookup(s.word),
            )).toList()),
      ],
    );
  }
}
