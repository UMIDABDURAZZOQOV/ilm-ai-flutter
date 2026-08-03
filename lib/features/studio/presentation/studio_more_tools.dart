import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../../quiz/data/quiz_models.dart';
import '../data/studio_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

/// Mock test from the learner's materials.
class StudioMockScreen extends ConsumerStatefulWidget {
  const StudioMockScreen({super.key});
  @override
  ConsumerState<StudioMockScreen> createState() => _StudioMockScreenState();
}

class _StudioMockScreenState extends ConsumerState<StudioMockScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _start() async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final qs = await ref.read(studioRepositoryProvider).mock(userId, lang, n: 15);
      if (qs.isEmpty || !mounted) { setState(() => _error = 'failed'); return; }
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StudioQuizRunner(title: _tr(lang, 'Sinov imtihoni', 'Пробный тест', 'Mock test'), questions: qs, lang: lang),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('no_materials') ? 'no_materials' : 'failed');
    } finally {
      if (mounted) setState(() => _busy = false);
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
        title: Text(_tr(lang, 'Materialdan sinov', 'Пробный тест', 'Mock test'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.assignment_rounded, size: 44, color: colors.success),
            const SizedBox(height: 12),
            Text(_tr(lang, 'Materialingizdan 15 savollik imtihon', 'Экзамен из 15 вопросов по материалу', '15-question exam from your material'),
                textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 20),
            if (_error == 'no_materials')
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_tr(lang, 'Avval material yuklang.', 'Сначала загрузите материал.', 'Upload material first.'), style: TextStyle(color: colors.warning))),
            if (_error == 'failed')
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_tr(lang, 'Bo\'lmadi — qayta urinib ko\'ring.', 'Не удалось.', 'Couldn\'t build it.'), style: TextStyle(color: colors.error))),
            ElevatedButton.icon(
              onPressed: _busy ? null : _start,
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow_rounded),
              label: Text(_busy ? _tr(lang, 'Tayyorlanmoqda...', 'Создаётся...', 'Building...') : _tr(lang, 'Boshlash', 'Начать', 'Start')),
            ),
          ]),
        ),
      ),
    );
  }
}

/// AI diagram — generates Mermaid source (shown as code, since the app has no
/// Mermaid renderer yet).
class StudioDiagramScreen extends ConsumerStatefulWidget {
  const StudioDiagramScreen({super.key});
  @override
  ConsumerState<StudioDiagramScreen> createState() => _StudioDiagramScreenState();
}

class _StudioDiagramScreenState extends ConsumerState<StudioDiagramScreen> {
  final _ctrl = TextEditingController();
  bool _fromMaterials = false;
  bool _busy = false;
  ({String title, String mermaid})? _result;
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _build() async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null || _busy) return;
    if (!_fromMaterials && _ctrl.text.trim().isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      final r = await ref.read(studioRepositoryProvider).diagram(userId, _ctrl.text.trim(), _fromMaterials, lang);
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('no_materials') ? 'no_materials' : 'failed');
    } finally {
      if (mounted) setState(() => _busy = false);
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
        title: Text(_tr(lang, 'AI diagramma', 'AI-диаграмма', 'AI diagram'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _ctrl,
            enabled: !_fromMaterials,
            decoration: InputDecoration(
              hintText: _tr(lang, 'Mavzu (masalan: Fotosintez)', 'Тема (например: Фотосинтез)', 'Topic (e.g. Photosynthesis)'),
              filled: true, fillColor: colors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _fromMaterials,
            onChanged: (v) => setState(() => _fromMaterials = v),
            title: Text(_tr(lang, 'Materialimdan yasa', 'На основе материалов', 'Base it on my materials'), style: TextStyle(color: colors.text, fontSize: 14)),
          ),
          ElevatedButton.icon(
            onPressed: _busy ? null : _build,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.account_tree_rounded),
            label: Text(_busy ? _tr(lang, 'Chizilyapti...', 'Строится...', 'Building...') : _tr(lang, 'Diagramma yasash', 'Создать', 'Build diagram')),
          ),
          if (_error == 'no_materials') Padding(padding: const EdgeInsets.only(top: 12), child: Text(_tr(lang, 'Avval material yuklang.', 'Сначала загрузите материал.', 'Upload material first.'), style: TextStyle(color: colors.warning))),
          if (_error == 'failed') Padding(padding: const EdgeInsets.only(top: 12), child: Text(_tr(lang, 'Bo\'lmadi — qayta urinib ko\'ring.', 'Не удалось.', 'Couldn\'t build it.'), style: TextStyle(color: colors.error))),
          if (_result != null) ...[
            const SizedBox(height: 16),
            if (_result!.title.isNotEmpty) Text(_result!.title, style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
              child: Text(_result!.mermaid, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'monospace', height: 1.4)),
            ),
          ],
        ]),
      ),
    );
  }
}

/// My materials — list uploaded documents and delete them.
class StudioDocsScreen extends ConsumerStatefulWidget {
  const StudioDocsScreen({super.key});
  @override
  ConsumerState<StudioDocsScreen> createState() => _StudioDocsScreenState();
}

class _StudioDocsScreenState extends ConsumerState<StudioDocsScreen> {
  List<StudyDocument>? _docs;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final d = await ref.read(studioRepositoryProvider).listDocuments(userId);
      if (mounted) setState(() => _docs = d);
    } catch (_) {
      if (mounted) setState(() => _docs = []);
    }
  }

  Future<void> _delete(StudyDocument d) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(studioRepositoryProvider).deleteDocument(userId, d.filename);
    setState(() => _docs = _docs?.where((x) => x.filename != d.filename).toList());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'Materiallarim', 'Мои материалы', 'My materials'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
      ),
      body: _docs == null
          ? const Center(child: CircularProgressIndicator())
          : _docs!.isEmpty
              ? Center(child: Text(_tr(lang, 'Hali hujjat yo\'q.', 'Пока нет документов.', 'No documents yet.'), style: TextStyle(color: colors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _docs!.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = _docs![i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                      child: Row(children: [
                        Icon(Icons.description_rounded, color: colors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d.filename, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${d.topic} · ${d.chunks} ${_tr(lang, 'bo\'lak', 'фрагм.', 'chunks')}', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                          ]),
                        ),
                        IconButton(onPressed: () => _delete(d), icon: Icon(Icons.delete_outline_rounded, color: colors.textSecondary)),
                      ]),
                    );
                  },
                ),
    );
  }
}

/// Shared one-question-at-a-time runner used by the Studio mock test.
class StudioQuizRunner extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;
  final String lang;
  const StudioQuizRunner({super.key, required this.title, required this.questions, required this.lang});
  @override
  State<StudioQuizRunner> createState() => _StudioQuizRunnerState();
}

class _StudioQuizRunnerState extends State<StudioQuizRunner> {
  int _i = 0;
  String? _selected;
  bool _answered = false;
  int _correct = 0;

  void _pick(String opt) {
    if (_answered) return;
    setState(() {
      _selected = opt;
      _answered = true;
      if (opt == widget.questions[_i].correctAnswer) _correct++;
    });
  }

  void _next() {
    if (_i + 1 >= widget.questions.length) {
      Navigator.of(context).pop();
    } else {
      setState(() { _i++; _selected = null; _answered = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final q = widget.questions[_i];
    final lang = widget.lang;
    final last = _i + 1 >= widget.questions.length;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.close_rounded, color: colors.text), onPressed: () => Navigator.of(context).pop()),
        title: Text('${_i + 1}/${widget.questions.length}  ·  $_correct ✓', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: (_i + (_answered ? 1 : 0)) / widget.questions.length, minHeight: 6, backgroundColor: colors.border, valueColor: AlwaysStoppedAnimation(colors.primary)),
            ),
            const SizedBox(height: 20),
            Text(q.question, style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(children: q.options.map((opt) {
                final isCorrect = opt == q.correctAnswer;
                final isPicked = opt == _selected;
                Color border = colors.border, bg = colors.card;
                if (_answered && isCorrect) { border = colors.success; bg = colors.successLight; }
                else if (_answered && isPicked && !isCorrect) { border = colors.error; bg = colors.errorLight; }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _pick(opt),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 1.6)),
                      child: Text(opt, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }).toList()),
            ),
            if (_answered) ...[
              if (q.explanation.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(q.explanation, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(last ? _tr(lang, 'Tugatish', 'Завершить', 'Finish') : _tr(lang, 'Davom etish', 'Далее', 'Continue'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
