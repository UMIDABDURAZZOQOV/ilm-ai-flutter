import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/decks_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class DecksScreen extends ConsumerStatefulWidget {
  const DecksScreen({super.key});
  @override
  ConsumerState<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends ConsumerState<DecksScreen> {
  List<DeckSummary>? _decks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final d = await ref.read(decksRepositoryProvider).listDecks(userId);
      if (mounted) setState(() => _decks = d);
    } catch (_) {
      if (mounted) setState(() => _decks = []);
    }
  }

  Future<void> _review(DeckSummary deck) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final due = await ref.read(decksRepositoryProvider).getDue(userId, deck.id);
    if (due.isEmpty || !mounted) return;
    final results = await Navigator.of(context).push<List<Map<String, dynamic>>>(
      MaterialPageRoute(builder: (_) => _ReviewScreen(title: deck.title, cards: due, lang: ref.read(languageProvider))),
    );
    if (results != null && results.isNotEmpty) {
      await ref.read(decksRepositoryProvider).review(userId, deck.id, results);
    }
    _load();
  }

  Future<void> _delete(DeckSummary deck) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(decksRepositoryProvider).deleteDeck(userId, deck.id);
    setState(() => _decks = _decks?.where((d) => d.id != deck.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: colors.text), onPressed: () => context.pop()),
        title: Text(_tr(lang, 'Flashcard to\'plamlari', 'Колоды карточек', 'Flashcard decks'),
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
      ),
      body: _decks == null
          ? const Center(child: CircularProgressIndicator())
          : _decks!.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      _tr(lang, 'Hali to\'plam yo\'q. Studio yoki companion kartochkalarini saqlang.',
                          'Пока нет колод. Сохраните карточки из Studio.',
                          'No decks yet. Save flashcards from Studio or the companion.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(_tr(lang, 'Muddati kelganlari birinchi.', 'Сначала карточки к повторению.', 'Due cards first.'),
                        style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
                    ..._decks!.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${d.total} ${_tr(lang, 'karta', 'карт', 'cards')}'
                                        '${d.due > 0 ? ' · ${d.due} ${_tr(lang, 'takror', 'к повтору', 'due')}' : ''}',
                                        style: TextStyle(color: d.due > 0 ? colors.primary : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                if (d.due > 0)
                                  ElevatedButton(
                                    onPressed: () => _review(d),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(_tr(lang, 'Takror', 'Повторить', 'Review')),
                                  ),
                                IconButton(
                                  onPressed: () => _delete(d),
                                  icon: Icon(Icons.delete_outline_rounded, color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
    );
  }
}

class _ReviewScreen extends StatefulWidget {
  final String title;
  final List<DueCard> cards;
  final String lang;
  const _ReviewScreen({required this.title, required this.cards, required this.lang});
  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  int _i = 0;
  bool _flipped = false;
  final List<Map<String, dynamic>> _results = [];

  void _grade(bool correct) {
    _results.add({'index': widget.cards[_i].index, 'correct': correct});
    if (_i + 1 >= widget.cards.length) {
      Navigator.of(context).pop(_results);
    } else {
      setState(() { _i++; _flipped = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final c = widget.cards[_i];
    final lang = widget.lang;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.close_rounded, color: colors.text), onPressed: () => Navigator.of(context).pop()),
        title: Text('${_i + 1}/${widget.cards.length}', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _flipped = !_flipped),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(_flipped),
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _flipped ? _tr(lang, 'Javob', 'Ответ', 'Back') : _tr(lang, 'Savol', 'Вопрос', 'Front'),
                            style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(_flipped ? c.back : c.front,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w700)),
                          if (!_flipped) ...[
                            const SizedBox(height: 16),
                            Text(_tr(lang, 'Javobni ko\'rish uchun bosing', 'Нажмите, чтобы увидеть', 'Tap to reveal'),
                                style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_flipped)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _grade(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(_tr(lang, 'Bilmadim', 'Не знал', 'Didn\'t know')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _grade(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(_tr(lang, 'Bildim', 'Знал', 'Knew it')),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
