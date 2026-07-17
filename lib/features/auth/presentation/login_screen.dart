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
import '../../../core/widgets/gradient_button.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 32),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                t('auth.login.title', language),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.text),
              ).animate().fadeIn(delay: 80.ms, duration: 350.ms),
              const SizedBox(height: 28),
              ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
              AppTextField(
                controller: _email,
                hint: t('auth.email.placeholder', language),
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(Icons.mail_outline, color: colors.textMuted, size: 20),
              ).animate().fadeIn(delay: 140.ms, duration: 320.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),
              PasswordField(controller: _password, hint: t('auth.password.placeholder', language))
                  .animate()
                  .fadeIn(delay: 190.ms, duration: 320.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(t('auth.forgot.password', language), style: TextStyle(color: colors.primary)),
                ),
              ),
              const SizedBox(height: 8),
              GradientButton(
                onPressed: _loading ? null : _handleLogin,
                loading: _loading,
                child: Text(t('auth.login.button', language)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(t('auth.divider.or', language), style: TextStyle(color: colors.textMuted)),
                  ),
                  Expanded(child: Divider(color: colors.border)),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _googleLoading ? null : _handleGoogle,
                icon: _googleLoading
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary))
                    : const Icon(Icons.g_mobiledata, size: 26),
                label: Text(t('auth.google.button', language)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.border, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t('auth.no.account', language), style: TextStyle(color: colors.textSecondary)),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: Text(t('auth.signup.button', language), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
