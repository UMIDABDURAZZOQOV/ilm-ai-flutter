import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../application/auth_controller.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  int _step = 1; // 1 = request code, 2 = confirm code + new password
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(
            PasswordResetRequestBody(email: _email.text.trim()),
          );
      if (mounted) setState(() => _step = 2);
    } catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleReset() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(authRepositoryProvider).confirmPasswordReset(
            PasswordResetConfirmRequest(email: _email.text.trim(), code: _code.text.trim(), newPassword: _newPassword.text),
          );
      await ref.read(authControllerProvider.notifier).login(res);
    } catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.text, size: 24), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('forgot.title', language), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: colors.text, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text(t('forgot.subtitle', language), style: TextStyle(fontSize: 15, color: colors.textSecondary, fontWeight: FontWeight.w500, height: 1.5)),
              const SizedBox(height: 32),
              ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
              if (_step == 1) ...[
                PremiumCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  borderRadius: 20,
                  child: AppTextField(
                    controller: _email,
                    hint: t('auth.email.placeholder', language),
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.mail_outline, color: colors.textMuted, size: 22),
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
                PremiumButton(
                  onPressed: _loading ? null : _handleSendCode,
                  loading: _loading,
                  borderRadius: 20,
                  child: Text(t('forgot.send.button', language)),
                ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
              ] else ...[
                PremiumCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  borderRadius: 20,
                  child: TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.text, letterSpacing: 12),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: colors.inputBackground,
                      hintText: t('verify.code.placeholder', language),
                      hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.textMuted, letterSpacing: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.border, width: 1.5)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.border, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.primary, width: 2)),
                    ),
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 16),
                PremiumCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  borderRadius: 20,
                  child: PasswordField(controller: _newPassword, hint: t('forgot.new.password.placeholder', language)),
                ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
                PremiumButton(
                  onPressed: _loading ? null : _handleReset,
                  loading: _loading,
                  borderRadius: 20,
                  child: Text(t('forgot.reset.button', language)),
                ).animate().fadeIn(delay: 250.ms, duration: 350.ms),
              ],
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(t('forgot.back.to.login', language), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
            ],
          ),
        ),
      ),
    );
  }
}
