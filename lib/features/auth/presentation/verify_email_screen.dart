import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/countdown_controller.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/gradient_button.dart';
import '../application/auth_controller.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

const _resendCooldownSeconds = 60;

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  final _cooldown = CountdownController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cooldown.addListener(_onTick);
    _cooldown.start(_resendCooldownSeconds);
  }

  void _onTick() => setState(() {});

  @override
  void dispose() {
    _cooldown.removeListener(_onTick);
    _cooldown.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_code.text.trim().length != 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(authRepositoryProvider).verifyEmail(
            VerifyEmailRequest(email: widget.email, code: _code.text.trim()),
          );
      await ref.read(authControllerProvider.notifier).login(res);
    } catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_cooldown.remaining > 0) return;
    setState(() => _error = null);
    try {
      await ref.read(authRepositoryProvider).resendCode(
            ResendCodeRequest(email: widget.email, purpose: 'signup'),
          );
      _cooldown.start(_resendCooldownSeconds);
    } catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: colors.primaryLight, borderRadius: BorderRadius.circular(18)),
                  child: Icon(Icons.mail_outline, color: colors.primary, size: 26),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t('verify.title', language),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.text),
              ),
              const SizedBox(height: 8),
              Text(
                t('verify.subtitle', language).replaceAll('{email}', widget.email),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: colors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                t('verify.check.spam', language),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.warning),
              ),
              const SizedBox(height: 24),
              ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                onChanged: (v) => setState(() {}),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.text, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: colors.inputBackground,
                  hintText: t('verify.code.placeholder', language),
                  hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.textMuted, letterSpacing: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                onPressed: (_loading || _code.text.trim().length != 6) ? null : _handleVerify,
                loading: _loading,
                child: Text(t('verify.button', language)),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _cooldown.remaining > 0 ? null : _handleResend,
                  child: Text(
                    _cooldown.remaining > 0
                        ? t('verify.resend.wait', language).replaceAll('{s}', '${_cooldown.remaining}')
                        : t('verify.resend', language),
                    style: TextStyle(color: _cooldown.remaining > 0 ? colors.textMuted : colors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
