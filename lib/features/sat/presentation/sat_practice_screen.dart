import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../../core/widgets/ai_explain_sheet.dart';
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/sat_models.dart';
import '../data/sat_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class SatPracticeScreen extends ConsumerStatefulWidget {
  final String title;
  final String? domain;
  final String? skill;
  final String difficulty;
  final int numQuestions;
  const SatPracticeScreen({
    super.key,
    required this.title,
    this.domain,
    this.skill,
    this.difficulty = 'medium',
    this.numQuestions = 10,
  });

  @override
  ConsumerState<SatPracticeScreen> createState() => _SatPracticeScreenState();
}

class _SatPracticeScreenState extends ConsumerState<SatPracticeScreen> {
  SatSessionStart? _session;
  String? _error;
  int _i = 0;
  String? _selected;
  final _textCtrl = TextEditingController();
  bool _answered = false;
  bool _submitting = false;
  int _correctCount = 0;
  DateTime _qStart = DateTime.now();
  SatSessionResult? _result;

  @override
  void initState() { super.initState(); _start(); }

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  Future<void> _start() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final s = await ref.read(satRepositoryProvider).startSession(
        userId: userId, domain: widget.domain, skill: widget.skill,
        difficulty: widget.difficulty, numQuestions: widget.numQuestions,
      );
      if (mounted) setState(() { _session = s; _qStart = DateTime.now(); });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('404') ? 'no_questions' : 'failed');
    }
  }

  bool _matches(SatQuestion q, String answer) =>
      answer.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase();

  Future<void> _submitCurrent() async {
    if (_answered || _submitting) return;
    final q = _session!.questions[_i];
    final answer = q.isMcq ? (_selected ?? '') : _textCtrl.text.trim();
    if (answer.isEmpty) return;
    setState(() { _submitting = true; });
    final elapsed = DateTime.now().difference(_qStart).inMilliseconds;
    try {
      await ref.read(satRepositoryProvider).submitAnswer(
        sessionId: _session!.sessionId, questionId: q.id, answer: answer, elapsedMs: elapsed,
      );
    } catch (_) {/* keep going even if one submit fails */}
    if (_matches(q, answer)) _correctCount++;
    if (mounted) setState(() { _answered = true; _submitting = false; });
  }

  Future<void> _next() async {
    if (_i + 1 >= _session!.questions.length) {
      await _finish();
    } else {
      setState(() { _i++; _selected = null; _textCtrl.clear(); _answered = false; _qStart = DateTime.now(); });
    }
  }

  Future<void> _finish() async {
    setState(() => _submitting = true);
    try {
      final r = await ref.read(satRepositoryProvider).completeSession(_session!.sessionId);
      if (mounted) setState(() { _result = r; _submitting = false; });
    } catch (_) {
      if (mounted) setState(() { _result = SatSessionResult(score: _correctCount, total: _session!.questions.length); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);

    if (_error != null) {
      return _Scaffold(title: widget.title, colors: colors, child: Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          _error == 'no_questions'
              ? _tr(lang, 'Bu bo\'lim uchun savol topilmadi.', 'Нет вопросов для этого раздела.', 'No questions for this section yet.')
              : _tr(lang, 'Yuklab bo\'lmadi.', 'Не удалось загрузить.', 'Failed to load.'),
          textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
      )));
    }
    if (_session == null) {
      return _Scaffold(title: widget.title, colors: colors, child: const Center(child: CircularProgressIndicator()));
    }
    if (_result != null) {
      return _Scaffold(title: widget.title, colors: colors, child: _buildResult(colors, lang));
    }

    final q = _session!.questions[_i];
    final total = _session!.questions.length;
    final last = _i + 1 >= total;
    return _Scaffold(
      title: '${_i + 1}/$total',
      colors: colors,
      child: Column(children: [
        LinearProgressIndicator(value: (_i + (_answered ? 1 : 0)) / total, minHeight: 4, backgroundColor: colors.border, valueColor: AlwaysStoppedAnimation(colors.primary)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(children: [
                _chip(q.domain, const Color(0xFF3B82F6), colors),
                if (q.skill != null && q.skill!.isNotEmpty) ...[const SizedBox(width: 6), _chip(q.skill!, colors.textSecondary, colors)],
              ]),
              const SizedBox(height: 14),
              Text(q.questionText, style: TextStyle(color: colors.text, fontSize: 16, height: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),
              if (q.isMcq)
                ...q.options.map((opt) => _optionTile(q, opt, colors))
              else
                TextField(
                  controller: _textCtrl,
                  enabled: !_answered,
                  decoration: InputDecoration(
                    hintText: _tr(lang, 'Javobingiz', 'Ваш ответ', 'Your answer'),
                    filled: true, fillColor: colors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                  ),
                ),
              if (_answered && !q.isMcq) ...[
                const SizedBox(height: 10),
                Text('${_tr(lang, 'To\'g\'ri javob', 'Правильный ответ', 'Correct answer')}: ${q.correctAnswer}',
                    style: TextStyle(color: colors.success, fontWeight: FontWeight.w700)),
              ],
              if (_answered && q.rubric != null && q.rubric!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
                  child: Text(q.rubric!, style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4)),
                ),
              ],
              if (_answered) ...[
                const SizedBox(height: 6),
                AiExplainButton(question: q.questionText, correctAnswer: q.correctAnswer, userAnswer: q.isMcq ? _selected : _textCtrl.text.trim()),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : (_answered ? _next : _submitCurrent),
                style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_answered ? (last ? _tr(lang, 'Yakunlash', 'Завершить', 'Finish') : _tr(lang, 'Keyingi', 'Далее', 'Next')) : _tr(lang, 'Tekshirish', 'Проверить', 'Check'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String text, Color c, ThemeColors colors) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
      );

  Widget _optionTile(SatQuestion q, String opt, ThemeColors colors) {
    final selected = _selected == opt;
    final isRight = _answered && opt.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase();
    final isWrongPick = _answered && selected && !isRight;
    Color border = colors.border, bg = colors.card;
    if (isRight) { border = colors.success; bg = colors.successLight; }
    else if (isWrongPick) { border = colors.error; bg = colors.errorLight; }
    else if (selected) { border = colors.primary; }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _answered ? null : () => setState(() => _selected = opt),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 1.5)),
          child: Text(opt, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildResult(ThemeColors colors, String lang) {
    final r = _result!;
    final pct = r.scorePct ?? (r.total != null && r.total! > 0 ? (r.score ?? 0) / r.total! * 100 : 0);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Center(child: Text('${r.score ?? _correctCount} / ${r.total ?? _session!.questions.length}',
            style: TextStyle(color: colors.text, fontSize: 44, fontWeight: FontWeight.w900))),
        Center(child: Text('${pct.round()}%', style: TextStyle(color: colors.primary, fontSize: 18, fontWeight: FontWeight.w700))),
        const SizedBox(height: 24),
        if (r.sectionScores.isNotEmpty) ...[
          Text(_tr(lang, 'Bo\'limlar bo\'yicha', 'По разделам', 'By section'), style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...r.sectionScores.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(e.key, style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600))),
                    Text('${e.value.round()}%', style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(value: e.value / 100, minHeight: 6, backgroundColor: colors.border, valueColor: AlwaysStoppedAnimation(colors.primary)),
                  ),
                ]),
              )),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Text(_tr(lang, 'Tugatish', 'Готово', 'Done'), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _Scaffold extends StatelessWidget {
  final String title;
  final ThemeColors colors;
  final Widget child;
  const _Scaffold({required this.title, required this.colors, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: child,
    );
  }
}
