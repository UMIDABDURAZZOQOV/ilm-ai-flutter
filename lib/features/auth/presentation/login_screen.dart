import '../../../core/widgets/motion.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/product_mode.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/ilmo_brand_mark.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/google_logo.dart';
import '../application/google_auth.dart';

/// Google-only entry. One button both signs up and logs in — Google has already
/// vetted the account, so we no longer ask for email + password. The email
/// endpoints still exist on the backend for support, just not in the UI.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _googleLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-warm the backend (Render free plan spins down after idle) so the
    // Google token exchange isn't the request that pays the ~30-60s wake-up
    // cost — fire it now, while the user is still picking their account.
    ref.read(dioProvider).get('/health').then((_) {}, onError: (_) {});
  }

  String _getAuthErrorMessage(Object err, String language) {
    String tr(String uz, String ru, String en) => language == 'ru'
        ? ru
        : language == 'en'
        ? en
        : uz;

    // Check for timeout or backend waking up (Render free tier cold start ~30-50s)
    final isTimeout =
        err is TimeoutException ||
        (err is DioException &&
            (err.type == DioExceptionType.connectionTimeout ||
                err.type == DioExceptionType.receiveTimeout ||
                err.type == DioExceptionType.sendTimeout)) ||
        (err is DioException &&
            err.response?.statusCode != null &&
            [502, 503, 504].contains(err.response!.statusCode)) ||
        err.toString().toLowerCase().contains('timeout');

    if (isTimeout) {
      return tr(
        "Server uyg'onmoqda, biroz kuting va qayta urinib ko'ring.",
        'Сервер просыпается, подождите немного и повторите попытку.',
        'Server is waking up, please wait a moment and try again.',
      );
    }

    if (err is DioException && err.type == DioExceptionType.connectionError) {
      return tr(
        "Internet aloqasi yo'q. Tarmoq ulanishini tekshiring.",
        'Нет подключения к интернету. Проверьте соединение.',
        'No internet connection. Please check your network.',
      );
    }

    if (err is DioException &&
        err.response?.statusCode != null &&
        err.response!.statusCode! >= 500) {
      return tr(
        "Serverda xatolik yuz berdi (${err.response!.statusCode}). Birozdan so'ng qayta urinib ko'ring.",
        'Ошибка сервера (${err.response!.statusCode}). Пожалуйста, повторите попытку позже.',
        'Server error (${err.response!.statusCode}). Please try again in a moment.',
      );
    }

    final extracted = extractError(err, language: ref.read(languageProvider));
    if (extracted.isNotEmpty &&
        extracted != 'An unexpected error occurred. Please try again.' &&
        extracted != 'Request failed. Please try again.') {
      return extracted;
    }

    return tr(
      "Kirishda xatolik yuz berdi. Qayta urinib ko'ring.",
      'Произошла ошибка при входе. Попробуйте еще раз.',
      'An error occurred during sign-in. Please try again.',
    );
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      final needsOnboarding = await signInWithGoogle(ref);
      if (mounted) {
        if (needsOnboarding) {
          context.go('/setup');
        } else {
          context.go(subjectsOnly ? '/learn' : '/home');
        }
      }
    } catch (e) {
      // Backing out of the Google sheet throws CANCELED — a user choice, not an error.
      final canceled = e.toString().toLowerCase().contains('cancel');
      if (mounted && !canceled) {
        final language = ref.read(languageProvider);
        setState(() => _error = _getAuthErrorMessage(e, language));
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    String tr(String uz, String ru, String en) => language == 'ru'
        ? ru
        : language == 'en'
        ? en
        : uz;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 64).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: IlmoBrandMark()),
                      const SizedBox(height: 16),
                      Text(
                        'ILM AI',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          t('auth.login.title', language),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: colors.text,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr(
                          "Google bilan bir marta bosib kiring — ro'yxatdan o'tish ham, kirish ham shu.",
                          'Войдите одним нажатием через Google — это и регистрация, и вход.',
                          'Continue with Google in one tap — it both signs you up and logs you in.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Semantics(
                        liveRegion: true,
                        child: ErrorBanner(
                          message: _error,
                          onDismiss: () => setState(() => _error = null),
                        ),
                      ),
                      PremiumButton(
                        key: const ValueKey('login_google'),
                        onPressed: _googleLoading ? null : _handleGoogle,
                        outline: true,
                        borderRadius: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_googleLoading)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  value: MediaQuery.disableAnimationsOf(context)
                                      ? .75
                                      : null,
                                  semanticsLabel: tr(
                                    'Kirilmoqda',
                                    'Выполняется вход',
                                    'Signing in',
                                  ),
                                  strokeWidth: 2.5,
                                  color: colors.primary,
                                ),
                              )
                            else
                              const GoogleLogo(size: 22),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                tr(
                                  'Google bilan davom etish',
                                  'Продолжить с Google',
                                  'Continue with Google',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).motion(context).fadeIn(duration: 220.ms, curve: Curves.easeOut),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
