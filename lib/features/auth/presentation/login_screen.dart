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
import '../application/google_auth.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(authRepositoryProvider).login(
            LoginRequest(email: _email.text.trim(), password: _password.text),
          );
      await ref.read(authControllerProvider.notifier).login(res);
    } catch (e) {
      final unverifiedEmail = getUnverifiedEmail(e);
      if (unverifiedEmail != null && mounted) {
        context.push('/verify-email?email=${Uri.encodeComponent(unverifiedEmail)}');
        return;
      }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(colors: [colors.primary, colors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                ),
              ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              Text(
                t('auth.login.title', language),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: colors.text, letterSpacing: -0.5),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                t('auth.login.subtitle', language),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: colors.textSecondary, fontWeight: FontWeight.w500),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
              const SizedBox(height: 36),
              ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(t('auth.forgot.password', language), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 12),
              PremiumButton(
                onPressed: _loading ? null : _handleLogin,
                loading: _loading,
                borderRadius: 20,
                child: Text(t('auth.login.button', language)),
              ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
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
              ).animate().fadeIn(delay: 350.ms, duration: 350.ms),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t('auth.no.account', language), style: TextStyle(color: colors.textSecondary, fontSize: 15)),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: Text(t('auth.signup.button', language), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 350.ms),
            ],
          ),
        ),
      ),
    );
  }
}
