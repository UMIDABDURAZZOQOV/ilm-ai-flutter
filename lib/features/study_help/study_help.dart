import '../../core/config/integrated_beta.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../auth/application/auth_controller.dart';
import '../skills/presentation/content_source_button.dart';
import '../skills/presentation/skill_ui.dart';

/// Only identifiers and the Biology v1 advisory selection cross the wire.
/// Correct answers, grading specs and textbook facts are resolved on the server.
class StudyHelpContext {
  const StudyHelpContext({
    required this.subject,
    this.grade,
    this.lessonKey,
    this.attemptId,
    this.questionKey,
    this.checked = false,
    this.selectedAnswer,
  });
  final String subject;
  final int? grade;
  final String? lessonKey, attemptId, questionKey, selectedAnswer;
  final bool checked;
  Map<String, dynamic> request(String language, String message) => {
    'subject': subject,
    if (grade != null) 'grade': grade,
    if (lessonKey != null) 'lesson_key': lessonKey,
    if (attemptId != null) 'attempt_id': attemptId,
    if (questionKey != null) 'question_key': questionKey,
    'language': language,
    'message': message,
    if (subject == 'biologiya') ...{
      'checked': checked,
      if (selectedAnswer != null) 'selected_answer': selectedAnswer,
    },
  };
}

class StudyHelpRepository {
  const StudyHelpRepository(this.dio);
  final Dio dio;
  Future<Map<String, dynamic>> ask(
    StudyHelpContext context,
    String language,
    String message,
    CancelToken cancel,
  ) async {
    final response = await dio.post(
      reviewedMobileRelease ? '/mobile/study-help' : '/beta/study-help',
      data: context.request(language, message),
      cancelToken: cancel,
      options: Options(receiveTimeout: const Duration(seconds: 25)),
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['mode'] != 'reviewed_evidence' ||
        data['subject'] != context.subject ||
        context.grade != null && data['grade'] != context.grade ||
        context.attemptId != null && data['attempt_id'] != context.attemptId ||
        context.questionKey != null &&
            data['question_key'] != context.questionKey ||
        context.lessonKey != null && data['lesson_key'] != context.lessonKey ||
        data['evidence'] is! List ||
        data['source_refs'] is! List) {
      throw const FormatException('Invalid study help context');
    }
    return data;
  }
}

final studyHelpRepositoryProvider = Provider<StudyHelpRepository>(
  (ref) => StudyHelpRepository(ref.watch(dioProvider)),
);

class StudyHelpButton extends StatefulWidget {
  const StudyHelpButton({
    super.key,
    required this.contextData,
    required this.language,
    this.onOpenChanged,
  });
  final StudyHelpContext contextData;
  final String language;
  final ValueChanged<bool>? onOpenChanged;
  @override
  State<StudyHelpButton> createState() => _StudyHelpButtonState();
}

class _StudyHelpButtonState extends State<StudyHelpButton> {
  bool _opening = false;
  ModalRoute<void>? _sheetRoute;
  NavigatorState? _navigator;

  void _closeSheet() {
    final route = _sheetRoute;
    final navigator = _navigator;
    _sheetRoute = null;
    if (route == null || navigator == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && route.isActive) navigator.removeRoute(route);
    });
  }

  @override
  void didUpdateWidget(covariant StudyHelpButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contextData.attemptId != widget.contextData.attemptId ||
        oldWidget.contextData.questionKey != widget.contextData.questionKey ||
        oldWidget.contextData.subject != widget.contextData.subject ||
        oldWidget.contextData.grade != widget.contextData.grade ||
        oldWidget.contextData.lessonKey != widget.contextData.lessonKey ||
        !widget.contextData.checked) {
      _closeSheet();
    }
  }

  @override
  void dispose() {
    _closeSheet();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contextData = widget.contextData;
    if (!contextData.checked ||
        contextData.attemptId == null ||
        contextData.questionKey == null) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      key: const ValueKey('question_study_help'),
      onPressed: _opening
          ? null
          : () async {
              if (_opening) return;
              setState(() => _opening = true);
              widget.onOpenChanged?.call(true);
              try {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (sheetContext) {
                    _sheetRoute = ModalRoute.of(sheetContext);
                    _navigator = Navigator.of(sheetContext);
                    return StudyHelpSheet(
                      contextData: contextData,
                      language: widget.language,
                    );
                  },
                );
              } finally {
                _sheetRoute = null;
                if (mounted) {
                  setState(() => _opening = false);
                  widget.onOpenChanged?.call(false);
                }
              }
            },
      icon: const Icon(Icons.auto_awesome_outlined, size: 20),
      label: Text(
        str3(
          widget.language,
          'AI tushuntirish',
          'AI объяснение',
          'AI explanation',
        ),
      ),
    );
  }
}

class StudyHelpSheet extends ConsumerStatefulWidget {
  const StudyHelpSheet({
    super.key,
    required this.contextData,
    required this.language,
  });
  final StudyHelpContext contextData;
  final String language;
  @override
  ConsumerState<StudyHelpSheet> createState() => _StudyHelpSheetState();
}

class _StudyHelpSheetState extends ConsumerState<StudyHelpSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _cancel = CancelToken();
  final List<({String question, Map<String, dynamic> answer})> _messages = [];
  late final int? _owner;
  bool _busy = false;
  bool _closing = false;
  String? _error;
  String _pending = '';
  String tr(String uz, String ru, String en) =>
      str3(widget.language, uz, ru, en);
  @override
  void initState() {
    super.initState();
    _owner = ref.read(currentUserIdProvider);
    Future.microtask(() => _ask(''));
  }

  @override
  void dispose() {
    _cancel.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ask(String message) async {
    if (_busy || _owner == null || ref.read(currentUserIdProvider) != _owner) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _pending = message;
    });
    try {
      final answer = await ref
          .read(studyHelpRepositoryProvider)
          .ask(widget.contextData, widget.language, message, _cancel);
      if (!mounted || ref.read(currentUserIdProvider) != _owner) return;
      setState(() {
        _messages.add((question: message, answer: answer));
        _input.clear();
      });
    } catch (_) {
      if (mounted && !_cancel.isCancelled) {
        setState(
          () => _error = tr(
            'Izoh yuklanmadi. Ulanishni tekshirib, qayta urining.',
            'Не удалось загрузить объяснение. Проверьте подключение и повторите.',
            'Could not load the explanation. Check your connection and retry.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserIdProvider);
    ref.listen(currentUserIdProvider, (_, next) {
      if (next != _owner) {
        _cancel.cancel();
        if (!_closing && ModalRoute.of(context) is PopupRoute) {
          _closing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.pop(context);
            }
          });
        }
      }
    });
    if (user != _owner) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom -
                    80)
                .clamp(120, MediaQuery.sizeOf(context).height * .82),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(
                        'Ilmo bilan tushunamiz',
                        'Разберёмся с Ilmo',
                        'Learn with Ilmo',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: tr('Yopish', 'Закрыть', 'Close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  for (final turn in _messages) ...[
                    if (turn.question.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(turn.question),
                        ),
                      ),
                    Text(
                      '${turn.answer['title']} · ${turn.answer['grade']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (turn.answer['question'] != null)
                      SelectableText('${turn.answer['question']}'),
                    Text(
                      turn.answer['provider_status'] == 'selected'
                          ? tr(
                              'AI tanlagan tekshirilgan dars izohlari.',
                              'Проверенные объяснения, выбранные AI.',
                              'Reviewed lesson explanations selected by AI.',
                            )
                          : tr(
                              'AI hozir ulanmagan. Quyida tekshirilgan dars izohlari.',
                              'AI сейчас не подключён. Ниже проверенные объяснения урока.',
                              'AI is not connected. Reviewed lesson explanations are shown below.',
                            ),
                      key: turn == _messages.first
                          ? const ValueKey('study_help_status')
                          : null,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (widget.language != 'uz')
                      Text(
                        tr(
                          'Dars mazmuni o‘zbek tilida.',
                          'Материал урока на узбекском.',
                          'Lesson material is in Uzbek.',
                        ),
                      ),
                    if (turn.answer['answered'] != true &&
                        widget.contextData.questionKey != null)
                      Text(
                        tr(
                          'Avval darsni eslab ko‘ring. Yechim javob tekshirilgach ochiladi.',
                          'Вспомните материал. Решение откроется после проверки ответа.',
                          'Review the lesson first. The solution opens after checking your answer.',
                        ),
                      ),
                    if ((turn.answer['option_reviews'] as List? ?? [])
                        .isNotEmpty)
                      ExpansionTile(
                        title: Text(
                          tr(
                            'Variantlarni solishtirish',
                            'Сравнить варианты',
                            'Compare options',
                          ),
                        ),
                        children: [
                          Text(
                            tr(
                              'Har bir variantni quyidagi manbali yechim bilan solishtiring.',
                              'Сравните каждый вариант с решением из проверенного материала ниже.',
                              'Compare each option with the reviewed solution below.',
                            ),
                          ),
                          for (final option
                              in turn.answer['option_reviews'] as List)
                            ListTile(
                              leading: Icon(
                                option['matches_key'] == true
                                    ? Icons.check_circle_outline
                                    : Icons.remove_circle_outline,
                              ),
                              title: Text('${option['label']}'),
                              subtitle: Text(
                                option['matches_key'] == true
                                    ? tr(
                                        'Darsdagi javobga mos',
                                        'Соответствует ответу урока',
                                        'Matches the lesson answer',
                                      )
                                    : tr(
                                        'Darsdagi javobga mos emas',
                                        'Не соответствует ответу урока',
                                        'Does not match the lesson answer',
                                      ),
                              ),
                            ),
                        ],
                      ),
                    for (final raw in turn.answer['evidence'] as List) ...[
                      const SizedBox(height: 12),
                      SelectableText('${raw['text']}'),
                      if (!reviewedLearning)
                        for (final source in raw['source_refs'] as List? ?? [])
                          ContentSourceButton(
                            source: {
                              'book_title':
                                  source['file_name'] ?? source['book_id'],
                              ...Map<String, dynamic>.from(source as Map),
                            },
                            language: widget.language,
                            referenceLabel: source['paragraph'] == null
                                ? tr('Darslik', 'Учебник', 'Textbook')
                                : null,
                            sectionTitle: '${turn.answer['title']}',
                          ),
                    ],
                    if ((turn.answer['evidence'] as List).isEmpty)
                      Text(
                        tr(
                          'Bu savol uchun mos parcha topilmadi. Shu dars mavzusiga oid savol bering.',
                          'Подходящий фрагмент не найден. Спросите по теме этого урока.',
                          'No matching passage found. Ask about this lesson.',
                        ),
                      ),
                    const Divider(height: 32),
                  ],
                  if (_busy) const Center(child: CircularProgressIndicator()),
                  if (_error != null) ...[
                    Text(_error!, key: const ValueKey('study_help_error')),
                    TextButton(
                      onPressed: () => _ask(_pending),
                      child: Text(tr('Qayta urinish', 'Повторить', 'Retry')),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: tr(
                            'Shu dars haqida savol',
                            'Вопрос об этом уроке',
                            'Question about this lesson',
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) _ask(value.trim());
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: tr('Yuborish', 'Отправить', 'Send'),
                      onPressed: _busy
                          ? null
                          : () {
                              final message = _input.text.trim();
                              if (message.isNotEmpty) _ask(message);
                            },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
