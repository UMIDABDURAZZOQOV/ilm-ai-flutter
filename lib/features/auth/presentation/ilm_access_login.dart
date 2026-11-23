import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/integrated_beta.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/app_providers.dart';
import '../../skills/presentation/skill_ui.dart';
import '../application/auth_controller.dart';
import '../data/auth_models.dart';
import 'qa_age_check.dart';

class IlmAccessLogin extends ConsumerStatefulWidget {
  const IlmAccessLogin({
    super.key,
    required this.blocked,
    required this.onBusyChanged,
  });

  final bool blocked;
  final ValueChanged<bool> onBusyChanged;

  @override
  ConsumerState<IlmAccessLogin> createState() => _IlmAccessLoginState();
}

class _IlmAccessLoginState extends ConsumerState<IlmAccessLogin> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening || widget.blocked) return;
    setState(() => _opening = true);
    widget.onBusyChanged(true);
    final language = ref.read(languageProvider);
    try {
      final result = await showDialog<({AuthResponse auth, bool setup})>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _AccessDialog(),
      );
      if (result == null || !mounted) return;
      await ref
          .read(authControllerProvider.notifier)
          .login(result.auth, needsOnboarding: result.setup);
      if (!mounted) return;
      ref.read(onboardingCompleteProvider.notifier).complete();
      context.go(ref.read(needsProfileSetupProvider) ? '/setup' : '/learn');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              str3(
                language,
                'Sessiya saqlanmadi. Kalit bilan qayta kiring.',
                'Сессия не сохранена. Войдите снова с ключом.',
                'Session could not be saved. Sign in again with your key.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ilmAccessQaEnabled(apiBaseUrl)) return const SizedBox.shrink();
    final lang = ref.watch(languageProvider);
    return OutlinedButton.icon(
      key: const ValueKey('ilm_access_open'),
      onPressed: _opening || widget.blocked ? null : _open,
      icon: const Icon(Icons.key_outlined),
      label: Text(
        str3(
          lang,
          'ILM kaliti bilan kirish',
          'Вход с ключом ILM',
          'Sign in with an ILM key',
        ),
      ),
    );
  }
}

class _AccessDialog extends ConsumerStatefulWidget {
  const _AccessDialog();

  @override
  ConsumerState<_AccessDialog> createState() => _AccessDialogState();
}

class _AccessDialogState extends ConsumerState<_AccessDialog> {
  final _input = TextEditingController();
  final _format = RegExp(r'^ilm1_[A-Za-z0-9_-]{43}$');
  final _backupFormat = RegExp(r'^ilmr1_[A-Za-z0-9_-]{43}$');
  String? _newKey;
  String? _newBackup;
  String? _error;
  bool _recovering = false;
  bool _busy = false;
  bool _saved = false;
  CancelToken? _request;

  String _makeKey(String prefix) {
    final random = Random.secure();
    final secret = base64UrlEncode(
      List.generate(32, (_) => random.nextInt(256)),
    );
    return prefix + secret.replaceAll('=', '');
  }

  void _startNewKey({bool recover = false}) {
    setState(() {
      _recovering = recover;
      _input.clear();
      _newKey = _makeKey('ilm1_');
      _newBackup = _makeKey('ilmr1_');
      _saved = false;
      _error = null;
    });
  }

  Future<void> _startNewAccount() async {
    if (_busy) return;
    setState(() => _busy = true);
    final language = ref.read(languageProvider);
    final allowed = await confirmQaAdultEntry(context, language);
    if (!mounted) return;
    setState(() => _busy = false);
    if (allowed) _startNewKey();
  }

  String get _entered => _input.text.trim();
  String get _key => _newKey ?? _entered;
  bool get _canSubmit =>
      !_busy &&
      (_recovering
          ? _backupFormat.hasMatch(_entered)
          : _format.hasMatch(_key)) &&
      (_newBackup == null || _saved);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final lang = ref.read(languageProvider);
    final cancel = _request = CancelToken();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/auth/ilm/access',
            data: {
              'key': _key,
              'mode': _recovering
                  ? 'recover'
                  : _newKey == null
                  ? 'login'
                  : 'create',
              if (_recovering) ...{
                'recovery_key': _entered,
                'next_recovery_key': _newBackup,
              } else if (_newBackup != null)
                'recovery_key': _newBackup,
            },
            options: Options(extra: {'skipAuth': true}),
            cancelToken: cancel,
          );
      final payload = response.data;
      if (payload == null || payload['needs_onboarding'] is! bool) {
        throw const FormatException('Invalid ILM access response');
      }
      final auth = AuthResponse.fromJson(payload);
      if (mounted) {
        Navigator.of(
          context,
        ).pop((auth: auth, setup: payload['needs_onboarding'] as bool));
      }
    } catch (error) {
      if (!mounted) return;
      final badKey = error is DioException && error.response?.statusCode == 401;
      setState(
        () => _error = badKey && _recovering
            ? str3(
                lang,
                'Zaxira kalit ishlamadi. Avval tiklagan bo‘lsangiz, yangi kirish kalitini sinang.',
                'Резервный ключ не подошёл. Если профиль уже восстановлен, попробуйте новый ключ входа.',
                'Backup key rejected. If recovery already succeeded, try your new sign-in key.',
              )
            : badKey
            ? str3(
                lang,
                'Kalit topilmadi. Kalitni tekshiring.',
                'Ключ не найден. Проверьте ключ.',
                'Key not found. Check your key.',
              )
            : str3(
                lang,
                'Kirish bajarilmadi. Qayta urinib ko‘ring.',
                'Не удалось войти. Повторите попытку.',
                'Sign-in failed. Try again.',
              ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _request?.cancel();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final newKey = _newKey;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        scrollable: true,
        title: Text(
          str3(lang, 'ILM kirish kaliti', 'Ключ входа ILM', 'ILM sign-in key'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (newKey == null || _recovering)
              TextField(
                key: const ValueKey('ilm_access_input'),
                controller: _input,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                enabled: !_busy,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: _recovering
                      ? str3(
                          lang,
                          'Saqlangan zaxira kalit',
                          'Сохранённый резервный ключ',
                          'Saved backup key',
                        )
                      : str3(lang, 'Kalitingiz', 'Ваш ключ', 'Your key'),
                ),
              ),
            if (newKey == null && _newBackup == null) ...[
              TextButton(
                onPressed: _busy ? null : _startNewAccount,
                child: Text(
                  str3(
                    lang,
                    'Yangi kalit yaratish',
                    'Создать ключ',
                    'Create a key',
                  ),
                ),
              ),
              TextButton(
                onPressed: _busy ? null : () => _startNewKey(recover: true),
                child: Text(
                  str3(
                    lang,
                    'Zaxira kalit bilan tiklash',
                    'Восстановить по резервному ключу',
                    'Recover with a backup key',
                  ),
                ),
              ),
              if (_format.hasMatch(_entered))
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _newBackup = _makeKey('ilmr1_');
                          _saved = false;
                          _error = null;
                        }),
                  child: Text(
                    str3(
                      lang,
                      'Zaxira kalit yaratish',
                      'Создать резервный ключ',
                      'Create a backup key',
                    ),
                  ),
                ),
            ],
            if (newKey != null) ...[
              const SizedBox(height: 12),
              Text(
                str3(
                  lang,
                  'Yangi kirish kaliti',
                  'Новый ключ входа',
                  'New sign-in key',
                ),
              ),
              SelectableText(
                newKey,
                key: const ValueKey('ilm_access_generated'),
              ),
            ],
            if (_newBackup case final backup?) ...[
              const SizedBox(height: 12),
              Text(
                str3(
                  lang,
                  'Yangi zaxira kalit',
                  'Новый резервный ключ',
                  'New backup key',
                ),
              ),
              SelectableText(
                backup,
                key: const ValueKey('ilm_backup_generated'),
              ),
              Text(
                str3(
                  lang,
                  'Zaxira kalitni alohida xavfsiz joyda saqlang. U kirish kaliti yo‘qolsa, profilni tiklaydi.',
                  'Храните резервный ключ отдельно. Он восстановит профиль при потере ключа входа.',
                  'Keep your backup key somewhere safe and separate. It restores your profile if you lose your sign-in key.',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _saved,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _saved = value == true),
                title: Text(
                  newKey == null
                      ? str3(
                          lang,
                          'Zaxira kalitni saqladim',
                          'Я сохранил резервный ключ',
                          'I saved my backup key',
                        )
                      : str3(
                          lang,
                          'Ikkala kalitni saqladim',
                          'Я сохранил оба ключа',
                          'I saved both keys',
                        ),
                ),
              ),
            ],
            if (_error case final error?)
              Semantics(liveRegion: true, child: Text(error)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(str3(lang, 'Bekor qilish', 'Отмена', 'Cancel')),
          ),
          FilledButton(
            key: const ValueKey('ilm_access_submit'),
            onPressed: _canSubmit ? _submit : null,
            child: Text(
              _busy
                  ? str3(lang, 'Kirilmoqda…', 'Вход…', 'Signing in…')
                  : str3(lang, 'Davom etish', 'Продолжить', 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
