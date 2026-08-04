import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart' show languageProvider;
import '../theme/app_theme.dart';
import '../utils/math_text.dart';
import '../../features/auth/application/auth_controller.dart' show currentUserIdProvider;
import '../../features/assistant/data/assistant_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

/// A bottom sheet that asks the AI companion to explain a question — used after
/// any quiz/SAT/skill result so the learner gets a "why" for every item, right
/// or wrong. Reusable: pass the question and the correct (and optionally the
/// learner's) answer.
class AiExplainSheet extends ConsumerStatefulWidget {
  final String question;
  final String correctAnswer;
  final String? userAnswer;
  const AiExplainSheet({super.key, required this.question, required this.correctAnswer, this.userAnswer});

  static Future<void> show(BuildContext context, {required String question, required String correctAnswer, String? userAnswer}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiExplainSheet(question: question, correctAnswer: correctAnswer, userAnswer: userAnswer),
    );
  }

  @override
  ConsumerState<AiExplainSheet> createState() => _AiExplainSheetState();
}

class _AiExplainSheetState extends ConsumerState<AiExplainSheet> {
  String? _text;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null) { setState(() => _error = true); return; }
    final langName = lang == 'ru' ? 'Russian' : lang == 'en' ? 'English' : 'Uzbek';
    final prompt = 'You are a friendly tutor. Explain this question simply and clearly '
        'in $langName. Say why the correct answer is right'
        '${widget.userAnswer != null && widget.userAnswer!.isNotEmpty ? " and, if the student's answer was wrong, why it's wrong" : ''}. '
        'Keep it short (3-5 sentences), no markdown.\n\n'
        'QUESTION: ${widget.question}\n'
        'CORRECT ANSWER: ${widget.correctAnswer}'
        '${widget.userAnswer != null && widget.userAnswer!.isNotEmpty ? "\nSTUDENT'S ANSWER: ${widget.userAnswer}" : ''}';
    try {
      final r = await ref.read(assistantRepositoryProvider).ask(userId: userId, question: prompt, language: lang);
      if (mounted) setState(() => _text = r.answer.trim());
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(children: [
                Icon(Icons.auto_awesome_rounded, color: colors.secondary, size: 20),
                const SizedBox(width: 8),
                Text(_tr(lang, 'AI tushuntirishi', 'Объяснение AI', 'AI explanation'),
                    style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
                    child: Text(cleanMath(widget.question), style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  if (_error)
                    Text(_tr(lang, 'Tushuntirib bo\'lmadi — qayta urinib ko\'ring.', 'Не удалось объяснить.', 'Couldn\'t explain — try again.'),
                        style: TextStyle(color: colors.error))
                  else if (_text == null)
                    Row(children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
                      const SizedBox(width: 10),
                      Text(_tr(lang, 'AI o\'ylayapti...', 'AI думает...', 'AI is thinking...'), style: TextStyle(color: colors.textSecondary)),
                    ])
                  else
                    Text(_text!, style: TextStyle(color: colors.text, fontSize: 15, height: 1.55)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill button that opens [AiExplainSheet]. Drop it under a result row.
class AiExplainButton extends ConsumerWidget {
  final String question;
  final String correctAnswer;
  final String? userAnswer;
  const AiExplainButton({super.key, required this.question, required this.correctAnswer, this.userAnswer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => AiExplainSheet.show(context, question: question, correctAnswer: correctAnswer, userAnswer: userAnswer),
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(Icons.auto_awesome_rounded, size: 16, color: colors.secondary),
        label: Text(_tr(lang, 'AI tushuntirsin', 'Объяснить (AI)', 'Explain with AI'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
