import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/app_providers.dart';
import '../../skills/presentation/skill_ui.dart';
import '../application/auth_controller.dart';
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final storage = ref.read(secureStorageProvider);
      var secret = await storage.read(key: 'beta.installationCredential');
      if (secret == null) {
        secret = base64UrlEncode(
          List.generate(32, (_) => Random.secure().nextInt(256)),
        ).replaceAll('=', '');
        await storage.write(key: 'beta.installationCredential', value: secret);
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
      if (mounted) {
        context.go(ref.read(needsProfileSetupProvider) ? '/setup' : '/learn');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Beta serverga ulanib bo‘lmadi. Ulanishni tekshirib qayta urining.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return ref
        .watch(betaConfigProvider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(betaConfigProvider),
            child: Text(
              str3(
                lang,
                'Beta ulanishini qayta tekshirish',
                'Проверить подключение бета',
                'Retry beta connection',
              ),
            ),
          ),
          data: (config) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              if (config['google_configured'] != true)
                Text(
                  str3(
                    lang,
                    'Google kirish lokal beta serverida hali sozlanmagan.',
                    'Вход Google ещё не настроен на локальном бета-сервере.',
                    'Google sign-in is not configured on this local beta server.',
                  ),
                  textAlign: TextAlign.center,
                ),
              if (_error != null) Text(_error!, semanticsLabel: _error),
              if (config['test_auth_available'] == true)
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: Text(
                    _busy
                        ? str3(lang, 'Kirilmoqda…', 'Вход…', 'Signing in…')
                        : str3(
                            lang,
                            'Ichki beta orqali davom etish',
                            'Продолжить во внутренней бета',
                            'Continue in internal beta',
                          ),
                  ),
                ),
            ],
          ),
        );
  }
}
