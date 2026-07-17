import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/gradient_button.dart';
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
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.text), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('auth.signup.title', language),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.text),
              ),
              const SizedBox(height: 24),
              ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
              AppTextField(
                controller: _name,
                hint: t('auth.name.placeholder', language),
                prefixIcon: Icon(Icons.person_outline, color: colors.textMuted, size: 20),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _email,
                hint: t('auth.email.placeholder', language),
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(Icons.mail_outline, color: colors.textMuted, size: 20),
              ),
              const SizedBox(height: 12),
              PasswordField(controller: _password, hint: t('auth.password.placeholder', language)),
              const SizedBox(height: 4),
              Text(t('auth.password.hint', language), style: TextStyle(fontSize: 12, color: colors.textMuted)),
              const SizedBox(height: 12),
              PasswordField(
                controller: _confirmPassword,
                hint: t('auth.confirm.password.placeholder', language),
                onChanged: (_) => setState(() {}),
              ),
              if (passwordsMatch) ...[
                const SizedBox(height: 4),
                Text(t('auth.password.match.ok', language), style: TextStyle(fontSize: 12, color: colors.success)),
              ],
              const SizedBox(height: 20),
              GradientButton(
                onPressed: _loading ? null : _handleSignUp,
                loading: _loading,
                child: Text(t('auth.signup.button', language)),
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
                  Text(t('auth.have.account', language), style: TextStyle(color: colors.textSecondary)),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(t('auth.login.button', language), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
