import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/widgets/celebration_confetti.dart';
import 'ai_tutor_widget.dart';
import 'mascot.dart';
import 'skill_ui.dart';
import 'study_exit_guard.dart';

enum PracticeMode {
  daily,
  mistakes,
  lightning,
  marathon,
  checkpoint,
  placement,
}

class SkillPracticeScreen extends ConsumerStatefulWidget {
  final PracticeMode mode;
  final String? subjectSlug; // for marathon
  final String? subjectName;
  final int? unitId;

  const SkillPracticeScreen({
    super.key,
    required this.mode,
    this.subjectSlug,
    this.subjectName,
    this.unitId,
  });

  @override
  ConsumerState<SkillPracticeScreen> createState() =>
      _SkillPracticeScreenState();
}

class _SkillPracticeScreenState extends ConsumerState<SkillPracticeScreen> {
  bool _loading = true;
  bool _finished = false;
  bool _saving = false;
  bool _saveError = false;
  bool _loadError = false;
  bool _notFound = false;
  bool _dailyAlreadyDone = false;
  List<PracticeQuestion> _questions = [];
  int _index = 0;
  String? _selected;
  bool _answered = false;
  final List<Map<String, dynamic>> _results = [];
  int _correct = 0;

  int _xpAwarded = 0;
  String? _extraLine;
  List<Map<String, dynamic>> _breakdown = [];

  Timer? _timer;
  int _timeLeft = 0;
  bool get _timed => widget.mode == PracticeMode.lightning;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final repo = ref.read(skillExtrasRepositoryProvider);
    try {
      switch (widget.mode) {
        case PracticeMode.placement:
          _questions = await repo.getPlacement(userId, widget.subjectSlug!);
          break;
        case PracticeMode.checkpoint:
          _questions = await repo.getUnitExam(userId, widget.unitId!);
          break;
        case PracticeMode.daily:
          final d = await repo.getDailyChallenge(userId);
          if (d.completed) {
            _dailyAlreadyDone = true;
          } else {
            _questions = d.questions;
          }
          break;
        case PracticeMode.mistakes:
          _questions = await repo.getMistakes(userId);
          break;
        case PracticeMode.lightning:
          _questions = await repo.getLightning(userId);
          _timeLeft = 60;
          break;
        case PracticeMode.marathon:
          _questions = await repo.getMarathon(userId, widget.subjectSlug ?? '');
          break;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _notFound = true;
      } else {
        _loadError = true;
      }
      _questions = [];
    } catch (e) {
      if (e.toString().contains('404')) {
        _notFound = true;
      } else {
        _loadError = true;
      }
      _questions = [];
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (_timed && _questions.isNotEmpty) _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _finish();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _pick(String option) {
    if (_answered || _saving || _finished) return;
    if (_timed) {
      final q = _questions[_index];
      final isCorrect = option == q.correctAnswer;
      if (isCorrect) {
        _correct++;
        HapticFeedback.lightImpact();
        ref.read(soundServiceProvider).playCorrect();
      } else {
        HapticFeedback.mediumImpact();
        ref.read(soundServiceProvider).playIncorrect();
      }
      _results.add({
        'question_id': q.id,
        'is_correct': isCorrect,
        'user_answer': option,
      });
      if (_index + 1 < _questions.length) {
        setState(() {
          _index++;
          _selected = null;
        });
      } else {
        _finish();
      }
      return;
    }
    setState(() {
      _selected = option;
    });
  }

  void _check() {
    if (_answered || _saving || _finished || _selected == null) return;
    final q = _questions[_index];
    final isCorrect = _selected == q.correctAnswer;
    if (isCorrect) {
      _correct++;
      HapticFeedback.lightImpact();
      ref.read(soundServiceProvider).playCorrect();
    } else {
      HapticFeedback.mediumImpact();
      ref.read(soundServiceProvider).playIncorrect();
    }
    _results.add({
      'question_id': q.id,
      'is_correct': isCorrect,
      'user_answer': _selected,
    });
    setState(() {
      _answered = true;
    });
  }

  void _continueAction() {
    if (!_answered) {
      _check();
      _next();
    } else {
      _next();
    }
  }

  void _next() {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_finished || _saving) return;
    _timer?.cancel();
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    final repo = ref.read(skillExtrasRepositoryProvider);
    setState(() {
      _saving = true;
      _saveError = false;
    });
    if (userId == null) {
      setState(() {
        _saving = false;
        _saveError = true;
      });
      return;
    }
    try {
      switch (widget.mode) {
        case PracticeMode.placement:
          final r = await repo.completePlacement(
            userId,
            widget.subjectSlug!,
            _results,
          );
          _extraLine =
              '${str3(lang, 'Taxminiy daraja', 'Примерный уровень', 'Estimated level')}: ${r['label']}';
          _breakdown = (r['breakdown'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          break;
        case PracticeMode.checkpoint:
          final r = await repo.completeUnitExam(
            userId,
            widget.unitId!,
            _results,
          );
          _xpAwarded = r['xp_awarded'] as int? ?? 0;
          _extraLine = r['passed'] == true
              ? str3(
                  lang,
                  'Keyingi bo‘lim ochildi!',
                  'Следующий раздел открыт!',
                  'Next unit unlocked!',
                )
              : str3(
                  lang,
                  'Takrorlab, yana urinib ko‘ring.',
                  'Повторите и попробуйте снова.',
                  'Review and try again.',
                );
          break;
        case PracticeMode.daily:
          final r = await repo.completeDailyChallenge(userId, _results);
          _xpAwarded = r['xp_awarded'] as int? ?? 0;
          break;
        case PracticeMode.mistakes:
          final r = await repo.completeMistakes(userId, _results);
          _xpAwarded = r['xp_awarded'] as int? ?? 0;
          final remaining = r['remaining'] as int? ?? 0;
          _extraLine = str3(
            lang,
            'Qolgan xatolar: $remaining',
            'Осталось ошибок: $remaining',
            'Mistakes remaining: $remaining',
          );
          break;
        case PracticeMode.lightning:
          final r = await repo.completeLightning(
            userId,
            _correct,
            _results.length,
          );
          _xpAwarded = r['xp_awarded'] as int? ?? 0;
          break;
        case PracticeMode.marathon:
          final r = await repo.completeMarathon(
            userId,
            _correct,
            _results.length,
          );
          _xpAwarded = r['xp_awarded'] as int? ?? 0;
          break;
      }
      if (mounted) {
        ref.read(soundServiceProvider).playLessonComplete();
        setState(() => _finished = true);
      }
    } catch (_) {
      if (mounted) setState(() => _saveError = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color get _accent {
    switch (widget.mode) {
      case PracticeMode.daily:
        return const Color(0xFFF9A825);
      case PracticeMode.mistakes:
        return const Color(0xFFFF4B4B);
      case PracticeMode.lightning:
        return const Color(0xFFFFC800);
      case PracticeMode.marathon:
      case PracticeMode.checkpoint:
      case PracticeMode.placement:
        return const Color(0xFF2A1F6B);
    }
  }

  String _title(String lang) {
    switch (widget.mode) {
      case PracticeMode.placement:
        return str3(
          lang,
          'Darajani aniqlash',
          'Определение уровня',
          'Find your level',
        );
      case PracticeMode.checkpoint:
        return str3(
          lang,
          'Bo‘lim sinovi',
          'Проверка раздела',
          'Unit checkpoint',
        );
      case PracticeMode.daily:
        return str3(
          lang,
          'Kunlik sinov',
          'Ежедневный вызов',
          'Daily challenge',
        );
      case PracticeMode.mistakes:
        return str3(
          lang,
          'Xatolar ustida',
          'Работа над ошибками',
          'Mistakes practice',
        );
      case PracticeMode.lightning:
        return str3(
          lang,
          'Tezlik raundi',
          'Молниеносный раунд',
          'Lightning round',
        );
      case PracticeMode.marathon:
        return '${str3(lang, 'Marafon', 'Марафон', 'Marathon')}${widget.subjectName != null ? ' · ${widget.subjectName}' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) => StudyExitGuard(
    active: !_finished && !_dailyAlreadyDone && _questions.isNotEmpty,
    saving: _saving,
    language: ref.watch(languageProvider),
    child: _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final lang = ref.watch(languageProvider);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_saving) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: Text(_title(lang))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(mood: MascotMood.idle, size: 90),
                const SizedBox(height: 16),
                Text(
                  str3(
                    lang,
                    'Hali tayyorlanmoqda',
                    'Ещё готовится',
                    'Still in preparation',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  str3(
                    lang,
                    'Ushbu fan uchun daraja testi hali tayyorlanmoqda.',
                    'Тест уровня для этого предмета ещё готовится.',
                    'Placement test for this subject is still in preparation.',
                  ),
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(str3(lang, 'Orqaga', 'Назад', 'Back')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_loadError || _saveError) {
      return Scaffold(
        appBar: AppBar(title: Text(_title(lang))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                str3(
                  lang,
                  'Ulanishda xatolik. Qayta urinib ko‘ring.',
                  'Ошибка соединения. Повторите.',
                  'Connection error. Please retry.',
                ),
              ),
              FilledButton(
                onPressed: () {
                  if (_saveError) {
                    _finish();
                  } else {
                    setState(() {
                      _loadError = false;
                      _loading = true;
                    });
                    _load();
                  }
                },
                child: Text(str3(lang, 'Qayta urinish', 'Повторить', 'Retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_dailyAlreadyDone) {
      return Scaffold(
        appBar: AppBar(title: Text(_title(lang))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✅', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 12),
                Text(
                  str3(
                    lang,
                    'Bugungi sinov bajarilgan!',
                    'Сегодняшний вызов пройден!',
                    "Today's challenge is done!",
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  str3(
                    lang,
                    'Ertaga yangisi uchun qaytib keling.',
                    'Возвращайся завтра за новым.',
                    'Come back tomorrow for a new one.',
                  ),
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(str3(lang, 'Orqaga', 'Назад', 'Back')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_finished) {
      return Scaffold(
        body: CelebrationConfetti(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Mascot(mood: MascotMood.cheer, size: 120)
                        .animate()
                        .scale(duration: 450.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 12),
                    Text(
                      str3(lang, 'Tayyor!', 'Готово!', 'Done!'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _stat(
                          '$_correct/${_results.length}',
                          str3(lang, "To'g'ri", 'Правильно', 'Correct'),
                          const Color(0xFF58CC02),
                        ).animate().scale(delay: 250.ms, duration: 300.ms, curve: Curves.easeOutBack),
                        const SizedBox(width: 32),
                        _stat('+$_xpAwarded', 'XP', const Color(0xFFFFC800))
                            .animate()
                            .scale(delay: 350.ms, duration: 300.ms, curve: Curves.easeOutBack),
                      ],
                    ),
                  if (_extraLine != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _extraLine!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                  if (_breakdown.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final level in _breakdown)
                      ListTile(
                        leading: Icon(
                          level['mastered'] == true
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          color: level['mastered'] == true
                              ? const Color(0xFF58CC02)
                              : Colors.grey,
                        ),
                        title: Text('${level['label']}'),
                        trailing: Text('${level['correct']}/${level['asked']}'),
                      ),
                    Text(
                      str3(
                        lang,
                        'Bu mashq natijasi, rasmiy sertifikat emas. Darslar avtomatik ochilmaydi.',
                        'Это оценка по практике, не официальный сертификат. Уроки не открываются автоматически.',
                        'This practice estimate is not an official certificate. It does not automatically unlock lessons.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      str3(lang, 'Davom etish', 'Продолжить', 'Continue'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_title(lang))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Mascot(mood: MascotMood.idle, size: 90),
              const SizedBox(height: 12),
              Text(
                str3(
                  lang,
                  "Hozircha savollar yo'q",
                  'Вопросов пока нет',
                  'No questions yet',
                ),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(str3(lang, 'Orqaga', 'Назад', 'Back')),
              ),
            ],
          ),
        ),
      );
    }

    final q = _questions[_index];
    final isCorrect = _selected == q.correctAnswer;
    final progress = (_index + (_answered ? 1 : 0)) / _questions.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        color: _accent,
                        backgroundColor: Colors.black12,
                      ),
                    ),
                  ),
                  if (_timed)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 18,
                            color: _timeLeft <= 10
                                ? const Color(0xFFFF4B4B)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${_timeLeft}s',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _timeLeft <= 10
                                  ? const Color(0xFFFF4B4B)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      q.questionText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final opt in q.options) _optionTile(opt, q, isCorrect),
                    if (_answered) _feedback(q, isCorrect, lang),
                  ],
                ),
              ),
            ),
            if (!_answered && !_timed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _selected == null
                    ? SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: null,
                          child: Text(
                            str3(lang, 'TEKSHIRISH', 'ПРОВЕРИТЬ', 'CHECK'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: _accent, width: 2),
                              ),
                              onPressed: _check,
                              child: Text(
                                str3(lang, 'TEKSHIRISH', 'ПРОВЕРИТЬ', 'CHECK'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _accent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _continueAction,
                              child: Text(
                                str3(lang, 'Davom etish', 'Далее', 'Continue'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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

  Widget _stat(String value, String label, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ],
  );

  Widget _optionTile(String opt, PracticeQuestion q, bool isCorrect) {
    final isSelectedBeforeAnswer = !_answered && _selected == opt;
    final showCorrect = _answered && opt == q.correctAnswer;
    final showWrong = _answered && _selected == opt && !isCorrect;
    Color border = Colors.black12;
    Color? bg;
    if (showCorrect) {
      border = const Color(0xFF58CC02);
      bg = const Color(0xFF58CC02).withValues(alpha: 0.10);
    } else if (showWrong) {
      border = const Color(0xFFFF4B4B);
      bg = const Color(0xFFFF4B4B).withValues(alpha: 0.10);
    } else if (isSelectedBeforeAnswer) {
      border = _accent;
      bg = _accent.withValues(alpha: 0.12);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _answered ? null : () => _pick(opt),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
          ),
          child: Text(
            opt,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _feedback(PracticeQuestion q, bool isCorrect, String lang) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isCorrect ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B))
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect
                ? str3(lang, 'Ajoyib!', 'Отлично!', 'Nice!')
                : str3(lang, "Noto'g'ri", 'Неправильно', 'Incorrect'),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isCorrect
                  ? const Color(0xFF3A8A00)
                  : const Color(0xFFC81E1E),
            ),
          ),
          if (q.explanation != null && q.explanation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                q.explanation!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
          if (!isCorrect)
            AiTutorWidget(
              questionText: q.questionText,
              options: q.options,
              correctAnswer: q.correctAnswer,
              userAnswer: _selected,
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _next,
              child: Text(
                str3(lang, 'Davom etish', 'Далее', 'Continue'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
