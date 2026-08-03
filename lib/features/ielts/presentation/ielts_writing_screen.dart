import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/ielts_models.dart';
import '../data/ielts_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class IeltsWritingScreen extends ConsumerStatefulWidget {
  const IeltsWritingScreen({super.key});
  @override
  ConsumerState<IeltsWritingScreen> createState() => _IeltsWritingScreenState();
}

class _IeltsWritingScreenState extends ConsumerState<IeltsWritingScreen> {
  List<IeltsWriting>? _items;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ref.read(ieltsRepositoryProvider).listWriting();
      if (mounted) setState(() => _items = r);
    } catch (_) {
      if (mounted) setState(() => _error = 'failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'Yozish', 'Письмо', 'Writing'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
      ),
      body: _error != null
          ? Center(child: Text(_tr(lang, 'Yuklab bo\'lmadi.', 'Не удалось загрузить.', 'Failed to load.'), style: TextStyle(color: colors.textSecondary)))
          : _items == null
              ? const Center(child: CircularProgressIndicator())
              : _items!.isEmpty
                  ? Center(child: Text(_tr(lang, 'Hozircha vazifa yo\'q.', 'Пока нет заданий.', 'No tasks yet.'), style: TextStyle(color: colors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items!.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final w = _items![i];
                        return InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => IeltsWritingTask(task: w))),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFFF97316).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                                  child: Text(w.taskType.toUpperCase(), style: const TextStyle(color: Color(0xFFEA580C), fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: 8),
                                Text('${w.minWords}+ ${_tr(lang, 'so\'z', 'слов', 'words')} · ${w.durationMinutes} ${_tr(lang, 'daq', 'мин', 'min')}',
                                    style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                              ]),
                              const SizedBox(height: 8),
                              Text(w.prompt, style: TextStyle(color: colors.text, fontSize: 13.5, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                        );
                      },
                    ),
    );
  }
}

class IeltsWritingTask extends ConsumerStatefulWidget {
  final IeltsWriting task;
  const IeltsWritingTask({super.key, required this.task});
  @override
  ConsumerState<IeltsWritingTask> createState() => _IeltsWritingTaskState();
}

class _IeltsWritingTaskState extends ConsumerState<IeltsWritingTask> {
  final _essay = TextEditingController();
  bool _submitting = false;
  IeltsWritingSubmission? _result;
  String? _error;

  @override
  void dispose() { _essay.dispose(); super.dispose(); }

  int get _words => _essay.text.trim().isEmpty ? 0 : _essay.text.trim().split(RegExp(r'\s+')).length;

  Future<void> _submit() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _submitting) return;
    if (_words < 20) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final r = await ref.read(ieltsRepositoryProvider).submitWriting(userId: userId, taskId: widget.task.id, essay: _essay.text.trim());
      if (mounted) setState(() => _result = r);
    } catch (_) {
      if (mounted) setState(() => _error = 'failed');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    final enough = _words >= widget.task.minWords;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text('${_tr(lang, 'Yozish', 'Письмо', 'Writing')} · ${widget.task.taskType}', style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: _result != null
          ? _buildResult(colors, lang)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                  child: Text(widget.task.prompt, style: TextStyle(color: colors.text, fontSize: 14, height: 1.5)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _essay,
                  minLines: 10, maxLines: 24,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _tr(lang, 'Insho matnini shu yerga yozing...', 'Напишите эссе здесь...', 'Write your essay here...'),
                    filled: true, fillColor: colors.card, alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${_tr(lang, 'So\'zlar', 'Слов', 'Words')}: $_words / ${widget.task.minWords}',
                    style: TextStyle(color: enough ? colors.success : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_tr(lang, 'Baholab bo\'lmadi — qayta urinib ko\'ring.', 'Не удалось оценить.', 'Couldn\'t grade it.'), style: TextStyle(color: colors.error))),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: (_submitting || _words < 20) ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_submitting ? _tr(lang, 'Baholanmoqda...', 'Оценивается...', 'Grading...') : _tr(lang, 'AI baholashga yuborish', 'Отправить на AI-оценку', 'Submit for AI feedback')),
                ),
              ],
            ),
    );
  }

  Widget _buildResult(ThemeColors colors, String lang) {
    final r = _result!;
    Widget crit(String label, String? val) => (val == null || val.isEmpty) ? const SizedBox.shrink() : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(color: colors.text, fontSize: 13, height: 1.45)),
          ]),
        );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_tr(lang, 'Band ball', 'Балл', 'Band score'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(r.bandScore != null ? r.bandScore!.toStringAsFixed(1) : '—', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
            ]),
            const Spacer(),
            if (r.wordCount != null) Text('${r.wordCount} ${_tr(lang, 'so\'z', 'слов', 'words')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (r.feedback != null && r.feedback!.isNotEmpty) ...[
              Text(_tr(lang, 'Umumiy izoh', 'Общий отзыв', 'Overall feedback'), style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(r.feedback!, style: TextStyle(color: colors.text, fontSize: 13, height: 1.45)),
              const SizedBox(height: 14),
            ],
            crit(_tr(lang, 'Vazifaga javob (Task Response)', 'Ответ на задание', 'Task Response'), r.taskResponse),
            crit(_tr(lang, 'Bog\'lanish (Coherence)', 'Связность', 'Coherence & Cohesion'), r.coherence),
            crit(_tr(lang, 'Lug\'at (Lexical)', 'Лексика', 'Lexical Resource'), r.lexical),
            crit(_tr(lang, 'Grammatika', 'Грамматика', 'Grammar'), r.grammar),
          ]),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => setState(() { _result = null; }),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Text(_tr(lang, 'Qayta yozish', 'Написать заново', 'Write again')),
        ),
      ],
    );
  }
}
