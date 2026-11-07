import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/mascot_image.dart';
import '../../auth/application/auth_controller.dart';
import '../../skills/data/skill_tree_models.dart';
import '../../skills/presentation/skill_ui.dart';
import '../../skills/presentation/lesson_feedback_panel.dart';
import '../../skills/presentation/lesson_completion_view.dart';
import '../../skills/presentation/study_exit_dialog.dart';
import '../../skills/presentation/content_source_button.dart';
import '../../physics/presentation/physics_answer_editor.dart';
import '../../chemistry/presentation/chemistry_answer_editor.dart';
import '../../chemistry/presentation/chemistry_display_text.dart';
import '../../world_history/presentation/world_history_answer_editor.dart';
import '../../world_history/presentation/world_history_display_text.dart';
import '../../uzbekistan_history/presentation/history_answer_editor.dart';
import '../data/assessment_repository.dart';
import '../../study_help/study_help.dart';
import '../../../core/config/integrated_beta.dart';

/// Shared branded lesson flow. Existing subject editors and server runtimes
/// retain their specialised answer formats, source links and grading semantics.
class AssessmentLessonScreen extends ConsumerWidget {
  const AssessmentLessonScreen({super.key, required this.lesson});
  final SkillTreeLesson lesson;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Akkauntingizga kiring.')),
      );
    }
    return _AssessmentSession(
      key: ValueKey('$uid:${lesson.assessmentKey}'),
      userId: uid,
      lesson: lesson,
    );
  }
}

class _AssessmentSession extends ConsumerStatefulWidget {
  const _AssessmentSession({
    super.key,
    required this.userId,
    required this.lesson,
  });
  final int userId;
  final SkillTreeLesson lesson;
  @override
  ConsumerState<_AssessmentSession> createState() => _AssessmentSessionState();
}

class _AssessmentSessionState extends ConsumerState<_AssessmentSession> {
  final _scroll = ScrollController();
  final _feedbackKey = GlobalKey();
  CancelToken _cancel = CancelToken();
  Json? _catalog, _attempt, _feedback, _result;
  List<Json> _questionRows = const [], _teachingRows = const [];
  Json _saved = {}, _draft = {};
  String? _lessonKey, _error;
  bool _busy = false,
      _teaching = true,
      _expired = false,
      _allowExit = false,
      _exitDialog = false;
  int _index = 0, _generation = 0, _teachingIndex = 0;
  Future<void> _writes = Future.value();
  String get _subject => widget.lesson.assessmentSubject!;
  int get _grade => widget.lesson.grade!;
  String get _language => ref.read(languageProvider);
  String _t(String uz, String ru, String en) => str3(_language, uz, ru, en);
  AssessmentRepository get _repo =>
      ref.read(assessmentRepositoryProvider(_subject));
  bool active(int generation) =>
      mounted &&
      generation == _generation &&
      ref.read(currentUserIdProvider) == widget.userId;
  String get _storageKey => AssessmentRepository.storageKey(
    _repo.dio.options.baseUrl,
    widget.userId,
    _subject,
    _lessonKey!,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(_prepare);
  }

  @override
  void dispose() {
    _generation++;
    _cancel.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Beta already has the selected lesson descriptor and hides bibliography.
      // Fetch the fresh catalogue only when choosing the next unlocked lesson.
      if (!reviewedLearning) {
        final catalog = await _repo.catalog(_cancel, grade: _grade);
        if (!active(generation)) return;
        _catalog = catalog;
      }
      await _open(widget.lesson.assessmentKey!);
    } catch (error) {
      if (active(generation)) {
        setState(() {
          _error = message(error);
          _busy = false;
        });
      }
    }
  }

  void _top({bool feedback = false}) {
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (active(generation) && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  String message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final detail = data is Map ? data['detail'] : null;
      if (detail is Map && detail['feedback'] is String) {
        return detail['feedback'] as String;
      }
      if (detail == 'attempt_expired') {
        return _t(
          'Urinish muddati tugadi. Oldingi natija saqlanadi; yangi urinishni boshlang.',
          'Срок попытки истёк. Результат сохранён; начните новую попытку.',
          'Attempt expired. Previous progress is safe; start a new attempt.',
        );
      }
    }
    return extractError(error, language: _language);
  }

  Future<void> _persist() {
    final key = _storageKey, value = jsonEncode(_saved);
    final prefs = ref.read(prefsServiceProvider);
    _writes = _writes
        .catchError((_) {})
        .then((_) => prefs.setString(key, value));
    return _writes;
  }

  void _remember(Json draft) {
    _draft = draft;
    (_saved['drafts'] as Json)[_question['key'] as String] = draft;
    final generation = _generation;
    unawaited(
      _persist().catchError((Object e) {
        if (active(generation)) {
          setState(
            () => _error =
                'Qurilmada qoralamani saqlab bo‘lmadi. Xotirani tekshiring.',
          );
        }
      }),
    );
  }

  Future<void> _open(String key, {bool fresh = false}) async {
    final generation = ++_generation;
    _cancel.cancel();
    _cancel = CancelToken();
    setState(() {
      _busy = true;
      _error = null;
      _expired = false;
      _lessonKey = key;
    });
    try {
      final raw = fresh
          ? null
          : ref.read(prefsServiceProvider).getString(_storageKey);
      Json? restored;
      try {
        restored = raw == null
            ? null
            : Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        restored = null;
      }
      _saved =
          restored != null &&
              restored['request_id'] is String &&
              restored['drafts'] is Map
          ? restored
          : {
              'request_id': AssessmentRepository.requestId(),
              'drafts': <String, dynamic>{},
              'teaching_done': false,
              'started_at': DateTime.now().millisecondsSinceEpoch,
              'teaching_index': 0,
            };
      await _persist(); // Store the request ID BEFORE a potentially lost response.
      if (!active(generation)) return;
      final data = await _repo.start(
        key,
        _saved['request_id'] as String,
        _cancel,
      );
      if (!active(generation)) return;
      final answered = Map<String, dynamic>.from(data['answers'] as Map);
      final questions = jsonRows(data['questions']);
      final index = questions.indexWhere(
        (q) => !answered.containsKey(q['key']),
      );
      final pending = _pending;
      if (pending != null && answered.containsKey(pending['key'])) {
        _saved.remove('pending');
        await _persist();
        if (!active(generation)) return;
      }
      setState(() {
        _attempt = data;
        _questionRows = List.unmodifiable(questions);
        _teachingRows = List.unmodifiable(_buildTeachingItems(data));
        _feedback = null;
        _result = data['result'] as Json?;
        _index = index < 0 ? questions.length : index;
        _teaching = _saved['teaching_done'] != true && answered.isEmpty;
        _teachingIndex = (_saved['teaching_index'] as int? ?? 0).clamp(
          0,
          _teachingItems.length - 1,
        );
        _saved['question_total'] = questions.length;
        _saved['question_index'] = _index;
        _saved['theory_total'] = _teachingItems.length;
        _draft = _index < questions.length
            ? Map<String, dynamic>.from(
                (_saved['drafts'] as Map)[questions[_index]['key']] as Map? ??
                    {},
              )
            : {};
      });
      if (_result != null) {
        ref.read(studyRevisionProvider.notifier).state++;
      }
      await _persist();
      // A completed path node means "practise again". Keep an unfinished review
      // resumable, but do not strand a new review on the previous result page.
      if (_result != null &&
          widget.lesson.status == LessonStatus.completed &&
          !fresh) {
        await _open(key, fresh: true);
        return;
      }
      _top();
    } catch (e) {
      if (active(generation)) {
        setState(() {
          _error = message(e);
          _expired =
              e is DioException &&
              e.response?.data is Map &&
              (e.response!.data as Map)['detail'] == 'attempt_expired';
        });
      }
    } finally {
      if (active(generation)) setState(() => _busy = false);
    }
  }

  List<Json> get _questions => _questionRows;
  Json get _question => _questions[_index];
  Json? get _pending => _saved['pending'] is Map
      ? Map<String, dynamic>.from(_saved['pending'] as Map)
      : null;

  Future<void> _submit() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pending =
          _pending ??
          {
            'key': _question['key'],
            'answer': Map<String, dynamic>.from(_draft),
          };
      _saved['pending'] = pending;
      await _persist(); // Freeze the exact payload through timeout/restart/retry.
      if (!active(generation)) return;
      final result = await _repo.answer(
        _attempt!['attempt_id'] as String,
        pending['key'] as String,
        Map<String, dynamic>.from(pending['answer'] as Map),
        _cancel,
      );
      if (!active(generation)) return;
      _saved.remove('pending');
      setState(() => _feedback = result);
      _saved['question_index'] = _index + 1;
      _top(feedback: true);
      // A local write failure must not hide an answer already saved by server.
      // On reopening, /start reconciles any older persisted pending payload.
      await _persist();
    } catch (e) {
      if (active(generation)) {
        if (e is DioException && e.response?.statusCode == 422) {
          // Server confirms no answer was committed; syntax can be corrected.
          _saved.remove('pending');
          try {
            await _persist();
          } catch (_) {
            /* Visible original error below. */
          }
        }
        if (active(generation)) {
          setState(() => _error = message(e));
          _top();
        }
      }
    } finally {
      if (active(generation)) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    if (_busy) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _repo.complete(
        _attempt!['attempt_id'] as String,
        _cancel,
      );
      if (!active(generation)) return;
      setState(() => _result = data);
      ref.read(studyRevisionProvider.notifier).state++;
      _top();
    } catch (e) {
      if (active(generation)) {
        setState(() => _error = message(e));
        _top();
      }
    } finally {
      if (active(generation)) setState(() => _busy = false);
    }
  }

  List<Json> get _teachingItems => _teachingRows;

  static List<Json> _buildTeachingItems(Json attempt) {
    final content = attempt['content'] as Json;
    return [
      for (final item in jsonRows(content['cards']))
        {...item, 'section': 'theory'},
      for (final item in jsonRows(content['formulas']))
        {...item, 'section': 'formula'},
      for (final item in jsonRows(content['examples']))
        {...item, 'section': 'example'},
      for (final item in jsonRows(content['reflections'] ?? []))
        {...item, 'section': 'reflection'},
    ];
  }

  String _display(String value) => switch (_subject) {
    'kimyo' => chemistryDisplayText(value),
    'jahon_tarixi' => worldHistoryDisplayText(value),
    _ => value,
  };

  Future<void> _nextTeaching({bool previous = false}) async {
    if (_busy) return;
    final generation = _generation;
    final next = previous ? _teachingIndex - 1 : _teachingIndex + 1;
    _saved['teaching_index'] = next.clamp(0, _teachingItems.length - 1);
    if (next >= _teachingItems.length) _saved['teaching_done'] = true;
    setState(() => _busy = true);
    try {
      await _persist();
      if (active(generation)) {
        setState(() {
          if (next >= _teachingItems.length) {
            _teaching = false;
          } else {
            _teachingIndex = next;
          }
          _error = null;
        });
        _top();
      }
    } catch (error) {
      if (active(generation)) setState(() => _error = message(error));
    } finally {
      if (active(generation)) setState(() => _busy = false);
    }
  }

  void _nextQuestion() {
    setState(() {
      _feedback = null;
      _index++;
      _draft = _index < _questions.length
          ? Map<String, dynamic>.from(
              (_saved['drafts'] as Map)[_question['key']] as Map? ?? {},
            )
          : {};
      _error = null;
    });
    _top();
  }

  Future<void> _leave() async {
    if (!mounted) return;
    setState(() => _allowExit = true);
    await Future<void>.delayed(Duration.zero);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmExit() async {
    if (_exitDialog) return;
    if (_result != null || _attempt == null) {
      await _leave();
      return;
    }
    _exitDialog = true;
    var status = StudyExitStatus.saved;
    try {
      await _persist();
      await _writes;
    } catch (_) {
      status = StudyExitStatus.saveFailed;
    }
    if (!mounted) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => StudyExitDialog(language: _language, status: status),
    );
    _exitDialog = false;
    if (leave == true) await _leave();
  }

  Future<void> _nextLesson() async {
    if (_busy) return;
    final generation = _generation;
    setState(() => _busy = true);
    try {
      final catalog = await _repo.catalog(_cancel, grade: _grade);
      if (!active(generation)) return;
      _catalog = catalog;
      final rows = jsonRows(catalog['lessons']);
      final position = rows.indexWhere((r) => r['key'] == _lessonKey);
      final next = rows
          .skip(position + 1)
          .where((r) => r['state'] == 'available')
          .firstOrNull;
      if (next == null) {
        await _leave();
      } else {
        await _open(next['key'] as String);
      }
    } catch (error) {
      if (active(generation)) {
        setState(() {
          _error = message(error);
          _busy = false;
        });
      }
    }
  }

  Widget _sourceButton(dynamic values) {
    if (reviewedLearning) return const SizedBox.shrink();
    final books = jsonRows(_catalog?['source_books'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final source in jsonRows(values))
          Builder(
            builder: (context) {
              final book = books
                  .where((b) => b['id'] == source['book_id'])
                  .firstOrNull;
              return ContentSourceButton(
                language: _language,
                referenceLabel: _t('Darslik', 'Учебник', 'Textbook'),
                source: {
                  if (book != null) ...{
                    'book_title': book['title'],
                    'authors': book['authors'],
                    'publisher': book['publisher'],
                    'year': book['year'],
                  } else
                    'book_title': source['file_name'] ?? '',
                  ...source,
                },
              );
            },
          ),
      ],
    );
  }

  Widget _panel(String title, String body, {Widget? child}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_display(title), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(_display(body), style: Theme.of(context).textTheme.bodyLarge),
          if (child != null) ...[const SizedBox(height: 12), child],
        ],
      ),
    ),
  );

  Widget _teachingContent() {
    final items = _teachingItems, item = items[_teachingIndex];
    final section = switch (item['section']) {
      'formula' => _t('Formula', 'Формула', 'Formula'),
      'example' => _t(
        'Ishlangan misol',
        'Разобранный пример',
        'Worked example',
      ),
      'reflection' => _t('Mustaqil fikrlash', 'Размышление', 'Reflection'),
      _ => _t('Nazariya', 'Теория', 'Theory'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$section ${_teachingIndex + 1}/${items.length}'),
        const SizedBox(height: 12),
        DuoProgressBar(value: (_teachingIndex + 1) / items.length),
        const SizedBox(height: 16),
        const MascotImage(pose: MascotPose.explaining, size: 72),
        _panel(
          item['title'] as String,
          '${item['expression'] == null ? '' : '${item['expression']}\n\n'}${item['body']}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, step) in jsonRows(item['steps'] ?? []).indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('${i + 1}. ${_display(step['body'] as String)}'),
                ),
              if (item['section'] == 'reflection') ...[
                Text(
                  _t(
                    'O‘zingiz yoki o‘qituvchi bilan ko‘rib chiqing. Avtomatik baholanmaydi.',
                    'Обсудите самостоятельно или с учителем. Автоматической оценки нет.',
                    'Review independently or with a teacher. This is not automatically scored.',
                  ),
                ),
                for (final criterion in item['rubric'] as List? ?? [])
                  Text(_display('$criterion')),
              ],
              _sourceButton(item['source_refs']),
            ],
          ),
        ),
        if (_teachingIndex > 0)
          TextButton(
            onPressed: _busy ? null : () => _nextTeaching(previous: true),
            child: Text(_t('Oldingi', 'Назад', 'Previous')),
          ),
      ],
    );
  }

  Widget _answerEditor(Json question, bool enabled) {
    void changed(Json value) {
      setState(() => _draft = value);
      _remember(value);
    }

    final key = ValueKey(question['key']);
    return switch (_subject) {
      'fizika' => PhysicsAnswerEditor(
        key: key,
        question: question,
        draft: _draft,
        enabled: enabled,
        onChanged: changed,
      ),
      'kimyo' => ChemistryAnswerEditor(
        key: key,
        question: question,
        draft: _draft,
        enabled: enabled,
        onChanged: changed,
      ),
      'jahon_tarixi' => WorldHistoryAnswerEditor(
        key: key,
        question: question,
        draft: _draft,
        enabled: enabled,
        onChanged: changed,
      ),
      'ozbekiston_tarixi' => HistoryAnswerEditor(
        key: key,
        question: question,
        draft: _draft,
        enabled: enabled,
        onChanged: changed,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _exercise() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${_index + 1}/${_questions.length} · ${_question['phase'] == 'guided' ? _t('Yo‘naltirilgan mashq', 'С поддержкой', 'Guided practice') : _t('Mustaqil mashq', 'Самостоятельно', 'Independent practice')}',
      ),
      const SizedBox(height: 12),
      DuoProgressBar(value: _index / _questions.length),
      const SizedBox(height: 24),
      Text(
        _display(_question['prompt'] as String),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 20),
      _answerEditor(_question, !_busy && _pending == null && _feedback == null),
      _sourceButton(_question['source_refs']),
    ],
  );

  Widget _studyHelp() => StudyHelpButton(
    language: _language,
    contextData: StudyHelpContext(
      subject: _subject,
      grade: _grade,
      lessonKey: _lessonKey,
      attemptId: _attempt!['attempt_id'] as String,
      questionKey: _question['key'] as String,
      checked: _feedback != null,
    ),
  );

  Widget _feedbackPanel() {
    final solution = jsonRows(_feedback!['solution']);
    return LessonFeedbackPanel(
      key: _feedbackKey,
      language: _language,
      correct: _feedback!['is_correct'] as bool,
      correctAnswer: _display(
        _feedback!['correct_answer'] as String? ??
            (solution.isEmpty
                ? _feedback!['feedback'] as String
                : solution.last['body'] as String),
      ),
      explanation: _display(
        '${_feedback!['feedback']}\n\n${solution.map((s) => s['body']).join('\n\n')}',
      ),
      source: reviewedLearning ? null : _sourceButton(_feedback!['source_refs']),
      help: reviewedLearning ? _studyHelp() : null,
      onContinue: _nextQuestion,
    );
  }

  Widget _action(String label, VoidCallback? action) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Duo3DButton(
        height: math.max(56, MediaQuery.textScalerOf(context).scale(36) + 16),
        onPressed: action,
        child: Text(label, textAlign: TextAlign.center),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final title =
        _attempt?['title'] as String? ?? widget.lesson.titleFor(_language);
    return PopScope(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, value) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: math.max(
            56,
            MediaQuery.textScalerOf(context).scale(42),
          ),
          leading: IconButton(
            tooltip: _t('Yopish', 'Закрыть', 'Close'),
            icon: const Icon(Icons.close),
            onPressed: _confirmExit,
          ),
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        body: result != null
            ? Column(
                children: [
                  Expanded(
                    child: LessonCompletionView(
                      language: _language,
                      title: result['passed'] == true
                          ? _t(
                              'Dars yakunlandi!',
                              'Урок завершён!',
                              'Lesson complete!',
                            )
                          : _t(
                              'Yana mashq qilamiz',
                              'Попробуем ещё',
                              'Keep practising',
                            ),
                      lessonTitle: title,
                      xp: result['xp_awarded'] as int,
                      correct: result['score'] as int,
                      total: result['total'] as int,
                      stars: result['stars'] as int,
                      streakDays: result['streak_days'] as int,
                      elapsed: Duration(
                        seconds: result['elapsed_seconds'] as int? ?? 0,
                      ),
                      onReview: () => _open(_lessonKey!, fresh: true),
                      reviewLabel: _t(
                        'Qayta mashq qilish',
                        'Пройти ещё раз',
                        'Practise again',
                      ),
                      onBack: _leave,
                    ),
                  ),
                  if (_error != null) Text(_error!),
                  if (result['passed'] == true)
                    _action(
                      _t('Keyingi dars', 'Следующий урок', 'Next lesson'),
                      _busy ? null : _nextLesson,
                    ),
                ],
              )
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: IlmDesign.readingWidth,
                          ),
                          child: ListView(
                            controller: _scroll,
                            padding: const EdgeInsets.all(20),
                            children: [
                              if (_busy) const LinearProgressIndicator(),
                              if (_error != null)
                                Semantics(
                                  liveRegion: true,
                                  child: _panel(
                                    _t(
                                      'Qayta urinib ko‘ramiz',
                                      'Попробуем ещё',
                                      'Try again',
                                    ),
                                    _error!,
                                    child: TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _expired
                                                ? _open(
                                                    _lessonKey!,
                                                    fresh: true,
                                                  )
                                                : _open(
                                                    _lessonKey ??
                                                        widget
                                                            .lesson
                                                            .assessmentKey!,
                                                  ),
                                      child: Text(
                                        _expired
                                            ? _t(
                                                'Yangi urinish',
                                                'Новая попытка',
                                                'New attempt',
                                              )
                                            : _t(
                                                'Qayta urinish',
                                                'Повторить',
                                                'Retry',
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_attempt != null && _teaching)
                                _teachingContent()
                              else if (_attempt != null &&
                                  _index < _questions.length)
                                _exercise()
                              else if (_attempt != null) ...[
                                const MascotImage(
                                  pose: MascotPose.happy,
                                  size: 96,
                                ),
                                Text(
                                  _t(
                                    'Barcha javoblar qabul qilindi. Natijani saqlaymiz.',
                                    'Все ответы приняты. Сохраним результат.',
                                    'All answers received. Save your result.',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_feedback != null)
                      _feedbackPanel()
                    else if (_attempt != null)
                      _action(
                        _teaching
                            ? (_teachingIndex + 1 == _teachingItems.length
                                  ? _t(
                                      'Mashqlarga o‘tish',
                                      'К упражнениям',
                                      'Start practice',
                                    )
                                  : _t('Davom etish', 'Далее', 'Continue'))
                            : _index < _questions.length
                            ? (_pending != null
                                  ? _t(
                                      'Qayta yuborish',
                                      'Отправить снова',
                                      'Retry answer',
                                    )
                                  : _t('Tekshirish', 'Проверить', 'Check'))
                            : _t(
                                'Natijani saqlash',
                                'Сохранить результат',
                                'Save result',
                              ),
                        _busy
                            ? null
                            : _teaching
                            ? _nextTeaching
                            : _index < _questions.length
                            ? (_draft.isEmpty && _pending == null
                                  ? null
                                  : _submit)
                            : _complete,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
