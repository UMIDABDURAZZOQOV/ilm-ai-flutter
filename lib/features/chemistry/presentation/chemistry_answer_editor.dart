import 'package:flutter/material.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../skills/presentation/skill_ui.dart';
import '../data/chemistry_repository.dart';

/// Collects input only. All correctness and accepted text aliases live on server.
class ChemistryAnswerEditor extends StatefulWidget {
  final Json question, draft;
  final Json? feedback;
  final bool enabled;
  final String language;
  final ValueChanged<Json> onChanged;
  const ChemistryAnswerEditor({
    super.key,
    required this.question,
    required this.draft,
    required this.enabled,
    required this.onChanged,
    this.feedback,
    this.language = 'uz',
  });
  @override
  State<ChemistryAnswerEditor> createState() => _ChemistryAnswerEditorState();
}

class _ChemistryAnswerEditorState extends State<ChemistryAnswerEditor> {
  late final TextEditingController _text;
  late Json _draft;
  @override
  void initState() {
    super.initState();
    _draft = Map.of(widget.draft);
    _text = TextEditingController(text: _draft['value'] as String? ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void change(String field, String value) {
    setState(() => _draft = {field: value});
    widget.onChanged(Map.of(_draft));
  }

  @override
  Widget build(BuildContext context) {
    final numeric = widget.question['response_kind'] == 'numeric_value';
    if (widget.question['response_kind'] == 'concept_selection') {
      return Column(
        children: [
          for (final option in jsonRows(widget.question['options']))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DuoChoiceCard(
                text: option['label'] as String,
                selected: _draft['choice_id'] == option['id'],
                answered: widget.feedback != null,
                isCorrectOption:
                    widget.feedback?['correct_answer'] == option['label'],
                onTap: widget.enabled
                    ? () => change('choice_id', option['id'] as String)
                    : null,
              ),
            ),
        ],
      );
    }
    return TextField(
      key: const Key('chemistry-short-answer'),
      controller: _text,
      readOnly: !widget.enabled,
      maxLength: widget.question['max_length'] as int,
      minLines: 1,
      maxLines: 3,
      autocorrect: false,
      enableSuggestions: false,
      // Scientific notation needs e and a minus sign on mobile keyboards too.
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: numeric
            ? str3(
                widget.language,
                'Sonli javob',
                'Числовой ответ',
                'Numeric answer',
              )
            : str3(
                widget.language,
                'Qisqa javob',
                'Краткий ответ',
                'Short answer',
              ),
        helperText: numeric
            ? str3(
                widget.language,
                'Faqat son. Birlik: ${widget.question['unit'] == '' ? 'birliksiz' : widget.question['unit']}. e yozuvi ham mumkin.',
                'Только число. Единица: ${widget.question['unit'] == '' ? 'безразмерная' : widget.question['unit']}. Можно использовать e.',
                'Number only. Unit: ${widget.question['unit'] == '' ? 'dimensionless' : widget.question['unit']}. e notation accepted.',
              )
            : null,
        helperMaxLines: 3,
        hintText: str3(
          widget.language,
          'Javobni yozing',
          'Введите ответ',
          'Type your answer',
        ),
      ),
      onChanged: (value) => change('value', value),
    );
  }
}
