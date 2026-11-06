import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/app_providers.dart';
import '../../skills/presentation/skill_ui.dart';
import '../application/auth_controller.dart';
import '../application/google_auth.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../data/auth_models.dart';

final betaConfigProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async =>
      (await ref.watch(dioProvider).get<Map<String, dynamic>>('/beta/config'))
          .data!,
);

/// Local beta-only identity; its random credential is generated on this device,
/// stored in Android secure storage, and never compiled or shown as a QA code.
class BetaLogin extends ConsumerStatefulWidget {
  const BetaLogin({super.key});
  @override
  ConsumerState<BetaLogin> createState() => _BetaLoginState();
}

class _BetaLoginState extends ConsumerState<BetaLogin> {
  bool _busy = false;
  String? _error;
  Future<void> _login() async {
    if (_busy) return;
    final config = ref.read(betaConfigProvider).valueOrNull;
    if (config == null) {
      ref.invalidate(betaConfigProvider);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (config['google_configured'] == true) {
        await signInWithGoogle(ref);
      } else if (config['test_auth_available'] == true) {
        final storage = ref.read(secureStorageProvider);
        var secret = await storage.read(key: 'beta.installationCredential');
        if (secret == null) {
          secret = base64UrlEncode(
            List.generate(32, (_) => Random.secure().nextInt(256)),
          ).replaceAll('=', '');
          await storage.write(
            key: 'beta.installationCredential',
            value: secret,
          );
        }
        final response = await ref
            .read(dioProvider)
            .post<Map<String, dynamic>>(
              '/beta/auth/test-login',
              data: {'installation_secret': secret},
            );
        final data = response.data!;
        await ref
            .read(authControllerProvider.notifier)
            .login(
              AuthResponse.fromJson(data),
              needsOnboarding: data['needs_onboarding'] == true,
            );
      } else {
        throw StateError('Authentication is unavailable');
      }
      if (mounted && ref.read(authControllerProvider).valueOrNull != null) {
        ref.read(onboardingCompleteProvider.notifier).complete();
        context.go(ref.read(needsProfileSetupProvider) ? '/setup' : '/learn');
      }
    } catch (error) {
      if (mounted && !error.toString().toLowerCase().contains('cancel')) {
        final lang = ref.read(languageProvider);
        setState(
          () => _error = str3(
            lang,
            'Ulanish yoki autentifikatsiya bajarilmadi. Qayta urining.',
            'Не удалось подключиться или подтвердить аккаунт. Повторите попытку.',
            'Connection or authentication failed. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final config = ref.watch(betaConfigProvider);
    final data = config.valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data != null && data['google_configured'] != true) ...[
          Text(
            str3(
              lang,
              'Google kirish lokal beta serverida hali sozlanmagan.',
              'Вход Google ещё не настроен на локальном бета-сервере.',
              'Google sign-in is not configured on this local beta server.',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            str3(
              lang,
              'Ichki beta: shu qurilmadagi akkaunt ishlatiladi.',
              'Внутренняя бета: используется аккаунт этого устройства.',
              'Internal beta: uses the account on this device.',
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (_error != null || config.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _error ??
                  str3(
                    lang,
                    'Beta serverga ulanib bo‘lmadi. Qayta urining.',
                    'Нет подключения к бета-серверу. Повторите попытку.',
                    'Could not connect to the beta server. Please try again.',
                  ),
              semanticsLabel: _error,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        Duo3DButton(
          key: const ValueKey('beta_register'),
          onPressed: _busy || config.isLoading ? null : _login,
          child: _busy || config.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        str3(lang, 'Kutilmoqda…', 'Подождите…', 'Please wait…'),
                      ),
                    ),
                  ],
                )
              : Text(
                  str3(
                    lang,
                    'RO‘YXATDAN O‘TISH',
                    'ЗАРЕГИСТРИРОВАТЬСЯ',
                    'SIGN UP',
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ],
    );
  }
}
