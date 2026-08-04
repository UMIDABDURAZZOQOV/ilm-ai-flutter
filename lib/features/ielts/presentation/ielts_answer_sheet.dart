import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ai_explain_sheet.dart';
import '../data/ielts_models.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

/// Renders a list of IELTS questions (MCQ or short-answer), grades them locally
/// against the correct_answer, and shows a score. Shared by Reading & Listening.
class IeltsAnswerSheet extends StatefulWidget {
  final List<IeltsQuestion> questions;
  final String lang;
  const IeltsAnswerSheet({super.key, required this.questions, required this.lang});

  @override
  State<IeltsAnswerSheet> createState() => _IeltsAnswerSheetState();
}

class _IeltsAnswerSheetState extends State<IeltsAnswerSheet> {
  final Map<int, String> _answers = {};
  final Map<int, TextEditingController> _controllers = {};
  bool _checked = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  bool _isCorrect(IeltsQuestion q) {
    final given = _norm(_answers[q.id] ?? _controllers[q.id]?.text ?? '');
    if (given.isEmpty) return false;
    final correct = _norm(q.correctAnswer);
    // Accept any of several correct forms separated by / or ;
    final variants = correct.split(RegExp(r'[/;]')).map(_norm);
    return variants.any((v) => v == given || (v.isNotEmpty && given == v));
  }

  int get _score => widget.questions.where(_isCorrect).length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = widget.lang;
    if (widget.questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_tr(lang, 'Bu bo\'lim uchun savol yo\'q.', 'Нет вопросов для этого раздела.', 'No questions for this section.'),
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_checked)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: colors.successLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.success)),
            child: Text('${_tr(lang, 'Natija', 'Результат', 'Score')}: $_score / ${widget.questions.length}',
                style: TextStyle(color: colors.success, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ...widget.questions.asMap().entries.map((e) => _buildQuestion(e.key, e.value, colors, lang)),
        const SizedBox(height: 12),
        if (!_checked)
          ElevatedButton(
            onPressed: () => setState(() => _checked = true),
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(_tr(lang, 'Javoblarni tekshirish', 'Проверить ответы', 'Check answers'), style: const TextStyle(fontWeight: FontWeight.w700)),
          )
        else
          OutlinedButton(
            onPressed: () => setState(() { _checked = false; _answers.clear(); for (final c in _controllers.values) { c.clear(); } }),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(_tr(lang, 'Qayta urinish', 'Заново', 'Try again')),
          ),
      ],
    );
  }

  Widget _buildQuestion(int index, IeltsQuestion q, ThemeColors colors, String lang) {
    final correct = _checked && _isCorrect(q);
    final wrong = _checked && !_isCorrect(q);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: correct ? colors.success : wrong ? colors.error : colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${index + 1}. ${q.questionText}', style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 10),
        if (q.isMcq)
          ...q.options.map((opt) {
            final selected = _answers[q.id] == opt;
            final isRight = _checked && _norm(opt) == _norm(q.correctAnswer);
            return InkWell(
              onTap: _checked ? null : () => setState(() => _answers[q.id] = opt),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isRight ? colors.successLight : selected ? colors.primary.withValues(alpha: 0.1) : colors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isRight ? colors.success : selected ? colors.primary : colors.border),
                ),
                child: Row(children: [
                  Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: selected ? colors.primary : colors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(opt, style: TextStyle(color: colors.text, fontSize: 13))),
                ]),
              ),
            );
          })
        else
          TextField(
            controller: _controllers.putIfAbsent(q.id, () => TextEditingController()),
            enabled: !_checked,
            decoration: InputDecoration(
              hintText: _tr(lang, 'Javobingiz...', 'Ваш ответ...', 'Your answer...'),
              filled: true, fillColor: colors.background, isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
            ),
          ),
        if (_checked && wrong) ...[
          const SizedBox(height: 8),
          Text('${_tr(lang, 'To\'g\'ri javob', 'Правильный ответ', 'Correct answer')}: ${q.correctAnswer}',
              style: TextStyle(color: colors.success, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
        if (_checked && q.hint != null && q.hint!.isNotEmpty && wrong)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text('💡 ${q.hint}', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        if (_checked)
          AiExplainButton(question: q.questionText, correctAnswer: q.correctAnswer, userAnswer: _answers[q.id] ?? _controllers[q.id]?.text),
      ]),
    );
  }
}
