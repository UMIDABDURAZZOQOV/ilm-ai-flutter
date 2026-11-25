import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/integrated_beta.dart';
import '../../core/network/dio_client.dart';
import '../../core/widgets/animated_ilmo.dart';
import '../../core/widgets/mascot_image.dart';
import '../auth/application/auth_controller.dart';
import '../physics/data/physics_repository.dart';
import 'ai_answer_report.dart';

const subjectTutorNames = {
  'biologiya': 'Biologiya',
  'fizika': 'Fizika',
  'kimyo': 'Kimyo',
  'ozbekiston_tarixi': 'O‘zbekiston tarixi',
  'jahon_tarixi': 'Jahon tarixi',
};

class SubjectTutorRepository {
  const SubjectTutorRepository(this.dio);
  final Dio dio;
  Future<Map<String, dynamic>> ask({
    required String subject,
    required int grade,
    required String conversation,
    required String request,
    required String message,
    required CancelToken cancel,
    String? lessonKey,
    Map<String, dynamic> questionContext = const {},
  }) async {
    final result = await dio.post(
      reviewedMobileRelease ? '/mobile/subject-chat' : '/beta/subject-chat',
      data: {
        ...questionContext,
        'subject': subject,
        'grade': grade,
        'conversation_id': conversation,
        'request_id': request,
        'message': message,
        'lesson_key': ?lessonKey,
      },
      cancelToken: cancel,
      options: Options(
        receiveTimeout: const Duration(seconds: 25),
        headers: {'X-ILM-AI-Report': 'v1'},
      ),
    );
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['mode'] != 'subject_chat' ||
        data['subject'] != subject ||
        data['grade'] != grade ||
        data['conversation_id'] != conversation ||
        data['request_id'] != request ||
        !{
          'answered',
          'off_topic',
          'clarify',
          'insufficient_evidence',
          'unavailable',
          'audience_unavailable',
        }.contains(data['status']) ||
        data['paragraphs'] is! List) {
      throw const FormatException('Invalid tutor context');
    }
    final paragraphs = data['paragraphs'] as List;
    if (data['status'] == 'answered') {
      final generation = data['generation'];
      final evidence = data['evidence'];
      if (generation is! Map ||
          generation['provider'] != 'gemini' ||
          generation['model'] != 'gemini-3.1-flash-lite' ||
          generation['http_status'] != 200 ||
          generation['status'] != 'answered' ||
          generation['language'] != 'uz' ||
          generation['grounding'] !=
              'citations_and_quotes_checked_not_semantic_verification' ||
          paragraphs.isEmpty ||
          paragraphs.length > 4 ||
          evidence is! List) {
        throw const FormatException('Invalid tutor provenance');
      }
      final ids = {
        for (final e in evidence)
          if (e is Map) e['id'],
      };
      for (final p in paragraphs) {
        if (p is! Map ||
            p['text'] is! String ||
            (p['text'] as String).length > 1500 ||
            p['evidence_ids'] is! List ||
            (p['evidence_ids'] as List).isEmpty ||
            !(p['evidence_ids'] as List).every(ids.contains)) {
          throw const FormatException('Invalid tutor evidence');
        }
      }
    } else if (paragraphs.isNotEmpty || data['message'] is! String) {
      throw const FormatException('Invalid tutor status');
    }
    return data;
  }
}

final subjectTutorRepositoryProvider = Provider(
  (ref) => SubjectTutorRepository(ref.watch(dioProvider)),
);

Future<void> openSubjectTutor(
  BuildContext context, {
  required String subject,
  required int grade,
  String language = 'uz',
  String? lessonKey,
  String? initialMessage,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      // Keep the study path and chat from rasterizing together during a slide.
      // Ilmo supplies the entrance motion inside the fully visible chat.
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => SubjectTutorScreen(
        subject: subject,
        grade: grade,
        language: language,
        lessonKey: lessonKey,
        initialMessage: initialMessage,
      ),
    ),
  );
}

class SubjectTutorScreen extends ConsumerStatefulWidget {
  const SubjectTutorScreen({
    super.key,
    required this.subject,
    required this.grade,
    this.language = 'uz',
    this.lessonKey,
    this.initialMessage,
    this.questionContext = const {},
  });
  final String subject;
  final String language;
  final int grade;
  final String? lessonKey, initialMessage;
  final Map<String, dynamic> questionContext;
  @override
  ConsumerState<SubjectTutorScreen> createState() => _SubjectTutorScreenState();
}

class _SubjectTutorScreenState extends ConsumerState<SubjectTutorScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _cancel = CancelToken();
  late final _conversation = PhysicsRepository.requestId();
  final List<({bool user, String text, ReportableAiAnswer? report})> _turns =
      [];
  late final int? _owner;
  String? _pending, _request, _error;
  bool _busy = false;
  String tr(String uz, String ru, String en) => widget.language == 'ru'
      ? ru
      : widget.language == 'en'
      ? en
      : uz;

  String statusText(String status) => switch (status) {
    'off_topic' => tr(
      'Bu suhbatda tanlangan fanni o‘rganamiz. Shu fan bo‘yicha savol bering.',
      'В этом чате изучаем выбранный предмет. Задайте вопрос по нему.',
      'This chat is for the selected subject. Ask a question about it.',
    ),
    'clarify' => tr(
      'Qaysi tushuncha yoki mavzuni tushuntiray?',
      'Какое понятие или тему объяснить?',
      'Which concept or topic should I explain?',
    ),
    'insufficient_evidence' => tr(
      'Bu savol uchun tekshirilgan material yetarli emas. Mavzu yoki tushuncha nomini aniqroq yozing.',
      'Для этого вопроса недостаточно проверенного материала. Уточните тему или понятие.',
      'There is not enough reviewed material for this question. Specify the topic or concept.',
    ),
    'audience_unavailable' => tr(
      'Bu akkaunt uchun AI suhbati mavjud emas. Darsdagi tekshirilgan izohdan foydalaning.',
      'AI-чат недоступен для этого аккаунта. Используйте проверенное объяснение в уроке.',
      'AI chat is unavailable for this account. Use the reviewed explanation in the lesson.',
    ),
    _ => tr(
      'Javob kelmadi. Savolingiz saqlandi — qayta urinishingiz mumkin.',
      'Ответ не получен. Ваш вопрос сохранён — можно повторить попытку.',
      'No answer arrived. Your question is saved — you can retry.',
    ),
  };
  @override
  void initState() {
    super.initState();
    _owner = ref.read(currentUserIdProvider);
    if (widget.initialMessage case final String message) {
      _input.text = message;
      Future.microtask(_send);
    }
  }

  @override
  void dispose() {
    _cancel.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });
  Future<void> _send({bool retry = false}) async {
    if (_busy || _owner == null || ref.read(currentUserIdProvider) != _owner) {
      return;
    }
    final message = retry ? _pending ?? '' : _input.text.trim();
    if (message.isEmpty || message.length > 1500) return;
    setState(() {
      _busy = true;
      _error = null;
      if (!retry) {
        _pending = message;
        _request = PhysicsRepository.requestId();
        _turns.add((user: true, text: message, report: null));
        _input.clear();
      }
    });
    _bottom();
    try {
      final reply = await ref
          .read(subjectTutorRepositoryProvider)
          .ask(
            subject: widget.subject,
            grade: widget.grade,
            conversation: _conversation,
            request: _request!,
            message: message,
            cancel: _cancel,
            lessonKey: widget.lessonKey,
            questionContext: widget.questionContext,
          );
      if (!mounted || ref.read(currentUserIdProvider) != _owner) return;
      setState(() {
        if (reply['status'] == 'unavailable') {
          _error = statusText('unavailable');
        } else {
          _turns.add((
            user: false,
            report: reply['status'] == 'answered'
                ? ReportableAiAnswer.fromReply(reply)
                : null,
            text: reply['status'] == 'answered'
                ? (reply['paragraphs'] as List)
                      .map((p) => p['text'])
                      .join('\n\n')
                : statusText(reply['status'] as String),
          ));
          _pending = null;
          _request = null;
        }
      });
    } catch (_) {
      if (mounted &&
          !_cancel.isCancelled &&
          ref.read(currentUserIdProvider) == _owner) {
        setState(() => _error = statusText('unavailable'));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _bottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserIdProvider, (_, next) {
      if (next != _owner) {
        _cancel.cancel();
        if (ModalRoute.of(context) is PopupRoute) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.of(context).pop();
            }
          });
        }
        setState(() {
          _turns.clear();
          _pending = null;
          _error = null;
        });
      }
    });
    if (ref.watch(currentUserIdProvider) != _owner || _owner == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            tr(
              'Suhbat uchun akkauntingizga kiring.',
              'Войдите в аккаунт, чтобы начать чат.',
              'Sign in to start a conversation.',
            ),
          ),
        ),
      );
    }
    final colors = Theme.of(context).colorScheme;
    final subject = switch (widget.subject) {
      'biologiya' => tr('Biologiya', 'Биология', 'Biology'),
      'fizika' => tr('Fizika', 'Физика', 'Physics'),
      'kimyo' => tr('Kimyo', 'Химия', 'Chemistry'),
      'ozbekiston_tarixi' => tr(
        'O‘zbekiston tarixi',
        'История Узбекистана',
        'Uzbekistan history',
      ),
      'jahon_tarixi' => tr(
        'Jahon tarixi',
        'Всемирная история',
        'World history',
      ),
      _ => widget.subject,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ilmo · $subject',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  if (_turns.isEmpty) ...[
                    Center(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _input,
                        builder: (context, value, child) => AnimatedIlmo(
                          pose: MascotPose.hello,
                          activity: value.text.trim().isEmpty
                              ? IlmoActivity.greeting
                              : IlmoActivity.listening,
                          size: 157,
                        ),
                      ),
                    ),
                    Text(
                      tr(
                        '$subject haqida birga o‘ylaymiz',
                        'Разберёмся вместе: $subject',
                        'Let’s explore $subject',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(
                        'Savolingizni yozing. Tushunmagan joyingizni sodda qilib, bosqichma-bosqich tushuntiraman.',
                        'Напишите вопрос. Объясню непонятное простыми словами, шаг за шагом.',
                        'Ask your question. I’ll explain what is unclear in simple steps.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Starter prompts: one tap sends a ready subject question.
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (index, prompt) in [
                          tr(
                            'Bu fanning asosiy tushunchalarini tushuntir',
                            'Объясни основные понятия предмета',
                            'Explain the key ideas of this subject',
                          ),
                          tr(
                            'Hayotiy misol bilan tushuntir',
                            'Объясни на жизненном примере',
                            'Explain with a real-life example',
                          ),
                          tr(
                            'Oxirgi mavzuni soddaroq tushuntir',
                            'Объясни последнюю тему проще',
                            'Explain the latest topic more simply',
                          ),
                        ].indexed)
                          ActionChip(
                            key: ValueKey('tutor_starter_$index'),
                            avatar: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                            ),
                            label: Text(prompt),
                            onPressed: _busy
                                ? null
                                : () {
                                    _input.text = prompt;
                                    _send();
                                  },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  for (final (index, turn) in _turns.indexed)
                    Align(
                      alignment: turn.user
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: turn.user
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!turn.user) ...[
                              Row(
                                children: [
                                  if (index == _turns.length - 1 && !_busy) ...[
                                    AnimatedIlmo(
                                      pose: MascotPose.explaining,
                                      reactionKey: index,
                                      size: 56,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      'Ilmo · AI',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            SelectableText(
                              turn.text,
                              style: TextStyle(
                                color: turn.user
                                    ? colors.onPrimaryContainer
                                    : colors.onSurface,
                              ),
                            ),
                            if (turn.report case final report?)
                              AiAnswerReportButton(
                                answer: report,
                                language: widget.language,
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_busy)
                    Row(
                      children: [
                        const AnimatedIlmo(
                          pose: MascotPose.thinking,
                          size: 67,
                          thinking: true,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr(
                              'Ilmo savolingiz ustida o‘ylayapti…',
                              'Ilmo обдумывает ваш вопрос…',
                              'Ilmo is thinking about your question…',
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_error != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AnimatedIlmo(pose: MascotPose.sad, size: 56),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                key: const ValueKey('tutor_error'),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _busy ? null : () => _send(retry: true),
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            tr('Qayta urinish', 'Повторить', 'Retry'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('tutor_input'),
                      controller: _input,
                      enabled: !_busy,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 1500,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: tr(
                          '$subject bo‘yicha savolingiz',
                          'Ваш вопрос: $subject',
                          'Your $subject question',
                        ),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _input,
                    builder: (context, value, child) {
                      final message = value.text.trim();
                      return IconButton.filled(
                        tooltip: tr('Yuborish', 'Отправить', 'Send'),
                        style: IconButton.styleFrom(
                          animationDuration: Duration.zero,
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          disabledBackgroundColor:
                              colors.surfaceContainerHighest,
                          disabledForegroundColor: colors.onSurfaceVariant,
                        ),
                        onPressed:
                            _busy || message.isEmpty || message.length > 1500
                            ? null
                            : () => _send(),
                        icon: child!,
                      );
                    },
                    child: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
