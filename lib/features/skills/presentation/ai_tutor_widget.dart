import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';

/// On-demand AI tutor button, shown next to a WRONG answer. Only calls Gemini
/// when tapped (never per question); caches the explanation once fetched.
class AiTutorWidget extends ConsumerStatefulWidget {
  final String questionText;
  final List<String>? options;
  final String correctAnswer;
  final String? userAnswer;

  const AiTutorWidget({
    super.key,
    required this.questionText,
    this.options,
    required this.correctAnswer,
    this.userAnswer,
  });

  @override
  ConsumerState<AiTutorWidget> createState() => _AiTutorWidgetState();
}

class _AiTutorWidgetState extends ConsumerState<AiTutorWidget> {
  bool _loading = false;
  bool _error = false;
  String? _explanation;

  Future<void> _ask() async {
    if (_loading || _explanation != null) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    final lang = ref.read(languageProvider);
    try {
      final text = await ref.read(skillExtrasRepositoryProvider).explain(
            questionText: widget.questionText,
            options: widget.options,
            correctAnswer: widget.correctAnswer,
            userAnswer: widget.userAnswer,
            lang: lang,
          );
      setState(() => _explanation = text);
    } catch (_) {
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    const violet = Color(0xFF7048E8);

    if (_explanation != null) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: violet.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: violet.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 15, color: violet),
                const SizedBox(width: 5),
                Text(
                  str3(lang, 'AI repetitor', 'AI репетитор', 'AI tutor'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: violet),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_explanation!, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: _loading ? null : _ask,
              style: TextButton.styleFrom(
                backgroundColor: violet.withValues(alpha: 0.12),
                foregroundColor: violet,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: _loading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: violet))
                  : const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                _loading
                    ? str3(lang, "O'ylayapti...", 'Думает...', 'Thinking...')
                    : str3(lang, '🤔 Tushuntirib ber', '🤔 Объясни', '🤔 Explain this'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
            if (_error)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  str3(lang, "Hozir bo'lmadi, qayta urinib ko'ring", 'Не получилось, попробуйте снова', "Couldn't load, try again"),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFFF4B4B)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
