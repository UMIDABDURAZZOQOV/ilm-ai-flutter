import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/ielts_models.dart';
import '../data/ielts_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class IeltsSpeakingScreen extends ConsumerStatefulWidget {
  const IeltsSpeakingScreen({super.key});
  @override
  ConsumerState<IeltsSpeakingScreen> createState() => _IeltsSpeakingScreenState();
}

class _IeltsSpeakingScreenState extends ConsumerState<IeltsSpeakingScreen> {
  List<IeltsSpeaking>? _items;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ref.read(ieltsRepositoryProvider).listSpeaking();
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
        title: Text(_tr(lang, 'Gapirish', 'Говорение', 'Speaking'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
      ),
      body: _error != null
          ? Center(child: Text(_tr(lang, 'Yuklab bo\'lmadi.', 'Не удалось загрузить.', 'Failed to load.'), style: TextStyle(color: colors.textSecondary)))
          : _items == null
              ? const Center(child: CircularProgressIndicator())
              : _items!.isEmpty
                  ? Center(child: Text(_tr(lang, 'Hozircha mavzu yo\'q.', 'Пока нет тем.', 'No topics yet.'), style: TextStyle(color: colors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items!.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = _items![i];
                        return InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => IeltsSpeakingTask(topic: s))),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40, alignment: Alignment.center,
                                decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                                child: Text('P${s.part}', style: const TextStyle(color: Color(0xFFDB2777), fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(s.topic, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('${_tr(lang, 'Qism', 'Часть', 'Part')} ${s.part} · ${s.difficulty}', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                                ]),
                              ),
                              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                            ]),
                          ),
                        );
                      },
                    ),
    );
  }
}

class IeltsSpeakingTask extends ConsumerStatefulWidget {
  final IeltsSpeaking topic;
  const IeltsSpeakingTask({super.key, required this.topic});
  @override
  ConsumerState<IeltsSpeakingTask> createState() => _IeltsSpeakingTaskState();
}

class _IeltsSpeakingTaskState extends ConsumerState<IeltsSpeakingTask> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _submitting = false;
  int _elapsed = 0;
  String? _recordedPath;
  IeltsSpeakingSubmission? _result;
  String? _error;

  @override
  void dispose() { _recorder.dispose(); super.dispose(); }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() { _recording = false; _recordedPath = path; });
      return;
    }
    if (!await _recorder.hasPermission()) {
      setState(() => _error = 'permission');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/ielts_speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() { _recording = true; _elapsed = 0; _recordedPath = null; _error = null; });
    _tick();
  }

  Future<void> _tick() async {
    while (_recording && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_recording && mounted) setState(() => _elapsed++);
    }
  }

  Future<void> _submit() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _recordedPath == null || _submitting) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final bytes = await File(_recordedPath!).readAsBytes();
      final b64 = base64Encode(bytes);
      final r = await ref.read(ieltsRepositoryProvider).submitSpeaking(
        userId: userId, topicId: widget.topic.id, audioBase64: b64, mimeType: 'audio/mp4', durationSeconds: _elapsed,
      );
      if (mounted) setState(() => _result = r);
    } catch (_) {
      if (mounted) setState(() => _error = 'failed');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text('${_tr(lang, 'Gapirish', 'Говорение', 'Speaking')} · P${widget.topic.part}', style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: _result != null ? _buildResult(colors, lang) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.topic.topic, style: TextStyle(color: colors.text, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (widget.topic.cueCard != null && widget.topic.cueCard!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
              child: Text(widget.topic.cueCard!, style: TextStyle(color: colors.text, fontSize: 14, height: 1.5)),
            ),
          if (widget.topic.questions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...widget.topic.questions.map((q) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 16, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(q, style: TextStyle(color: colors.text, fontSize: 14, height: 1.4))),
                  ]),
                )),
          ],
          const SizedBox(height: 24),
          // Record control
          Center(
            child: Column(children: [
              GestureDetector(
                onTap: _submitting ? null : _toggleRecord,
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: _recording ? colors.error : const Color(0xFFEC4899),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: (_recording ? colors.error : const Color(0xFFEC4899)).withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 12),
              Text(_recording ? _fmt(_elapsed) : (_recordedPath != null ? _tr(lang, 'Yozildi ✓', 'Записано ✓', 'Recorded ✓') : _tr(lang, 'Yozishni boshlash', 'Начать запись', 'Tap to record')),
                  style: TextStyle(color: _recording ? colors.error : colors.textSecondary, fontWeight: FontWeight.w700)),
            ]),
          ),
          if (_error == 'permission') Padding(padding: const EdgeInsets.only(top: 12), child: Text(_tr(lang, 'Mikrofon ruxsati kerak.', 'Нужен доступ к микрофону.', 'Microphone permission needed.'), textAlign: TextAlign.center, style: TextStyle(color: colors.warning))),
          if (_error == 'failed') Padding(padding: const EdgeInsets.only(top: 12), child: Text(_tr(lang, 'Baholab bo\'lmadi — qayta urinib ko\'ring.', 'Не удалось оценить.', 'Couldn\'t grade it.'), textAlign: TextAlign.center, style: TextStyle(color: colors.error))),
          if (_recordedPath != null && !_recording) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded),
              label: Text(_submitting ? _tr(lang, 'Baholanmoqda...', 'Оценивается...', 'Grading...') : _tr(lang, 'AI baholashga yuborish', 'Отправить на AI-оценку', 'Submit for AI feedback')),
            ),
          ],
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
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_tr(lang, 'Band ball', 'Балл', 'Band score'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
            Text(r.bandScore != null ? r.bandScore!.toStringAsFixed(1) : '—', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(height: 16),
        if (r.transcript != null && r.transcript!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_tr(lang, 'Transkript', 'Транскрипт', 'Transcript'), style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(r.transcript!, style: TextStyle(color: colors.text, fontSize: 13, height: 1.45)),
            ]),
          ),
          const SizedBox(height: 14),
        ],
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
            crit(_tr(lang, 'Ravonlik (Fluency)', 'Беглость', 'Fluency & Coherence'), r.fluency),
            crit(_tr(lang, 'Lug\'at (Lexical)', 'Лексика', 'Lexical Resource'), r.lexical),
            crit(_tr(lang, 'Grammatika', 'Грамматика', 'Grammar'), r.grammar),
            crit(_tr(lang, 'Talaffuz', 'Произношение', 'Pronunciation'), r.pronunciation),
          ]),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => setState(() { _result = null; _recordedPath = null; }),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Text(_tr(lang, 'Qayta urinish', 'Заново', 'Try again')),
        ),
      ],
    );
  }
}
