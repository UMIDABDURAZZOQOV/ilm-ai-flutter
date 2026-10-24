import 'package:flutter/material.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../skills/presentation/skill_ui.dart';
import '../data/chemistry_repository.dart';
import 'chemistry_display_text.dart';

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
    final formula = widget.question['response_kind'] == 'chemical_formula';
    final equation = widget.question['response_kind'] == 'chemical_equation';
    if (widget.question['response_kind'] == 'concept_selection') {
      return Column(
        children: [
          for (final option in jsonRows(widget.question['options']))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DuoChoiceCard(
                text: chemistryDisplayText(option['label'] as String),
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
        labelText: equation
            ? str3(
                widget.language,
                'Kimyoviy tenglama',
                'Химическое уравнение',
                'Chemical equation',
              )
            : formula
            ? str3(
                widget.language,
                'Kimyoviy formula',
                'Химическая формула',
                'Chemical formula',
              )
            : numeric
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
        helperText: (formula || equation)
            ? str3(
                widget.language,
                equation
                    ? 'Chap = o‘ng. Moddalarni + bilan ajrating. Harflar registrini saqlang.'
                    : 'Indeksni oddiy yoki pastki raqamda yozing. Harflar registrini saqlang.',
                equation
                    ? 'Слева = справа. Разделяйте вещества знаком +. Учитывайте регистр.'
                    : 'Индекс: обычная или нижняя цифра. Учитывайте регистр.',
                equation
                    ? 'Left = right. Separate substances with +. Case matters.'
                    : 'Use ordinary or subscript digits. Case matters.',
              )
            : numeric
            ? str3(
                widget.language,
                'Faqat son. Birlik: ${widget.question['unit'] == '' ? 'birliksiz' : widget.question['unit']}. e yozuvi ham mumkin.',
                'Только число. Единица: ${widget.question['unit'] == '' ? 'безразмерная' : widget.question['unit']}. Можно использовать e.',
                'Number only. Unit: ${widget.question['unit'] == '' ? 'dimensionless' : widget.question['unit']}. e notation accepted.',
              )
            : null,
        helperMaxLines: 6,
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
