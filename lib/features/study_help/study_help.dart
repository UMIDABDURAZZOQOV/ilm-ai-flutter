import '../../core/config/integrated_beta.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../auth/application/auth_controller.dart';
import '../skills/presentation/content_source_button.dart';
import '../skills/presentation/skill_ui.dart';
import '../../core/utils/reviewed_text.dart';

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
      options: Options(
        receiveTimeout: const Duration(seconds: 25),
        // An old backend ignores this header and keeps its compatible reviewed
        // fallback. No new JSON field breaks its extra-forbid request schema.
        headers: const {'X-ILM-Study-Help': 'reviewed-text-v2'},
      ),
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (!{
          'reviewed_evidence',
          'generated_explanation',
        }.contains(data['mode']) ||
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
    if (data['mode'] == 'generated_explanation') {
      if (!context.checked ||
          context.questionKey == null ||
          !_validGeneration(data)) {
        throw const FormatException('Invalid generated explanation');
      }
    } else if (data['provider_status'] == 'generated' ||
        data['generation'] != null) {
      throw const FormatException('Invalid explanation provenance');
    }
    return data;
  }
}

bool _validGeneration(Map<String, dynamic> data) {
  final generation = data['generation'];
  if (data['provider_status'] != 'generated' ||
      data['answered'] != true ||
      data['is_correct'] is! bool ||
      generation is! Map ||
      !((generation['provider'] == 'nvidia' &&
              generation['model'] == 'meta/muse-glimmer-30b') ||
          (generation['provider'] == 'gemini' &&
              generation['model'] == 'gemini-3.1-flash-lite')) ||
      !{
        'internal_evaluation',
        'authorized_hosted_application',
      }.contains(generation['usage']) ||
      generation['language'] != 'uz' ||
      generation['http_status'] != 200 ||
      generation['is_correct'] != data['is_correct'] ||
      generation['grounding'] !=
          'citations_and_quotes_checked_not_semantic_verification') {
    return false;
  }
  for (final key in ['request_sha256', 'response_sha256']) {
    if (generation[key] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(generation[key] as String)) {
      return false;
    }
  }
  if (generation['request_id'] is! String ||
      !RegExp(r'^[a-f0-9]{32}$').hasMatch(generation['request_id'] as String)) {
    return false;
  }
  final paragraphs = generation['paragraphs'];
  final evidence = data['evidence'];
  if (paragraphs is! List ||
      paragraphs.isEmpty ||
      paragraphs.length > 4 ||
      evidence is! List) {
    return false;
  }
  final ids = {
    for (final item in evidence)
      if (item is Map &&
          item['id'] is String &&
          item['source_refs'] is List &&
          (item['source_refs'] as List).isNotEmpty)
        item['id'],
  };
  for (final paragraph in paragraphs) {
    if (paragraph is! Map ||
        paragraph['text'] is! String ||
        (paragraph['text'] as String).trim().length < 20 ||
        (paragraph['text'] as String).length > 1500 ||
        paragraph['evidence_ids'] is! List) {
      return false;
    }
    final refs = paragraph['evidence_ids'] as List;
    if (refs.isEmpty ||
        refs.length > 3 ||
        refs.toSet().length != refs.length ||
        refs.any((id) => id is! String || !ids.contains(id))) {
      return false;
    }
  }
  return true;
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
    return LayoutBuilder(builder: _buildSheet);
  }

  Widget _buildSheet(BuildContext context, BoxConstraints constraints) {
    final requestedHeight =
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                80)
            .clamp(120, MediaQuery.sizeOf(context).height * .82);
    // A Scaffold/modal can already have resized its body for the keyboard and
    // removed viewInsets. Use its actual constraints, not screen size alone.
    final availableHeight = constraints.hasBoundedHeight
        ? (constraints.maxHeight - MediaQuery.viewInsetsOf(context).bottom)
              .clamp(0, double.infinity)
        : requestedHeight;
    final sheetHeight = requestedHeight.clamp(0, availableHeight);
    final compact =
        sheetHeight < 240 * MediaQuery.textScalerOf(context).scale(20) / 20;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: sheetHeight.toDouble(),
        child: _AdaptiveHelpLayout(
          compact: compact,
          scrollController: _scroll,
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
            Flexible(
              flex: compact ? 0 : 1,
              fit: FlexFit.tight,
              child: ListView(
                controller: compact ? null : _scroll,
                primary: false,
                shrinkWrap: compact,
                physics: compact ? const NeverScrollableScrollPhysics() : null,
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
                      turn.answer['mode'] == 'generated_explanation'
                          ? tr(
                              '${turn.answer['generation']['provider'] == 'gemini' ? 'Gemini' : 'NVIDIA AI'} yaratgan izoh.',
                              'Объяснение, созданное ${turn.answer['generation']['provider'] == 'gemini' ? 'Gemini' : 'NVIDIA AI'}.',
                              'Explanation generated by ${turn.answer['generation']['provider'] == 'gemini' ? 'Gemini' : 'NVIDIA AI'}.',
                            )
                          : turn.answer['provider_status'] == 'selected'
                          ? tr(
                              'AI tanlagan tekshirilgan dars izohlari.',
                              'Проверенные объяснения, выбранные AI.',
                              'Reviewed lesson explanations selected by AI.',
                            )
                          : turn.answer['provider_status'] == 'unavailable'
                          ? tr(
                              'AI izohini hozir tayyorlab bo‘lmadi. Quyida tekshirilgan dars izohlari.',
                              'Сейчас не удалось подготовить объяснение AI. Ниже проверенные объяснения урока.',
                              'An AI explanation could not be prepared right now. Reviewed lesson explanations are shown below.',
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
                    if (turn.answer['mode'] == 'generated_explanation' &&
                        _validGeneration(turn.answer)) ...[
                      const SizedBox(height: 12),
                      Card(
                        key: const ValueKey('nvidia_generated_explanation'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final paragraph
                                  in turn.answer['generation']['paragraphs']
                                      as List)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SelectableText('${paragraph['text']}'),
                                ),
                              Text(
                                tr(
                                  'AI izohini quyidagi tekshirilgan yechim bilan solishtiring.',
                                  'Сравните AI-объяснение с проверенным решением ниже.',
                                  'Compare the AI explanation with the reviewed solution below.',
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                    for (final raw
                        in reviewedLearning
                            ? distinctReviewedText(
                                turn.answer['evidence'] as List,
                                (raw) => '${raw['text']}',
                              )
                            : turn.answer['evidence'] as List) ...[
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

/// Keep the pinned layout when it fits. With a keyboard/large text, the header,
/// transcript and composer scroll together so neither controls nor text clip.
class _AdaptiveHelpLayout extends StatelessWidget {
  const _AdaptiveHelpLayout({
    required this.compact,
    required this.scrollController,
    required this.children,
  });
  final bool compact;
  final ScrollController scrollController;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    return compact
        ? SingleChildScrollView(controller: scrollController, child: column)
        : column;
  }
}
