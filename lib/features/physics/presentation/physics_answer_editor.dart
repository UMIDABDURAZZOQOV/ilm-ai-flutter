import 'package:flutter/material.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../data/physics_repository.dart';

/// No answer/rubric here: controls only collect input for server grading.
class PhysicsAnswerEditor extends StatefulWidget {
  final Json question, draft;
  final bool enabled;
  final ValueChanged<Json> onChanged;
  const PhysicsAnswerEditor({
    super.key,
    required this.question,
    required this.draft,
    required this.enabled,
    required this.onChanged,
  });
  @override
  State<PhysicsAnswerEditor> createState() => _PhysicsAnswerEditorState();
}

class _PhysicsAnswerEditorState extends State<PhysicsAnswerEditor> {
  late final TextEditingController _formula, _value, _unit;
  late Json _draft;
  @override
  void initState() {
    super.initState();
    _draft = Map.of(widget.draft);
    _formula = TextEditingController(text: _draft['formula'] as String? ?? '');
    _value = TextEditingController(text: _draft['value'] as String? ?? '');
    _unit = TextEditingController(text: _draft['unit'] as String? ?? '');
  }

  @override
  void dispose() {
    _formula.dispose();
    _value.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _change(String field, dynamic value) {
    setState(() => _draft[field] = value);
    widget.onChanged(Map.of(_draft));
  }

  void _insert(String symbol) {
    final selection = _formula.selection;
    final start = selection.isValid ? selection.start : _formula.text.length;
    final end = selection.isValid ? selection.end : start;
    final text = _formula.text.replaceRange(start, end, symbol);
    _formula.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + symbol.length),
    );
    _change('formula', text);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    if (q['response_kind'] == 'concept_selection') {
      return Column(
        children: [
          for (final option in jsonRows(q['options']))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DuoChoiceCard(
                text: option['label'] as String,
                selected: _draft['choice_id'] == option['id'],
                answered: false,
                isCorrectOption: false,
                onTap: widget.enabled
                    ? () => _change('choice_id', option['id'])
                    : null,
              ),
            ),
        ],
      );
    }
    if (q['response_kind'] == 'ordering') {
      final items = jsonRows(q['items']);
      final selected = List<String>.from(_draft['order'] as List? ?? []);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Bosqichlarni to‘g‘ri ketma-ketlikda bosing.'),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton(
                onPressed: widget.enabled && !selected.contains(item['id'])
                    ? () =>
                          _change('order', [...selected, item['id'] as String])
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '${selected.contains(item['id']) ? '${selected.indexOf(item['id'] as String) + 1}. ' : ''}${item['label']}',
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: widget.enabled
                ? () => _change('order', <String>[])
                : null,
            child: const Text('Tartibni tozalash'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in jsonRows(q['givens']))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${g['symbol']} = ${g['value']}${g['unit'] == '1' ? ' (oraliqlar soni)' : ' ${g['unit']}'}',
            ),
          ),
        const Text(
          'Formulada quyidagi belgilarni ishlating. Ko‘paytirish: *, bo‘lish: /. Namuna formulalar nazariya kartalarida bor.',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('physics-formula'),
          controller: _formula,
          enabled: widget.enabled,
          maxLength: 128,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Formula',
            hintText: 'Belgilar va amallar',
          ),
          onChanged: (v) => _change('formula', v),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final symbol in [
              ...List<String>.from(q['symbols'] as List),
              '*',
              '/',
              '(',
              ')',
            ])
              ActionChip(
                label: Text(symbol),
                onPressed: widget.enabled ? () => _insert(symbol) : null,
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('physics-value'),
          controller: _value,
          enabled: widget.enabled,
          maxLength: 128,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Sonli javob',
            hintText: 'Masalan: 1.5 yoki 1,5',
          ),
          onChanged: (v) => _change('value', v),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('physics-unit'),
          controller: _unit,
          enabled: widget.enabled,
          maxLength: 16,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'O‘lchov birligi',
            hintText: 'm, cm yoki mm',
          ),
          onChanged: (v) => _change('unit', v),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final u in ['m', 'cm', 'mm'])
              ActionChip(
                label: Text(u),
                onPressed: widget.enabled
                    ? () {
                        _unit.text = u;
                        _change('unit', u);
                      }
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}
