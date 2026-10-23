import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/mascot_image.dart';
import '../../auth/application/auth_controller.dart';
import '../data/chemistry_repository.dart';
import 'chemistry_answer_editor.dart';
import '../../skills/presentation/content_source_button.dart';
import '../../skills/presentation/lesson_feedback_panel.dart';
import '../../skills/presentation/lesson_completion_view.dart';
import '../../skills/presentation/skill_ui.dart';
import '../../skills/presentation/study_exit_dialog.dart';
import '../../../core/theme/ilm_design.dart';

/// Mounted only by the compile/host-gated router; keyed by account to prevent
/// restoring another learner's draft. The server independently enforces access.
class ChemistryPreviewScreen extends ConsumerWidget {
  const ChemistryPreviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    ref.watch(languageProvider);
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Davom etish uchun akkauntingizga kiring.')),
      );
    }
    return _Session(key: ValueKey(uid), userId: uid);
  }
}

class _Session extends ConsumerStatefulWidget {
  final int userId;
  const _Session({super.key, required this.userId});
  @override
  ConsumerState<_Session> createState() => _SessionState();
}

class _SessionState extends ConsumerState<_Session> {
  final _scroll = ScrollController();
  CancelToken _cancel = CancelToken();
  Json? _catalog, _attempt, _feedback, _result;
  Json _saved = {}, _draft = {};
  String? _lessonKey, _error;
  bool _busy = false, _teaching = true, _expired = false, _leaving = false;
  int _index = 0, _generation = 0;
  Future<void> _writes = Future.value();
  ChemistryRepository get _repo => ref.read(chemistryRepositoryProvider);
  bool active(int generation) =>
      mounted &&
      generation == _generation &&
      ref.read(currentUserIdProvider) == widget.userId;
  String get _storageKey {
    final origin = sha256
        .convert(utf8.encode(_repo.dio.options.baseUrl))
        .toString()
        .substring(0, 16);
    return 'chemistry_v2:$origin:${widget.userId}:$_lessonKey';
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCatalog);
  }

  @override
  void dispose() {
    _generation++;
    _cancel.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _top({bool feedback = false}) {
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (active(generation) && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  int _theoryIndex = 0;
  String get _language => ref.read(languageProvider);
  String _t(String uz, String ru, String en) => str3(_language, uz, ru, en);

  String message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final detail = data is Map ? data['detail'] : null;
      if (detail is Map && detail['feedback'] is String) {
        return detail['feedback'] as String;
      }
      if (detail == 'chemistry_preview_disabled') {
        return 'Kimyo sinovi bu serverda yoqilmagan.';
      }
      if (detail == 'chemistry_preview_schema_not_installed') {
        return 'Lokal Kimyo bazasi hali tayyorlanmagan.';
      }
      if (detail == 'attempt_expired') {
        return 'Urinishning 24 soatlik muddati tugadi. Yangi urinish oching; eski natijalar saqlanadi.';
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

  Future<void> _loadCatalog() async {
    if (!mounted) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _repo.catalog(_cancel);
      if (active(generation)) setState(() => _catalog = data);
    } catch (e) {
      if (active(generation)) setState(() => _error = message(e));
    } finally {
      if (active(generation)) setState(() => _busy = false);
    }
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
              'request_id': ChemistryRepository.requestId(),
              'drafts': <String, dynamic>{},
              'teaching_done': false,
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
        final savedIndex = _saved['theory_index'];
        final count = jsonRows((data['content'] as Json)['cards']).length;
        _theoryIndex = (savedIndex is int ? savedIndex : 0).clamp(0, count - 1);
        _attempt = data;
        _feedback = null;
        _result = data['result'] as Json?;
        _index = index < 0 ? questions.length : index;
        _teaching = _saved['teaching_done'] != true && answered.isEmpty;
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

  List<Json> get _questions => jsonRows(_attempt!['questions']);
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
      setState(() {
        _feedback = result;
        (_attempt!['answers'] as Json)[result['assessment_key'] as String] =
            result;
      });
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

  void _backToPath() {
    _generation++;
    _cancel.cancel();
    _cancel = CancelToken();
    setState(() {
      _attempt = null;
      _result = null;
      _feedback = null;
      _error = null;
      _lessonKey = null;
      _busy = false;
    });
    _top();
    unawaited(_loadCatalog());
  }

  Future<void> _confirmBack() async {
    if (_busy || _leaving) return;
    if (_result != null) {
      _backToPath();
      return;
    }
    final generation = _generation;
    setState(() => _leaving = true);
    var saved = false;
    try {
      await _persist();
      saved = true;
    } catch (_) {
      /* Dialog reports failure. */
    }
    if (!mounted || !active(generation)) return;
    final leave = await showDialog<bool>(
      context: context,
      animationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (_) => StudyExitDialog(
        language: _language,
        status: saved ? StudyExitStatus.saved : StudyExitStatus.saveFailed,
      ),
    );
    if (!active(generation)) return;
    setState(() => _leaving = false);
    if (leave == true) _backToPath();
  }

  Widget _button(String label, VoidCallback? action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Duo3DButton(
      height: math.max(56, MediaQuery.textScalerOf(context).scale(56)),
      onPressed: action,
      child: Text(label, textAlign: TextAlign.center),
    ),
  );

  Widget _panel(String title, String body, {Widget? child}) => Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (body.isNotEmpty) ...[const SizedBox(height: 12), Text(body)],
          if (child != null) ...[const SizedBox(height: 8), child],
        ],
      ),
    ),
  );

  Widget _sourceButton(dynamic values) {
    final refs = jsonRows(values);
    return Align(
      alignment: Alignment.centerLeft,
      child: ContentSourceButton(
        language: _language,
        source: {
          ...refs.first,
          'pdf_pages': [for (final r in refs) ...r['pdf_pages'] as List],
          'printed_pages': [
            for (final r in refs) ...r['printed_pages'] as List,
          ],
          'regions': [for (final r in refs) ...r['regions'] as List],
        },
      ),
    );
  }

  Widget _path() {
    final rows = _catalog == null ? <Json>[] : jsonRows(_catalog!['lessons']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MascotImage(pose: MascotPose.hello, size: 92),
        Text(
          _t('Kimyo · 7-sinf', 'Химия · 7 класс', 'Chemistry · Grade 7'),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _t(
            'Bilimlarni darslikdan boshlab o‘rganamiz.',
            'Начнём с знаний из учебника.',
            'Start with knowledge from the textbook.',
          ),
          textAlign: TextAlign.center,
        ),
        if (_catalog != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _t(
                '${rows.length}/${_catalog!['source_sections']} dars tayyor. Qolgan mavzular tayyorlanmoqda.',
                'Готово уроков: ${rows.length}/${_catalog!['source_sections']}. Остальные темы готовятся.',
                '${rows.length}/${_catalog!['source_sections']} lessons ready. Other topics are being prepared.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        for (final row in rows)
          _panel(
            row['title'] as String,
            '',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sourceButton(row['source_refs']),
                if (row['state'] == 'completed')
                  Text(_t('Tugallangan', 'Завершён', 'Completed')),
                _button(
                  row['state'] == 'completed'
                      ? _t(
                          'Darsni takrorlash',
                          'Повторить урок',
                          'Review lesson',
                        )
                      : _t('Darsni boshlash', 'Начать урок', 'Start lesson'),
                  _busy || row['state'] == 'locked'
                      ? null
                      : () => _open(row['key'] as String),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _nextTheory() async {
    if (_busy) return;
    final generation = _generation;
    final cards = jsonRows((_attempt!['content'] as Json)['cards']);
    final last = _theoryIndex == cards.length - 1;
    _saved['theory_index'] = last ? _theoryIndex : _theoryIndex + 1;
    if (last) _saved['teaching_done'] = true;
    setState(() => _busy = true);
    try {
      await _persist();
      if (!active(generation)) return;
      setState(() {
        if (last) {
          _teaching = false;
        } else {
          _theoryIndex++;
        }
        _error = null;
      });
      _top();
    } catch (_) {
      if (active(generation)) {
        setState(
          () => _error = _t(
            'Qoralamani saqlab bo‘lmadi. Qayta urining.',
            'Не удалось сохранить. Повторите попытку.',
            'Could not save your place. Try again.',
          ),
        );
      }
    } finally {
      if (active(generation)) setState(() => _busy = false);
    }
  }

  Widget _teachingContent() {
    final cards = jsonRows((_attempt!['content'] as Json)['cards']);
    final card = cards[_theoryIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_t('Nazariya', 'Теория', 'Theory')} ${_theoryIndex + 1}/${cards.length}',
        ),
        const SizedBox(height: 12),
        DuoProgressBar(value: (_theoryIndex + 1) / cards.length),
        const SizedBox(height: 18),
        const MascotImage(pose: MascotPose.explaining, size: 72),
        _panel(
          card['title'] as String,
          card['body'] as String,
          child: _sourceButton(card['source_refs']),
        ),
        _button(
          _theoryIndex == cards.length - 1
              ? _t('Mashqlarga o‘tish', 'К упражнениям', 'Start questions')
              : _t('Davom etish', 'Далее', 'Continue'),
          _busy ? null : _nextTheory,
        ),
      ],
    );
  }

  void _nextQuestion() {
    if (_busy) return;
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

  bool get _hasInput =>
      _pending != null ||
      (_question['response_kind'] == 'short_text'
          ? ((_draft['value'] as String?)?.trim().isNotEmpty ?? false)
          : _draft['choice_id'] != null);

  Widget _exercise() {
    final q = _question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_index + 1}/${_questions.length} · ${q['response_kind'] == 'short_text' ? 'FRQ' : 'MCQ'}',
        ),
        const SizedBox(height: 12),
        DuoProgressBar(value: _index / _questions.length),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            q['prompt'] as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _sourceButton(q['source_refs']),
        const SizedBox(height: 16),
        ChemistryAnswerEditor(
          key: ValueKey(q['key']),
          question: q,
          draft: _draft,
          language: _language,
          feedback: _feedback,
          enabled: !_busy && _pending == null && _feedback == null,
          onChanged: (draft) {
            setState(() => _draft = draft);
            _remember(draft);
          },
        ),
        if (_feedback == null)
          _button(
            _pending != null
                ? _t('Qayta yuborish', 'Отправить повторно', 'Retry submission')
                : _t('Tekshirish', 'Проверить', 'Check'),
            _busy || !_hasInput ? null : _submit,
          ),
      ],
    );
  }

  void _reviewAnswers() {
    final answers = Map<String, dynamic>.from(_attempt!['answers'] as Map);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .85,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _t('Javoblar', 'Ответы', 'Answers'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            for (final q in _questions)
              if (answers[q['key']] is Map)
                _panel(
                  q['prompt'] as String,
                  (answers[q['key']] as Map)['correct_answer'] as String,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final step in jsonRows(
                        (answers[q['key']] as Map)['solution'],
                      ))
                        Text(step['body'] as String),
                      _sourceButton(q['source_refs']),
                    ],
                  ),
                ),
            _button(_t('Yangi urinish', 'Новая попытка', 'New attempt'), () {
              Navigator.pop(context);
              unawaited(_open(_lessonKey!, fresh: true));
            }),
          ],
        ),
      ),
    );
  }

  Widget _resultContent() => LessonCompletionView(
    language: _language,
    title: _result!['passed'] == true
        ? _t('Dars yakunlandi!', 'Урок завершён!', 'Lesson complete!')
        : _t('Yana mashq qilamiz', 'Попробуем ещё', 'Let’s practise again'),
    lessonTitle: _attempt!['title'] as String,
    xp: _result!['xp_awarded'] as int,
    correct: _result!['score'] as int,
    total: _result!['total'] as int,
    stars: _result!['stars'] as int,
    streakDays: _result!['streak_days'] as int,
    elapsed: Duration(seconds: _result!['elapsed_seconds'] as int),
    onReview: _reviewAnswers,
    onBack: _backToPath,
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _attempt == null && !_busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _attempt != null) _confirmBack();
    },
    child: AbsorbPointer(
      absorbing: _leaving,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: math.max(
            56,
            MediaQuery.textScalerOf(context).scale(42),
          ),
          title: Text(
            _t('Kimyo · 7-sinf', 'Химия · 7 класс', 'Chemistry · Grade 7'),
            maxLines: 2,
          ),
          leading: _attempt == null
              ? null
              : IconButton(
                  tooltip: _t(
                    'Dars yo‘liga qaytish',
                    'К учебному пути',
                    'Back to learning path',
                  ),
                  onPressed: _busy ? null : _confirmBack,
                  icon: const Icon(Icons.arrow_back),
                ),
        ),
        body: _result != null
            ? _resultContent()
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
                              if (_busy)
                                Semantics(
                                  label: _t(
                                    'Yuklanmoqda',
                                    'Загрузка',
                                    'Loading',
                                  ),
                                  child: MediaQuery.disableAnimationsOf(context)
                                      ? Text(
                                          _t(
                                            'Yuklanmoqda…',
                                            'Загрузка…',
                                            'Loading…',
                                          ),
                                        )
                                      : const LinearProgressIndicator(),
                                ),
                              if (_language != 'uz')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    _t(
                                      'Dars tili: o‘zbekcha',
                                      'Язык урока: узбекский',
                                      'Lesson language: Uzbek',
                                    ),
                                  ),
                                ),
                              if (_error != null)
                                Semantics(
                                  liveRegion: true,
                                  child: _panel(
                                    _t(
                                      'Qayta urinib ko‘ramiz',
                                      'Попробуем снова',
                                      'Try again',
                                    ),
                                    _error!,
                                    child: Column(
                                      children: [
                                        if (_expired && _lessonKey != null)
                                          _button(
                                            _t(
                                              'Yangi urinish',
                                              'Новая попытка',
                                              'New attempt',
                                            ),
                                            _busy
                                                ? null
                                                : () => _open(
                                                    _lessonKey!,
                                                    fresh: true,
                                                  ),
                                          ),
                                        if (_attempt == null && !_expired)
                                          _button(
                                            _t(
                                              'Qayta urinish',
                                              'Повторить',
                                              'Retry',
                                            ),
                                            _busy
                                                ? null
                                                : () => _lessonKey != null
                                                      ? _open(_lessonKey!)
                                                      : _loadCatalog(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_attempt == null)
                                _path()
                              else if (_teaching)
                                _teachingContent()
                              else if (_index < _questions.length)
                                _exercise()
                              else ...[
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
                                _button(
                                  _t(
                                    'Natijani saqlash',
                                    'Сохранить результат',
                                    'Save result',
                                  ),
                                  _busy ? null : _complete,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_feedback != null)
                      LessonFeedbackPanel(
                        language: _language,
                        correct: _feedback!['is_correct'] as bool,
                        correctAnswer: _feedback!['correct_answer'] as String,
                        explanation: jsonRows(
                          _feedback!['solution'],
                        ).map((s) => s['body']).join('\n\n'),
                        onContinue: _nextQuestion,
                      ),
                  ],
                ),
              ),
      ),
    ),
  );
}
