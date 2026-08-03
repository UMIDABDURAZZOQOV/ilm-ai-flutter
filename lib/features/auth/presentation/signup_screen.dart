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
import '../application/google_auth.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      await signInWithGoogle(ref);
    } catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    final language = ref.read(languageProvider);
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = t('auth.error.password.mismatch', language));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(authRepositoryProvider).signUp(
            SignUpRequest(name: _name.text.trim(), email: _email.text.trim(), password: _password.text),
          );
      if (mounted) context.push('/verify-email?email=${Uri.encodeComponent(res.email)}');
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
    final passwordsMatch = _confirmPassword.text.isNotEmpty && _password.text == _confirmPassword.text;

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
              Text(
                t('auth.signup.title', language),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: colors.text, letterSpacing: -0.5),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                t('auth.signup.subtitle', language),
                style: TextStyle(fontSize: 15, color: colors.textSecondary, fontWeight: FontWeight.w500),
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
              const SizedBox(height: 32),
              ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
              PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                borderRadius: 20,
                child: AppTextField(
                  controller: _name,
                  hint: t('auth.name.placeholder', language),
                  prefixIcon: Icon(Icons.person_outline, color: colors.textMuted, size: 22),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 16),
              PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                borderRadius: 20,
                child: AppTextField(
                  controller: _email,
                  hint: t('auth.email.placeholder', language),
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(Icons.mail_outline, color: colors.textMuted, size: 22),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 16),
              PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                borderRadius: 20,
                child: PasswordField(controller: _password, hint: t('auth.password.placeholder', language)),
              ).animate().fadeIn(delay: 250.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(t('auth.password.hint', language), style: TextStyle(fontSize: 13, color: colors.textMuted, fontWeight: FontWeight.w500)),
              ).animate().fadeIn(delay: 280.ms, duration: 300.ms),
              const SizedBox(height: 16),
              PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                borderRadius: 20,
                child: PasswordField(
                  controller: _confirmPassword,
                  hint: t('auth.confirm.password.placeholder', language),
                  onChanged: (_) => setState(() {}),
                ),
              ).animate().fadeIn(delay: 310.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              if (passwordsMatch) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: colors.success, size: 16),
                      const SizedBox(width: 6),
                      Text(t('auth.password.match.ok', language), style: TextStyle(fontSize: 13, color: colors.success, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ).animate().fadeIn(delay: 330.ms, duration: 300.ms),
              ],
              const SizedBox(height: 24),
              PremiumButton(
                onPressed: _loading ? null : _handleSignUp,
                loading: _loading,
                borderRadius: 20,
                child: Text(t('auth.signup.button', language)),
              ).animate().fadeIn(delay: 360.ms, duration: 350.ms),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.border, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(t('auth.divider.or', language), style: TextStyle(color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: colors.border, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),
              PremiumButton(
                onPressed: _googleLoading ? null : _handleGoogle,
                outline: true,
                borderRadius: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_googleLoading)
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.primary))
                    else
                      const Icon(Icons.g_mobiledata, size: 24),
                    const SizedBox(width: 12),
                    Text(t('auth.google.button', language)),
                  ],
                ),
              ).animate().fadeIn(delay: 390.ms, duration: 350.ms),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t('auth.have.account', language), style: TextStyle(color: colors.textSecondary, fontSize: 15)),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(t('auth.login.button', language), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ],
              ).animate().fadeIn(delay: 420.ms, duration: 350.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
