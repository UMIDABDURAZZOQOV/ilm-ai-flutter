import 'package:flutter/material.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../skills/presentation/skill_ui.dart';
import '../data/world_history_repository.dart';

/// Input only; the server owns reviewed keys, aliases and correctness.
class WorldHistoryAnswerEditor extends StatefulWidget {
  final Json question, draft;
  final Json? feedback;
  final bool enabled;
  final String language;
  final ValueChanged<Json> onChanged;
  const WorldHistoryAnswerEditor({
    super.key,
    required this.question,
    required this.draft,
    required this.enabled,
    required this.onChanged,
    this.feedback,
    this.language = 'uz',
  });
  @override
  State<WorldHistoryAnswerEditor> createState() =>
      _WorldHistoryAnswerEditorState();
}

class _WorldHistoryAnswerEditorState extends State<WorldHistoryAnswerEditor> {
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
      key: const Key('world-history-short-answer'),
      controller: _text,
      readOnly: !widget.enabled,
      maxLength: widget.question['max_length'] as int,
      minLines: 1,
      maxLines: 3,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: str3(
          widget.language,
          'Qisqa javob',
          'Краткий ответ',
          'Short answer',
        ),
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
