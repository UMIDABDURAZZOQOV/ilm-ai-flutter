import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import '../data/skill_tree_models.dart';
import 'ai_tutor_widget.dart';
import 'skill_ui.dart';

enum _Phase { overview, running, result }

class MockExamScreen extends ConsumerStatefulWidget {
  final SkillSubject subject;
  const MockExamScreen({super.key, required this.subject});

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen> {
  _Phase _phase = _Phase.overview;
  bool _loading = true;
  MockOverview? _overview;

  MockStartResult? _exam;
  final Map<int, String> _answers = {};
  int _index = 0;
  int _timeLeft = 0;
  Timer? _timer;
  bool _submitting = false;
  bool _submitted = false;
  MockResult? _result;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOverview() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      _overview = await ref.read(skillExtrasRepositoryProvider).getMockOverview(userId, widget.subject.slug);
    } catch (_) {
      _overview = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _begin() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      _exam = await ref.read(skillExtrasRepositoryProvider).startMockExam(userId, widget.subject.slug);
      _answers.clear();
      _index = 0;
      _submitted = false;
      _timeLeft = _exam!.durationSeconds;
      _phase = _Phase.running;
      _startTimer();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _submit();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitted || _exam == null) return;
    _submitted = true;
    _timer?.cancel();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _submitting = true);
    try {
      final answers = _exam!.questions.map((q) => {'question_id': q.id, 'user_answer': _answers[q.id]}).toList();
      _result = await ref.read(skillExtrasRepositoryProvider).completeMockExam(userId, _exam!.examId, answers);
      _phase = _Phase.result;
    } catch (_) {
      _submitted = false;
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    if (_phase == _Phase.result && _result != null) return _buildResult(lang, _result!);
    if (_phase == _Phase.running && _exam != null) return _buildRunning(lang);
    return _buildOverview(lang);
  }

  // ── Overview ─────────────────────────────────────────────────────────────
  Widget _buildOverview(String lang) {
    final o = _overview;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.subject.nameFor(lang)} · ${str3(lang, 'Sinov imtihoni', 'Пробный экзамен', 'Mock exam')}')),
      body: _loading || o == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
                    child: Row(
                      children: [
                        _numTile('${o.size}', str3(lang, 'savol', 'вопросов', 'questions')),
                        const SizedBox(width: 20),
                        _numTile('${(o.durationSeconds / 60).round()}', str3(lang, 'daqiqa', 'минут', 'minutes')),
                        const Spacer(),
                        if (o.bestGrade != null)
                          Column(
                            children: [
                              Text(o.bestGrade!, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: gradeColor(o.bestGrade))),
                              Text('${str3(lang, 'eng yaxshi', 'лучший', 'best')} · ${o.bestPercentage}%', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (o.prediction != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: gradeColor(o.prediction!.predictedGrade).withValues(alpha: 0.4), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF58CC02)),
                            const SizedBox(width: 6),
                            Text(str3(lang, 'Bashorat qilingan daraja', 'Прогнозируемая оценка', 'Predicted grade'), style: const TextStyle(fontWeight: FontWeight.w800)),
                          ]),
                          const SizedBox(height: 6),
                          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(o.prediction!.predictedGrade, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: gradeColor(o.prediction!.predictedGrade))),
                            const SizedBox(width: 8),
                            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('~${o.prediction!.predictedPct}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade600))),
                          ]),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF58CC02), padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _begin,
                    icon: const Icon(Icons.emoji_events_rounded),
                    label: Text(str3(lang, 'Imtihonni boshlash', 'Начать экзамен', 'Start exam'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  if (o.attempts.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(str3(lang, 'Oldingi urinishlar', 'Прошлые попытки', 'Past attempts'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    for (final a in o.attempts)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(a.completedAt?.substring(0, 10) ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text('${a.score}/${a.total} · ${a.percentage}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(a.grade ?? '', style: TextStyle(fontWeight: FontWeight.w900, color: gradeColor(a.grade))),
                        ]),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _numTile(String value, String label) => Column(children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ]);

  // ── Running ──────────────────────────────────────────────────────────────
  Widget _buildRunning(String lang) {
    final q = _exam!.questions[_index];
    final total = _exam!.questions.length;
    final mm = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_timeLeft % 60).toString().padLeft(2, '0');
    final answeredCount = _answers.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: _confirmLeave),
                  Text('$mm:$ss', style: TextStyle(fontWeight: FontWeight.w900, color: _timeLeft < 60 ? const Color(0xFFFF4B4B) : null)),
                  const Spacer(),
                  Text('${_index + 1}/$total', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
                ],
              ),
            ),
            LinearProgressIndicator(value: (_index + 1) / total, minHeight: 6, color: const Color(0xFF58CC02), backgroundColor: Colors.black12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(q.questionText, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    for (final opt in q.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => setState(() => _answers[q.id] = opt),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: _answers[q.id] == opt ? const Color(0xFF58CC02).withValues(alpha: 0.10) : null,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _answers[q.id] == opt ? const Color(0xFF58CC02) : Colors.black12, width: 2),
                            ),
                            child: Text(opt, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  OutlinedButton(onPressed: _index == 0 ? null : () => setState(() => _index--), child: Text(str3(lang, 'Oldingi', 'Назад', 'Prev'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _index < total - 1
                        ? FilledButton(onPressed: () => setState(() => _index++), child: Text(str3(lang, 'Keyingi', 'Далее', 'Next')))
                        : FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF58CC02)),
                            onPressed: _submitting ? null : _submit,
                            child: Text(_submitting ? '...' : str3(lang, 'Yakunlash ($answeredCount/$total)', 'Завершить ($answeredCount/$total)', 'Finish ($answeredCount/$total)'), style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeave() {
    final lang = ref.read(languageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(str3(lang, 'Imtihonni tark etasizmi? Javoblaringiz baholanadi.', 'Выйти из экзамена? Ответы будут оценены.', 'Leave the exam? Your answers will be graded.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(str3(lang, 'Yo\'q', 'Нет', 'No'))),
          FilledButton(onPressed: () { Navigator.pop(ctx); _submit(); }, child: Text(str3(lang, 'Ha', 'Да', 'Yes'))),
        ],
      ),
    );
  }

  // ── Result ───────────────────────────────────────────────────────────────
  Widget _buildResult(String lang, MockResult r) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(str3(lang, 'Natija', 'Результат', 'Result'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: gradeColor(r.grade)),
              child: Column(
                children: [
                  Text('${widget.subject.nameFor(lang)} · ${str3(lang, 'Sinov imtihoni', 'Пробный экзамен', 'Mock exam')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(r.grade, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                  const SizedBox(height: 6),
                  Text('${r.percentage}% · ${r.score}/${r.total}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    r.certificate
                        ? str3(lang, '🎓 Sertifikat darajasida!', '🎓 Уровень сертификата!', '🎓 Certificate level!')
                        : str3(lang, 'Sertifikat uchun kamida 60% kerak', 'Для сертификата нужно минимум 60%', 'Need at least 60% for a certificate'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (r.prediction != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF58CC02)),
                      const SizedBox(width: 6),
                      Text(str3(lang, 'Haqiqiy imtihon bashorati', 'Прогноз реального экзамена', 'Real exam prediction'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(r.prediction!.predictedGrade, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: gradeColor(r.prediction!.predictedGrade))),
                      const SizedBox(width: 8),
                      Padding(padding: const EdgeInsets.only(bottom: 5), child: Text('~${r.prediction!.predictedPct}%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade600))),
                    ]),
                  ],
                ),
              ),
            ],
            if (r.xpAwarded > 0) ...[
              const SizedBox(height: 12),
              Center(child: Text('+${r.xpAwarded} XP', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFFA000), fontSize: 16))),
            ],
            const SizedBox(height: 16),
            Text(str3(lang, 'Javoblarni ko\'rib chiqish', 'Разбор ответов', 'Review answers'), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (var i = 0; i < r.review.length; i++) _reviewTile(lang, i + 1, r.review[i]),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF58CC02), padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => context.pop(),
              child: Text(str3(lang, 'Yakunlash', 'Завершить', 'Done'), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewTile(String lang, int n, MockReviewItem r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(r.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 18, color: r.isCorrect ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B)),
            const SizedBox(width: 6),
            Expanded(child: Text('$n. ${r.questionText}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
          ]),
          if (!r.isCorrect) ...[
            const SizedBox(height: 6),
            if (r.userAnswer.isNotEmpty)
              Text('${str3(lang, 'Siz:', 'Вы:', 'You:')} ${r.userAnswer}', style: const TextStyle(fontSize: 12, color: Color(0xFFFF4B4B), decoration: TextDecoration.lineThrough)),
            Text('${str3(lang, 'To\'g\'ri:', 'Верно:', 'Correct:')} ${r.correctAnswer}', style: const TextStyle(fontSize: 12, color: Color(0xFF3A8A00), fontWeight: FontWeight.w700)),
            if (r.explanation != null && r.explanation!.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 2), child: Text(r.explanation!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
            AiTutorWidget(questionText: r.questionText, options: r.options, correctAnswer: r.correctAnswer, userAnswer: r.userAnswer),
          ],
        ],
      ),
    );
  }
}
