import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/integrated_beta.dart';
import '../../core/network/dio_client.dart';
import '../auth/application/auth_controller.dart';

class ReportableAiAnswer {
  const ReportableAiAnswer(this.receipt, this.paragraphs);

  final String receipt;
  final List<String> paragraphs;

  static ReportableAiAnswer? fromReply(Map<String, dynamic> reply) {
    final receipt = reply['report_receipt'];
    final generation = reply['generation'];
    if (receipt is! String || receipt.isEmpty || generation is! Map) {
      return null;
    }
    final paragraphs = generation['paragraphs'];
    if (paragraphs is! List || paragraphs.isEmpty) return null;
    final text = [
      for (final item in paragraphs)
        if (item is Map) item['text'],
    ];
    if (text.length != paragraphs.length ||
        text.any((part) => part is! String)) {
      return null;
    }
    return ReportableAiAnswer(receipt, text.cast<String>());
  }
}

class AiAnswerReportButton extends ConsumerStatefulWidget {
  const AiAnswerReportButton({
    super.key,
    required this.answer,
    required this.language,
  });

  final ReportableAiAnswer answer;
  final String language;

  @override
  ConsumerState<AiAnswerReportButton> createState() =>
      _AiAnswerReportButtonState();
}

class _AiAnswerReportButtonState extends ConsumerState<AiAnswerReportButton> {
  final _cancel = CancelToken();
  late final int? _owner;
  bool _busy = false;
  bool _sent = false;
  bool _failed = false;

  String tr(String uz, String ru, String en) => switch (widget.language) {
    'ru' => ru,
    'en' => en,
    _ => uz,
  };

  @override
  void initState() {
    super.initState();
    _owner = ref.read(currentUserIdProvider);
  }

  @override
  void dispose() {
    _cancel.cancel();
    super.dispose();
  }

  Future<void> _report() async {
    if (_busy ||
        _sent ||
        _owner == null ||
        ref.read(currentUserIdProvider) != _owner) {
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final response = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            reviewedMobileRelease
                ? '/mobile/ai-answer-report'
                : '/beta/ai-answer-report',
            data: {
              'receipt': widget.answer.receipt,
              'paragraphs': widget.answer.paragraphs,
            },
            cancelToken: _cancel,
          );
      if (mounted && ref.read(currentUserIdProvider) == _owner) {
        setState(() {
          _sent = response.data?['reported'] == true;
          _failed = !_sent;
        });
      }
    } catch (_) {
      if (mounted &&
          !_cancel.isCancelled &&
          ref.read(currentUserIdProvider) == _owner) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_owner == null || ref.watch(currentUserIdProvider) != _owner) {
      return const SizedBox.shrink();
    }
    if (_sent) {
      return Semantics(
        liveRegion: true,
        child: Text(
          tr('Shikoyat yuborildi', 'Жалоба отправлена', 'Report sent'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _busy ? null : _report,
          icon: const Icon(Icons.flag_outlined),
          label: Text(
            _busy
                ? tr('Yuborilmoqda…', 'Отправляем…', 'Sending…')
                : tr(
                    'AI javobidan shikoyat qilish',
                    'Пожаловаться на ответ ИИ',
                    'Report AI answer',
                  ),
          ),
        ),
        if (_failed)
          Semantics(
            liveRegion: true,
            child: Text(
              tr(
                'Shikoyat yuborilmadi. Qayta urinib ko‘ring.',
                'Жалоба не отправлена. Попробуйте ещё раз.',
                'The report could not be sent. Try again.',
              ),
            ),
          ),
      ],
    );
  }
}
