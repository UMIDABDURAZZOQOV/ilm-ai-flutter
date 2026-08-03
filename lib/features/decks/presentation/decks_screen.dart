import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_loading.dart';
import '../../../core/widgets/animated_pressable.dart';
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
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: colors.text, size: 24), onPressed: () => context.pop()),
        title: Text(_tr(lang, 'Flashcard to\'plamlari', 'Колоды карточек', 'Flashcard decks'),
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
      ),
      body: _decks == null
          ? const Center(child: PremiumLoading())
          : _decks!.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Icons.style_rounded, size: 40, color: colors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _tr(lang, 'Hali to\'plam yo\'q. Studio yoki companion kartochkalarini saqlang.',
                              'Пока нет колод. Сохраните карточки из Studio.',
                              'No decks yet. Save flashcards from Studio or the companion.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(_tr(lang, 'Muddati kelganlari birinchi.', 'Сначала карточки к повторению.', 'Due cards first.'),
                        style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    ..._decks!.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: AnimatedPressable(
                            onTap: () => _review(entry.value),
                            child: PremiumCard(
                              borderRadius: 20,
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.value.title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 16)),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${entry.value.total} ${_tr(lang, 'karta', 'карт', 'cards')}'
                                          '${entry.value.due > 0 ? ' · ${entry.value.due} ${_tr(lang, 'takror', 'к повтору', 'due')}' : ''}',
                                          style: TextStyle(color: entry.value.due > 0 ? colors.primary : colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (entry.value.due > 0)
                                    PremiumButton(
                                      onPressed: () => _review(entry.value),
                                      borderRadius: 14,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Text(_tr(lang, 'Takror', 'Повторить', 'Review'), style: const TextStyle(fontSize: 13)),
                                    ),
                                  const SizedBox(width: 8),
                                  AnimatedPressable(
                                    onTap: () => _delete(entry.value),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: colors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.delete_outline_rounded, color: colors.error, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: (entry.key * 50).ms, duration: 300.ms),
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
        leading: IconButton(icon: Icon(Icons.close_rounded, color: colors.text, size: 24), onPressed: () => Navigator.of(context).pop()),
        title: Text('${_i + 1}/${widget.cards.length}', style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
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
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_flipped),
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _flipped ? _tr(lang, 'Javob', 'Ответ', 'Back') : _tr(lang, 'Savol', 'Вопрос', 'Front'),
                            style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(_flipped ? c.back : c.front,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.w800, height: 1.4)),
                          if (!_flipped) ...[
                            const SizedBox(height: 20),
                            Text(_tr(lang, 'Javobni ko\'rish uchun bosing', 'Нажмите, чтобы увидеть', 'Tap to reveal'),
                                style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_flipped)
                Row(
                  children: [
                    Expanded(
                      child: PremiumButton(
                        onPressed: () => _grade(false),
                        backgroundColor: colors.error,
                        borderRadius: 18,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.close_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(_tr(lang, 'Bilmadim', 'Не знал', 'Didn\'t know')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: PremiumButton(
                        onPressed: () => _grade(true),
                        backgroundColor: colors.success,
                        borderRadius: 18,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(_tr(lang, 'Bildim', 'Знал', 'Knew it')),
                          ],
                        ),
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
