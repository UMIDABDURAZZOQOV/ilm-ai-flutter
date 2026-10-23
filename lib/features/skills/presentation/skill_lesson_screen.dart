import '../../../core/widgets/motion.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/ilm_state_view.dart';
import 'lesson_widgets.dart';
import '../../../core/utils/math_text.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/network/dio_client.dart' show apiBaseUrl;
import '../../../core/network/error_message.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import '../data/lesson_draft_store.dart';
import 'mascot.dart';
import 'skill_ui.dart';
import 'lesson_completion_view.dart';
import 'content_source_button.dart';
import 'study_exit_guard.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/widgets/celebration_confetti.dart';

class SkillLessonScreen extends ConsumerStatefulWidget {
  final SkillTreeLesson lesson;
  const SkillLessonScreen({super.key, required this.lesson});

  @override
  ConsumerState<SkillLessonScreen> createState() => _SkillLessonScreenState();
}

// `learning` is the Duolingo-style teach-first phase: the lesson's theory
// cards are shown one at a time BEFORE any question appears.
enum _Phase { loading, learning, playing, error, finished }

class _SkillLessonScreenState extends ConsumerState<SkillLessonScreen> {
  _Phase _phase = _Phase.loading;
  int? _attemptId;
  List<TheoryCard> _theory = [];
  int _theoryIndex = 0;
  List<SkillQuestion> _questions = [];
  int _index = 0;
  String? _selected;
  bool _answered = false;
  bool _submitting = false;
  bool _saveFailed = false;
  final List<LessonResultItem> _results = [];
  final List<int> _mistakes = [];
  bool _reviewing = false;
  final Stopwatch _timer = Stopwatch()..start();
  LessonCompleteResult? _completion;
  late final int? _owner;
  LessonDraftStore? _drafts;
  Map<String, dynamic>? _startSnapshot;
  String? _contentLanguage;
  Object? _loadError;
  bool _expired = false;
  bool _draftFailed = false;
  int _elapsedBeforeRestore = 0;
  int _startedAt = 0;
  bool get _active => mounted && ref.read(currentUserIdProvider) == _owner;

  bool _uzbekContent(String language) {
    if (language == 'uz') return false;
    if (_contentLanguage != null) return _contentLanguage == 'uz';
    return widget.lesson.slug.startsWith('biology-') ||
        looksLikeUntranslatedUzbek(
          '${_theory.map((c) => '${c.title} ${c.body}').join(' ')} ${_questions.map((q) => q.questionText).join(' ')}',
          language,
        );
  }

  Map<String, dynamic> get _draft => {
    'start': _startSnapshot,
    'phase': _phase.name,
    'index': _index,
    'theory_index': _theoryIndex,
    'selected': _selected,
    'answered': _answered,
    'reviewing': _reviewing,
    'results': _results.map((r) => r.toJson()).toList(),
    'mistakes': List<int>.of(_mistakes),
    'elapsed_ms': _elapsedBeforeRestore + _timer.elapsedMilliseconds,
    'started_at': _startedAt,
  };

  Future<void> _persist() async {
    if (_drafts == null || _startSnapshot == null || !_active) return;
    await _drafts!.save(_draft);
  }

  void _remember() {
    unawaited(
      _persist()
          .then((_) {
            if (_active && _draftFailed) setState(() => _draftFailed = false);
          })
          .catchError((Object _) {
            if (_active) setState(() => _draftFailed = true);
          }),
    );
  }

  @override
  void initState() {
    super.initState();
    _owner = ref.read(currentUserIdProvider);
    if (_owner != null) {
      _drafts = LessonDraftStore(
        ref.read(prefsServiceProvider),
        apiBaseUrl,
        _owner,
        widget.lesson.id,
      );
    }
    _start();
  }

  Future<void> _start({bool fresh = false}) async {
    final userId = _owner;
    if (userId == null || !_active) return;
    setState(() {
      _phase = _Phase.loading;
      _loadError = null;
    });
    final language = ref.read(languageProvider);
    try {
      if (fresh) {
        await _drafts?.clear();
        if (!_active) return;
      }
      final draft = fresh ? null : _drafts?.read();
      if (draft != null) {
        final age =
            DateTime.now().millisecondsSinceEpoch -
            (draft['started_at'] as int);
        if (age < 0 || age >= const Duration(hours: 24).inMilliseconds) {
          setState(() {
            _expired = true;
            _phase = _Phase.error;
          });
          return;
        }
        final start = Map<String, dynamic>.from(draft['start'] as Map);
        final restored = LessonStartResult.fromJson(start);
        setState(() {
          _startSnapshot = start;
          _contentLanguage = restored.contentLanguage;
          _attemptId = restored.attemptId;
          _theory = restored.theory;
          _questions = restored.questions;
          _index = draft['index'] as int;
          _theoryIndex = draft['theory_index'] as int;
          _selected = draft['selected'] as String?;
          _answered = draft['answered'] as bool;
          _reviewing = draft['reviewing'] as bool;
          _startedAt = draft['started_at'] as int;
          _elapsedBeforeRestore = draft['elapsed_ms'] as int;
          _timer.reset();
          _results
            ..clear()
            ..addAll(
              (draft['results'] as List).map(
                (r) => LessonResultItem(
                  questionId: r['question_id'] as int,
                  userAnswer: r['user_answer'] as String,
                  isCorrect: r['is_correct'] as bool,
                ),
              ),
            );
          _mistakes
            ..clear()
            ..addAll((draft['mistakes'] as List).cast<int>());
          _phase = draft['phase'] == 'learning'
              ? _Phase.learning
              : _Phase.playing;
        });
        return;
      }
      final res = await ref
          .read(skillTreeRepositoryProvider)
          .startLesson(
            lessonId: widget.lesson.id,
            userId: userId,
            language: language,
          );
      if (!_active) return;
      if (res.questions.isEmpty) {
        setState(() => _phase = _Phase.error);
        return;
      }
      setState(() {
        _expired = false;
        _startSnapshot = LessonDraftStore.snapshot(res);
        _contentLanguage = res.contentLanguage;
        _startedAt = DateTime.now().millisecondsSinceEpoch;
        _elapsedBeforeRestore = 0;
        _timer
          ..reset()
          ..start();
        _theoryIndex = 0;
        _index = 0;
        _selected = null;
        _answered = false;
        _reviewing = false;
        _saveFailed = false;
        _results.clear();
        _mistakes.clear();
        _attemptId = res.attemptId;
        _theory = res.theory;
        _questions = res.questions;
        _phase = _theory.isNotEmpty ? _Phase.learning : _Phase.playing;
      });
      _remember();
    } catch (error) {
      if (!_active) return;
      setState(() {
        _loadError = error;
        _phase = _Phase.error;
      });
    }
  }

  void _nextTheoryCard() {
    if (_theoryIndex + 1 < _theory.length) {
      setState(() => _theoryIndex++);
    } else {
      setState(() => _phase = _Phase.playing);
    }
    _remember();
  }

  SkillQuestion get _current => _questions[_index];

  void _pick(String option) {
    if (_answered) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = option);
    _remember();
  }

  void _check() {
    final option = _selected;
    if (_answered || option == null) return;
    final isCorrect = option == _current.correctAnswer;
    if (isCorrect) {
      HapticFeedback.lightImpact();
      ref.read(soundServiceProvider).playCorrect();
    } else {
      HapticFeedback.mediumImpact();
      ref.read(soundServiceProvider).playIncorrect();
    }
    setState(() {
      _selected = option;
      _answered = true;
      if (!_reviewing) {
        if (!isCorrect) _mistakes.add(_index);
        _results.add(
          LessonResultItem(
            questionId: _current.id,
            userAnswer: option,
            isCorrect: isCorrect,
          ),
        );
      }
    });
    _remember();
  }

  Future<void> _next() async {
    if (_submitting || !_answered) return;
    if (_reviewing && _selected != _current.correctAnswer) {
      setState(() {
        _selected = null;
        _answered = false;
      });
      _remember();
      return;
    }
    if (!_reviewing && _index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
      _remember();
      return;
    }
    if (_mistakes.isNotEmpty) {
      setState(() {
        _reviewing = true;
        _index = _mistakes.removeAt(0);
        _selected = null;
        _answered = false;
      });
      _remember();
      return;
    }
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _attemptId == null || !_active) return;
    setState(() {
      _submitting = true;
      _saveFailed = false;
    });
    try {
      await _persist();
      if (!_active) return;
      final res = await ref
          .read(skillTreeRepositoryProvider)
          .completeLesson(
            lessonId: widget.lesson.id,
            userId: userId,
            attemptId: _attemptId!,
            results: List<LessonResultItem>.of(_results),
          );
      if (!_active) return;
      ref.read(studyRevisionProvider.notifier).state++;
      if (res.stars > 0) ref.read(soundServiceProvider).playLessonComplete();
      setState(() {
        _timer.stop();
        _completion = res;
        _phase = _Phase.finished;
        _draftFailed = false;
      });
      // Cleanup failure must not turn an acknowledged completion into an error.
      await _drafts?.clear().catchError((Object _) {});
    } catch (error) {
      if (_active) {
        final detail = error is DioException && error.response?.data is Map
            ? (error.response!.data as Map)['detail']
            : null;
        setState(() {
          _saveFailed = true;
          if (detail == 'study_session_expired' ||
              detail == 'study_session_required') {
            _expired = true;
            _phase = _Phase.error;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showAnswers() async {
    final language = ref.read(languageProvider);
    final answers = {
      for (final result in _results) result.questionId: result.userAnswer,
    };
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          if (ref.watch(currentUserIdProvider) != _owner) {
            return const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Icon(Icons.lock_outline_rounded),
              ),
            );
          }
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .8,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    str3(
                      language,
                      'Javoblaringiz',
                      'Ваши ответы',
                      'Your answers',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_uzbekContent(language))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ContentLanguageBadge(language: language),
                    ),
                  for (final question in _questions.where(
                    (q) => answers.containsKey(q.id),
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                cleanMath(question.questionText),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                str3(
                                  language,
                                  'Sizning javobingiz',
                                  'Ваш ответ',
                                  'Your answer',
                                ),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(cleanMath(answers[question.id]!)),
                              const SizedBox(height: 8),
                              Text(
                                str3(
                                  language,
                                  'Darsdagi javob',
                                  'Ответ из урока',
                                  'Lesson answer',
                                ),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(cleanMath(question.correctAnswer)),
                              if (question.explanation?.isNotEmpty == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(cleanMath(question.explanation!)),
                                ),
                              if (question.source != null)
                                ContentSourceButton(
                                  source: question.source!,
                                  language: language,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StudyExitGuard(
    active:
        ref.watch(currentUserIdProvider) == _owner &&
        _phase != _Phase.finished &&
        _phase != _Phase.error,
    saving: ref.watch(currentUserIdProvider) == _owner && _submitting,
    saveBeforeExit: _drafts != null && _startSnapshot != null
        ? () async {
            try {
              if (!_active) return false;
              await _persist();
              if (!_active) return false;
              if (_draftFailed) setState(() => _draftFailed = false);
              return true;
            } catch (_) {
              if (_active) setState(() => _draftFailed = true);
              return false;
            }
          }
        : null,
    language: ref.watch(languageProvider),
    child: Column(
      children: [
        if (_draftFailed &&
            _phase != _Phase.finished &&
            ref.watch(currentUserIdProvider) == _owner)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .3,
            ),
            child: SingleChildScrollView(
              child: Material(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          str3(
                            ref.watch(languageProvider),
                            'Darsni qurilmada saqlab bo‘lmadi. Ilovani yopishdan oldin qayta urinib ko‘ring.',
                            'Не удалось сохранить урок на устройстве. Повторите перед закрытием приложения.',
                            'Could not save this lesson on the device. Retry before closing the app.',
                          ),
                        ),
                        TextButton(
                          onPressed: _remember,
                          child: Text(
                            str3(
                              ref.watch(languageProvider),
                              'Qayta urinish',
                              'Повторить',
                              'Retry',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(child: _buildContent(context)),
      ],
    ),
  );

  Widget _buildContent(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    if (ref.watch(currentUserIdProvider) != _owner) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              str3(
                language,
                'Sessiya o‘zgardi. Darsni qayta oching.',
                'Сеанс изменился. Откройте урок заново.',
                'Session changed. Reopen the lesson.',
              ),
            ),
          ),
        ),
      );
    }

    if (_phase == _Phase.loading) {
      return Scaffold(body: IlmLoadingView(language: language));
    }

    if (_phase == _Phase.error) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MascotImage(pose: MascotPose.sad, size: 110),
                  const SizedBox(height: 16),
                  Text(
                    _expired
                        ? str3(
                            language,
                            'Urinish muddati tugadi. Saqlangan natijalar qoladi; darsni yangidan boshlang.',
                            'Срок попытки истёк. Сохранённые результаты останутся; начните урок заново.',
                            'This attempt expired. Saved results are preserved; start the lesson again.',
                          )
                        : _loadError == null
                        ? t('skills.error.generic', language)
                        : extractError(_loadError!, language: language),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Duo3DButton(
                    onPressed: () => _start(fresh: _expired),
                    child: Text(
                      _expired
                          ? str3(
                              language,
                              'Yangidan boshlash',
                              'Начать заново',
                              'Start again',
                            )
                          : str3(
                              language,
                              'Qayta urinish',
                              'Повторить',
                              'Retry',
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(t('skills.back', language)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_phase == _Phase.learning) {
      final card = _theory[_theoryIndex];
      final learnProgress = (_theoryIndex + 1) / _theory.length;
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              LessonStepHeader(
                label:
                    '${str3(language, 'Nazariya', 'Теория', 'Theory')} ${_theoryIndex + 1}/${_theory.length}',
                progress: learnProgress,
                language: language,
                uzbekContent: _uzbekContent(language),
                onClose: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey('theory-scroll-$_theoryIndex'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: IlmReadingWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_theoryIndex == 0 && _uzbekContent(language)) ...[
                          ContentLanguageBadge(language: language),
                          const SizedBox(height: 16),
                        ],
                        Container(
                              key: ValueKey(_theoryIndex),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(
                                  IlmRadius.card,
                                ),
                                border: Border.all(
                                  color: colors.border,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          card.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const MascotImage(
                                        pose: MascotPose.explaining,
                                        size: 72,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    card.body,
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 1.6,
                                      color: colors.text,
                                    ),
                                  ),
                                  if (card.source != null)
                                    ContentSourceButton(
                                      source: card.source!,
                                      language: language,
                                    ),
                                  if (card.example != null &&
                                      card.example!.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: colors.card,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: colors.accent.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t(
                                              'skills.example',
                                              language,
                                            ).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1,
                                              color: colors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            card.example!,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              height: 1.4,
                                              color: colors.text,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                            .motion(
                              context,
                              key: ValueKey('theory_$_theoryIndex'),
                            )
                            .fadeIn(duration: 250.ms)
                            .slideX(
                              begin: 0.08,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Duo3DButton(
                  onPressed: _nextTheoryCard,
                  child: Text(
                    _theoryIndex + 1 < _theory.length
                        ? t('skills.lesson.continue', language)
                        : t('skills.start_quiz', language),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_phase == _Phase.finished && _completion != null) {
      final c = _completion!;
      final result = LessonCompletionView(
        language: language,
        title: c.stars > 0
            ? t('skills.complete.title', language)
            : str3(
                language,
                'Yana bir bor mashq qilamiz!',
                'Попробуем ещё раз!',
                'Let’s practise again!',
              ),
        lessonTitle: widget.lesson.titleFor(language),
        xp: c.xpAwarded,
        correct: c.score,
        total: c.total,
        stars: c.stars,
        streakDays: c.streakDays,
        elapsed: Duration(
          milliseconds: _elapsedBeforeRestore + _timer.elapsedMilliseconds,
        ),
        onReview: _showAnswers,
        onBack: () => Navigator.of(context).maybePop(),
      );
      return Scaffold(
        body: c.stars > 0 ? CelebrationConfetti(child: result) : result,
      );
    }

    final q = _current;
    final isCorrect = _selected == q.correctAnswer;
    final reviewTotal = _results.where((r) => !r.isCorrect).length;
    final reviewPosition = reviewTotal - _mistakes.length;
    final progress = _reviewing
        ? reviewTotal == 0
              ? 0.0
              : ((reviewPosition - 1 + (_answered && isCorrect ? 1 : 0)) /
                        reviewTotal)
                    .clamp(0.0, 1.0)
        : (_index + (_answered ? 1 : 0)) / _questions.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LessonStepHeader(
              label: _reviewing
                  ? '${str3(language, 'Takrorlash', 'Закрепление', 'Review')} $reviewPosition/$reviewTotal'
                  : '${str3(language, 'Savol', 'Вопрос', 'Question')} ${_index + 1}/${_questions.length}',
              progress: progress,
              language: language,
              uzbekContent: _uzbekContent(language),
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey('question-scroll-${q.id}-$_reviewing'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: IlmReadingWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_reviewing) ...[
                        Text(
                          str3(
                            language,
                            'XATOLARNI MUSTAHKAMLASH',
                            'РАБОТА НАД ОШИБКАМИ',
                            'REVIEW YOUR MISTAKES',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!_answered) ...[
                        const Center(
                          child: MascotImage(
                            pose: MascotPose.thinking,
                            size: 72,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!_answered &&
                          _theory.isEmpty &&
                          _index == 0 &&
                          _uzbekContent(language))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ContentLanguageBadge(language: language),
                        ),
                      Text(
                        cleanMath(q.questionText),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                          height: 1.4,
                        ),
                      ),
                      if (q.source != null)
                        ContentSourceButton(
                          source: q.source!,
                          language: language,
                        ),
                      const SizedBox(height: 24),
                      for (final option in q.options)
                        DuoChoiceCard(
                          text: cleanMath(option),
                          answered: _answered,
                          selected: _selected == option,
                          isCorrectOption: option == q.correctAnswer,
                          stateLabel: _answered && option == q.correctAnswer
                              ? str3(
                                  language,
                                  'To‘g‘ri javob',
                                  'Правильный ответ',
                                  'Correct answer',
                                )
                              : _answered && _selected == option
                              ? str3(
                                  language,
                                  'Bu javob mos kelmadi',
                                  'Этот ответ не подходит',
                                  'This answer does not fit',
                                )
                              : _selected == option
                              ? str3(
                                  language,
                                  'Tanlandi',
                                  'Выбрано',
                                  'Selected',
                                )
                              : null,
                          onTap: () => _pick(option),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_answered)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Duo3DButton(
                  onPressed: _selected == null ? null : _check,
                  child: Text(
                    str3(language, 'TEKSHIRISH', 'ПРОВЕРИТЬ', 'CHECK'),
                  ),
                ),
              ),
            if (_answered)
              LessonFeedbackPanel(
                saveError: _saveFailed
                    ? str3(
                        language,
                        'Natija saqlanmadi. Davom etish tugmasi bilan qayta urinib ko‘ring.',
                        'Результат не сохранён. Нажмите «Продолжить», чтобы повторить.',
                        'Result not saved. Tap Continue to retry.',
                      )
                    : null,
                language: language,
                correct: isCorrect,
                correctAnswer: cleanMath(q.correctAnswer),
                explanation: q.explanation == null
                    ? ''
                    : cleanMath(q.explanation!),
                reviewHint: !isCorrect && !_reviewing,
                saving: _submitting,
                onContinue: _next,
              ),
          ],
        ),
      ),
    );
  }
}
