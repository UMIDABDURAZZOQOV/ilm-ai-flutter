import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quiz_models.dart';
import '../data/quiz_repository.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  List<Flashcard> _cards = [];
  int _index = 0;
  bool _flipped = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cards = await ref.read(quizRepositoryProvider).generateFlashcards(userId, ref.read(languageProvider));
      setState(() {
        _cards = cards;
        _index = 0;
        _flipped = false;
      });
    } catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('flashcard.title', language)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _generate)],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: TextStyle(color: colors.error)))
                : _cards.isEmpty
                    ? Center(child: Text(t('files.empty', language), style: TextStyle(color: colors.textMuted)))
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _flipped = !_flipped),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Container(
                                    key: ValueKey('$_index-$_flipped'),
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _flipped ? _cards[_index].back : _cards[_index].front,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.4),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(t('flashcard.tap', language), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t('flashcard.counter', language).replaceAll('{i}', '${_index + 1}').replaceAll('{n}', '${_cards.length}'),
                              style: TextStyle(color: colors.textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GradientButton(
                                    outline: true,
                                    onPressed: _index == 0
                                        ? null
                                        : () => setState(() {
                                              _index--;
                                              _flipped = false;
                                            }),
                                    child: Text(t('flashcard.prev', language)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GradientButton(
                                    onPressed: _index == _cards.length - 1
                                        ? null
                                        : () => setState(() {
                                              _index++;
                                              _flipped = false;
                                            }),
                                    child: Text(t('flashcard.next', language)),
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
