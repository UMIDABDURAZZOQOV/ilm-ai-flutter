import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/ilm_state_view.dart';
import 'lesson_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/motion.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/widgets/celebration_confetti.dart';
import 'mascot.dart';
import 'skill_ui.dart';
import 'study_exit_guard.dart';
import 'content_source_button.dart';

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
  DateTime? _deadline;
  String? get _attemptId =>
      _questions.isEmpty ? null : _questions.first.attemptId;
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
    _deadline = DateTime.now().add(Duration(seconds: _timeLeft));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final remaining = _deadline!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        t.cancel();
        _finish();
      } else {
        setState(() => _timeLeft = remaining);
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
        'answer_index': q.options.indexOf(option),
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
      'answer_index': q.options.indexOf(_selected!),
      'is_correct': isCorrect,
      'user_answer': _selected,
    });
    setState(() {
      _answered = true;
    });
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
            attemptId: _attemptId,
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
            attemptId: _attemptId,
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
          final r = await repo.completeDailyChallenge(
            userId,
            _results,
            attemptId: _attemptId,
          );
          _xpAwarded = r['xp_awarded'] as int? ?? 0;
          break;
        case PracticeMode.mistakes:
          final r = await repo.completeMistakes(
            userId,
            _results,
            attemptId: _attemptId,
          );
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
            attemptId: _attemptId,
            results: _results,
          );
          _xpAwarded = r['xp_awarded'] as int? ?? 0;
          break;
        case PracticeMode.marathon:
          final r = await repo.completeMarathon(
            userId,
            _correct,
            _results.length,
            attemptId: _attemptId,
            results: _results,
          );
          _xpAwarded = r['xp_awarded'] as int? ?? 0;
          break;
      }
      if (mounted) {
        ref.read(studyRevisionProvider.notifier).state++;
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
    final c = Theme.of(context).extension<AppColors>()!.colors;

    if (_loading) {
      return Scaffold(body: IlmLoadingView(language: lang));
    }

    if (_saving) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  str3(
                    lang,
                    'Natija saqlanmoqda',
                    'Сохраняем результат',
                    'Saving your result',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: Text(_title(lang))),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MascotImage(pose: MascotPose.thinking, size: 110),
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
                  style: Theme.of(context).textTheme.bodySmall,
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
        body: IlmStateView(
          title: str3(
            lang,
            'Ulanishda xatolik',
            'Ошибка соединения',
            'Connection error',
          ),
          message: _saveError
              ? str3(
                  lang,
                  'Natija saqlanmadi. Qayta urinish mumkin.',
                  'Результат не сохранён. Можно повторить отправку.',
                  'Your result was not saved. You can retry.',
                )
              : str3(
                  lang,
                  'Ulanishni tekshirib, qayta urinib ko‘ring.',
                  'Проверьте подключение и повторите попытку.',
                  'Check your connection and try again.',
                ),
          retryLabel: str3(lang, 'Qayta urinish', 'Повторить', 'Retry'),
          onRetry: () {
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
        ),
      );
    }

    if (_dailyAlreadyDone) {
      return Scaffold(
        appBar: AppBar(title: Text(_title(lang))),
        body: Center(
          child: SingleChildScrollView(
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
                  style: Theme.of(context).textTheme.bodySmall,
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
                    // Do not chain flutter_animate `.motion(context)` on MascotImage —
                    // it has a bool field named `animate` that shadows the extension.
                    const MascotImage(pose: MascotPose.happy, size: 170),
                    const SizedBox(height: 12),
                    Text(
                          str3(lang, 'Tayyor!', 'Готово!', 'Done!'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                        .motion(context)
                        .fadeIn(duration: 250.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _stat(
                              '$_correct/${_results.length}',
                              str3(lang, "To'g'ri", 'Правильно', 'Correct'),
                              c.success,
                            )
                            .motion(context)
                            .scale(
                              delay: 250.ms,
                              duration: 300.ms,
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(width: 32),
                        _stat('+$_xpAwarded', 'XP', c.warning)
                            .motion(context)
                            .scale(
                              delay: 350.ms,
                              duration: 300.ms,
                              curve: Curves.easeOutBack,
                            ),
                      ],
                    ),
                    if (_extraLine != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _extraLine!,
                        style: Theme.of(context).textTheme.bodySmall,
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
                          trailing: Text(
                            '${level['correct']}/${level['asked']}',
                          ),
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
                        foregroundColor: foregroundOn(_accent),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MascotImage(pose: MascotPose.thinking, size: 110),
                const SizedBox(height: 12),
                Text(
                  str3(
                    lang,
                    "Hozircha savollar yo'q",
                    'Вопросов пока нет',
                    'No questions yet',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
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

    final q = _questions[_index];
    final isCorrect = _selected == q.correctAnswer;
    final progress = (_index + (_answered ? 1 : 0)) / _questions.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LessonStepHeader(
              label:
                  '${str3(lang, 'Savol', 'Вопрос', 'Question')} ${_index + 1}/${_questions.length}${_timed ? ' · $_timeLeft s' : ''}',
              progress: progress,
              language: lang,
              onClose: () => Navigator.of(context).maybePop(),
              uzbekContent:
                  (q.source != null && lang != 'uz') ||
                  looksLikeUntranslatedUzbek(q.questionText, lang),
            ),
            Expanded(
              child: IlmReadingWidth(
                child: SingleChildScrollView(
                  key: ValueKey(q.id),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_answered)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: MascotImage(
                              pose: MascotPose.thinking,
                              size: 72,
                            ),
                          ),
                        ),
                      if (_index == 0 &&
                          ((q.source != null && lang != 'uz') ||
                              looksLikeUntranslatedUzbek(q.questionText, lang)))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ContentLanguageBadge(language: lang),
                        ),
                      Text(
                        q.questionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      if (q.source != null)
                        ContentSourceButton(source: q.source!, language: lang),
                      const SizedBox(height: 20),
                      for (final opt in q.options)
                        DuoChoiceCard(
                          text: opt,
                          selected: _selected == opt,
                          answered: _answered,
                          isCorrectOption: opt == q.correctAnswer,
                          stateLabel: _answered && opt == q.correctAnswer
                              ? str3(
                                  lang,
                                  'To‘g‘ri javob',
                                  'Правильный ответ',
                                  'Correct answer',
                                )
                              : _selected == opt
                              ? str3(lang, 'Tanlandi', 'Выбрано', 'Selected')
                              : null,
                          onTap: () => _pick(opt),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_answered && !_timed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Duo3DButton(
                  onPressed: _selected == null ? null : _check,
                  child: Text(str3(lang, 'TEKSHIRISH', 'ПРОВЕРИТЬ', 'CHECK')),
                ),
              ),
            if (_answered) _feedbackDock(q, isCorrect, lang),
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
          color:
              Theme.of(context).brightness == Brightness.light &&
                  color.computeLuminance() > 0.30
              ? BrandPalette.indigo
              : color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _feedbackDock(PracticeQuestion q, bool isCorrect, String lang) =>
      LessonFeedbackPanel(
        language: lang,
        correct: isCorrect,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation ?? '',
        onContinue: _next,
      );
}
