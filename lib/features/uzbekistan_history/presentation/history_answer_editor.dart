import 'package:flutter/material.dart';
import '../../physics/presentation/physics_answer_editor.dart';
import '../data/history_repository.dart';

/// Objective name/term input only. No local keys, fuzzy grading or essay score.
class HistoryAnswerEditor extends StatelessWidget {
  final Json question, draft;
  final bool enabled;
  final ValueChanged<Json> onChanged;
  const HistoryAnswerEditor({
    super.key,
    required this.question,
    required this.draft,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (question['response_kind'] != 'short_text') {
      return PhysicsAnswerEditor(
        question: question,
        draft: draft,
        enabled: enabled,
        onChanged: onChanged,
      );
    }
    return TextFormField(
      key: ValueKey('history-value-${question['key']}'),
      initialValue: draft['value'] as String? ?? '',
      enabled: enabled,
      maxLength: 120,
      minLines: 1,
      maxLines: 3,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Qisqa javob',
        helperText: question['input_hint'] as String,
        helperMaxLines: 4,
      ),
      onChanged: (value) =>
          onChanged(value.trim().isEmpty ? {} : {'value': value}),
    );
  }
}
