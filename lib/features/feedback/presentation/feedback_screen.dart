import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/application/auth_controller.dart';
import '../data/feedback_repository.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _message = TextEditingController();
  int _rating = 0;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  Future<void> _submit() async {
    if (_rating == 0) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(feedbackRepositoryProvider).submit(
            name: user?.name ?? '',
            email: user?.email ?? '',
            message: _message.text.trim(),
            rating: _rating,
          );
      setState(() => _sent = true);
    } catch (e) {
      final language = ref.read(languageProvider);
      setState(() => _error = t('feedback.error', language));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('feedback.title', language))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _sent
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 56, color: colors.success),
                      const SizedBox(height: 16),
                      Text(t('feedback.success', language), textAlign: TextAlign.center, style: TextStyle(color: colors.text, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t('feedback.desc', language), style: TextStyle(color: colors.textSecondary)),
                    const SizedBox(height: 24),
                    ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
                    Text(t('feedback.rating', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 1; i <= 5; i++)
                          IconButton(
                            icon: Icon(i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: colors.warning, size: 34),
                            onPressed: () => setState(() => _rating = i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(t('feedback.message', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _message,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: t('feedback.message.placeholder', language),
                        filled: true,
                        fillColor: colors.inputBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      onPressed: (_rating == 0 || _sending) ? null : _submit,
                      loading: _sending,
                      child: Text(t('feedback.submit', language)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
