import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/error_message.dart';
import '../../../core/widgets/error_banner.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

class PasswordAccessResult {
  const PasswordAccessResult(this.authentication, this.needsOnboarding);
  final AuthResponse authentication;
  final bool needsOnboarding;
}

/// Google is optional. This form uses the same verified server password/session
/// contracts; it never creates an account after a failed existing-user login.
class PasswordAccessSheet extends StatefulWidget {
  const PasswordAccessSheet({
    super.key,
    required this.repository,
    required this.language,
  });
  final AuthRepository repository;
  final String language;
  @override
  State<PasswordAccessSheet> createState() => _PasswordAccessSheetState();
}

class _PasswordAccessSheetState extends State<PasswordAccessSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _code = TextEditingController();
  bool _create = false, _busy = false, _reset = false;
  String? _verificationEmail, _error;
  String tr(String uz, String ru, String en) => widget.language == 'uz'
      ? uz
      : widget.language == 'ru'
      ? ru
      : en;

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirmation, _code]) {
      controller.clear();
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      AuthResponse? authenticated;
      if (_verificationEmail != null) {
        authenticated = _reset
            ? await widget.repository.confirmPasswordReset(
                PasswordResetConfirmRequest(
                  email: _verificationEmail!,
                  code: _code.text.trim(),
                  newPassword: _password.text,
                ),
              )
            : await widget.repository.verifyEmail(
                VerifyEmailRequest(
                  email: _verificationEmail!,
                  code: _code.text.trim(),
                ),
              );
      } else if (_create) {
        final response = await widget.repository.registerPassword(
          SignUpRequest(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          ),
        );
        if (response.verificationEmail != null) {
          if (mounted) {
            setState(() => _verificationEmail = response.verificationEmail);
          }
          return;
        }
        authenticated = response.authentication;
      } else {
        authenticated = await widget.repository.login(
          LoginRequest(email: _email.text.trim(), password: _password.text),
        );
      }
      if (authenticated == null) {
        throw const FormatException('Invalid authentication response');
      }
      final setup = await widget.repository.passwordNeedsOnboarding(
        authenticated,
      );
      if (mounted) {
        Navigator.of(context).pop(PasswordAccessResult(authenticated, setup));
      }
    } catch (error) {
      if (!mounted) return;
      if (error is DioException &&
          error.response?.statusCode == 403 &&
          error.response?.data is Map &&
          error.response?.data['detail'] is Map &&
          error.response?.data['detail']['code'] == 'email_not_verified') {
        setState(() => _verificationEmail = _email.text.trim());
      } else {
        setState(() => _error = extractError(error, language: widget.language));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recover() async {
    if (_busy || _email.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.requestPasswordReset(
        PasswordResetRequestBody(email: _email.text.trim()),
      );
      if (mounted) {
        setState(() {
          _reset = true;
          _verificationEmail = _email.text.trim();
          _password.clear();
          _confirmation.clear();
        });
      }
    } catch (error) {
      if (!mounted) return;
      final unavailable =
          error is DioException &&
          error.response?.data is Map &&
          error.response?.data['detail'] ==
              'secure_password_recovery_requires_delivery_service';
      setState(
        () => _error = unavailable
            ? tr(
                'Parolni xavfsiz tiklash xizmati hozir yoqilmagan. Yordam xizmatiga murojaat qiling.',
                'Безопасное восстановление пароля пока не настроено. Обратитесь в поддержку.',
                'Secure password recovery is not configured yet. Contact support.',
              )
            : extractError(error, language: widget.language),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('Email va parol', 'Почта и пароль', 'Email and password'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (_verificationEmail == null) ...[
                  DropdownButtonFormField<bool>(
                    key: const ValueKey('password_account_mode'),
                    initialValue: _create,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: false,
                        child: Text(
                          tr(
                            'Mavjud akkaunt',
                            'Существующий аккаунт',
                            'Existing account',
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text(
                          tr('Yangi akkaunt', 'Новый аккаунт', 'New account'),
                        ),
                      ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            _create = value!;
                            _error = null;
                          }),
                  ),
                  if (_create)
                    TextFormField(
                      key: const ValueKey('password_name'),
                      controller: _name,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        labelText: tr('Ism', 'Имя', 'Name'),
                      ),
                      autofillHints: const [AutofillHints.name],
                      validator: (value) => value!.trim().length < 2
                          ? tr(
                              'Ismingizni kiriting',
                              'Введите имя',
                              'Enter your name',
                            )
                          : null,
                    ),
                  TextFormField(
                    key: const ValueKey('password_email'),
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                      labelText: tr('Email', 'Почта', 'Email'),
                    ),
                    validator: (value) =>
                        !RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(value!.trim())
                        ? tr(
                            'Emailni tekshiring',
                            'Проверьте почту',
                            'Check your email',
                          )
                        : null,
                  ),
                  TextFormField(
                    key: const ValueKey('password_secret'),
                    controller: _password,
                    enabled: !_busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: [
                      _create
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      labelText: tr('Parol', 'Пароль', 'Password'),
                    ),
                    validator: (value) =>
                        value!.isEmpty || (_create && value.length < 8)
                        ? tr(
                            'Parolni tekshiring (yangi parol: kamida 8 belgi)',
                            'Проверьте пароль (новый: минимум 8 символов)',
                            'Check your password (new password: at least 8 characters)',
                          )
                        : null,
                  ),
                  if (_create)
                    TextFormField(
                      key: const ValueKey('password_confirmation'),
                      controller: _confirmation,
                      enabled: !_busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: tr(
                          'Parolni takrorlang',
                          'Повторите пароль',
                          'Repeat password',
                        ),
                      ),
                      validator: (value) => value != _password.text
                          ? tr(
                              'Parollar mos emas',
                              'Пароли не совпадают',
                              'Passwords do not match',
                            )
                          : null,
                    ),
                ] else ...[
                  Text(
                    tr(
                      'Server emailni tasdiqlashni so‘radi. Yuborilgan kodni kiriting.',
                      'Сервер запросил подтверждение почты. Введите полученный код.',
                      'The server requires email verification. Enter the delivered code.',
                    ),
                  ),
                  TextFormField(
                    key: const ValueKey('password_email_code'),
                    controller: _code,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr(
                        'Tasdiqlash kodi',
                        'Код подтверждения',
                        'Verification code',
                      ),
                    ),
                    validator: (value) =>
                        !RegExp(r'^\d{6}$').hasMatch(value!.trim())
                        ? tr(
                            '6 xonali kodni kiriting',
                            'Введите 6 цифр',
                            'Enter 6 digits',
                          )
                        : null,
                  ),
                  if (_reset) ...[
                    TextFormField(
                      key: const ValueKey('password_reset_new'),
                      controller: _password,
                      enabled: !_busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: tr(
                          'Yangi parol',
                          'Новый пароль',
                          'New password',
                        ),
                      ),
                      validator: (value) => value!.length < 8
                          ? tr(
                              'Kamida 8 belgi',
                              'Минимум 8 символов',
                              'At least 8 characters',
                            )
                          : null,
                    ),
                    TextFormField(
                      key: const ValueKey('password_reset_confirmation'),
                      controller: _confirmation,
                      enabled: !_busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: tr(
                          'Parolni takrorlang',
                          'Повторите пароль',
                          'Repeat password',
                        ),
                      ),
                      validator: (value) => value != _password.text
                          ? tr(
                              'Parollar mos emas',
                              'Пароли не совпадают',
                              'Passwords do not match',
                            )
                          : null,
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                ErrorBanner(message: _error),
                FilledButton(
                  key: const ValueKey('password_continue'),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(tr('Davom etish', 'Продолжить', 'Continue')),
                ),
                if (!_create && _verificationEmail == null)
                  TextButton(
                    onPressed: _busy ? null : _recover,
                    child: Text(
                      tr(
                        'Parolni tiklash',
                        'Восстановить пароль',
                        'Recover password',
                      ),
                    ),
                  ),
                TextButton(
                  key: const ValueKey('password_cancel'),
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: Text(tr('Bekor qilish', 'Отмена', 'Cancel')),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
