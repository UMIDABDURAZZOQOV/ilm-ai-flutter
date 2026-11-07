import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/application/auth_controller.dart';
import '../../skills/presentation/skill_ui.dart';
import '../data/account_deletion_repository.dart';

class AccountDeletionButton extends ConsumerWidget {
  const AccountDeletionButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final lang = ref.watch(languageProvider);
    if (user == null) return const SizedBox.shrink();
    return TextButton.icon(
      key: const ValueKey('delete_account_entry'),
      icon: const Icon(Icons.person_remove_outlined),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
      label: Text(
        str3(lang, 'Akkauntni o‘chirish', 'Удалить аккаунт', 'Delete account'),
      ),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => _DeletionDialog(userId: user.userId),
      ),
    );
  }
}

class _DeletionDialog extends ConsumerStatefulWidget {
  const _DeletionDialog({required this.userId});
  final int userId;
  @override
  ConsumerState<_DeletionDialog> createState() => _DeletionDialogState();
}

class _DeletionDialogState extends ConsumerState<_DeletionDialog> {
  final _code = TextEditingController();
  CancelToken? _cancel;
  String? _requestId, _error;
  bool _busy = false, _consent = false, _closing = false;
  late final int _sessionGeneration;

  @override
  void initState() {
    super.initState();
    _sessionGeneration = ref.read(secureTokenStorageProvider).sessionGeneration;
  }

  bool get _sameSession =>
      ref.read(currentUserIdProvider) == widget.userId &&
      ref.read(secureTokenStorageProvider).sessionGeneration ==
          _sessionGeneration;

  @override
  void dispose() {
    _cancel?.cancel('deletion_dialog_closed');
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_consent || !_sameSession) return;
    final lang = ref.read(languageProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    final cancel = _cancel = CancelToken();
    try {
      final repository = ref.read(accountDeletionRepositoryProvider);
      if (_requestId == null) {
        final request = await repository.request(cancel);
        if (!mounted || !_sameSession) return;
        setState(() => _requestId = request);
      } else {
        final result = await repository.confirm(
          _requestId!,
          _code.text.trim(),
          cancel,
        );
        if (!mounted || !_sameSession) return;
        if (result == 'retention_review') {
          setState(
            () => _error = str3(
              lang,
              'So‘rov saqlandi. Moliyaviy ma’lumotlar alohida ko‘rib chiqiladi; akkaunt hali o‘chirilmagan.',
              'Запрос сохранён. Финансовые данные требуют проверки; аккаунт ещё не удалён.',
              'Request saved. Financial records need review; your account has not been deleted.',
            ),
          );
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        final auth = ref.read(authControllerProvider.notifier);
        _closing = true;
        Navigator.of(context).pop();
        await auth.finishAccountDeletion(
          widget.userId,
          sessionGeneration: _sessionGeneration,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result == 'deleted'
                  ? str3(
                      lang,
                      'Akkaunt o‘chirildi',
                      'Аккаунт удалён',
                      'Account deleted',
                    )
                  : str3(
                      lang,
                      'Akkaunt yopildi. Fayllarni tozalash davom etadi.',
                      'Аккаунт закрыт. Очистка файлов продолжается.',
                      'Account closed. File cleanup is pending.',
                    ),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted || (error is DioException && CancelToken.isCancel(error))) {
        return;
      }
      setState(
        () => _error = str3(
          lang,
          'So‘rov tasdiqlanmadi. Email kodini va ulanishni tekshiring. Natija noaniq bo‘lsa, shu kod bilan qayta urinib ko‘ring.',
          'Запрос не подтверждён. Проверьте код и соединение. При неизвестном результате повторите с тем же кодом.',
          'Request not confirmed. Check your code and connection. If the result is unknown, retry with the same code.',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(currentUserIdProvider, (_, next) {
      if (next != widget.userId && mounted && !_closing) {
        _closing = true;
        Navigator.of(context).pop();
      }
    });
    final lang = ref.watch(languageProvider);
    return AlertDialog(
      scrollable: true,
      title: Text(
        str3(lang, 'Akkauntni o‘chirish', 'Удалить аккаунт', 'Delete account'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            str3(
              lang,
              'Profilingiz, progress, javoblar va XP o‘chiriladi. Bu amal qaytarilmaydi. Emailingizga kelgan kod bilan tasdiqlaysiz.',
              'Профиль, прогресс, ответы и XP будут удалены безвозвратно. Подтвердите кодом из письма.',
              'Your profile, progress, answers and XP will be deleted permanently. Confirm with the email verification code.',
            ),
          ),
          CheckboxListTile(
            key: const ValueKey('delete_account_consent'),
            contentPadding: EdgeInsets.zero,
            value: _consent,
            onChanged: _busy
                ? null
                : (value) => setState(() => _consent = value ?? false),
            title: Text(
              str3(
                lang,
                'Butunlay o‘chirishga roziman',
                'Подтверждаю удаление',
                'I confirm permanent deletion',
              ),
            ),
          ),
          if (_requestId != null)
            TextField(
              controller: _code,
              key: const ValueKey('delete_account_code'),
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: str3(
                  lang,
                  'Email kodi',
                  'Код из письма',
                  'Email code',
                ),
              ),
            ),
          if (_error != null)
            Text(_error!, key: const ValueKey('delete_account_error')),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          const SizedBox(height: 16),
          // Actions scroll with the content when large text and the keyboard
          // leave too little vertical space for AlertDialog's fixed actions.
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: Text(str3(lang, 'Bekor qilish', 'Отмена', 'Cancel')),
              ),
              FilledButton(
                key: const ValueKey('delete_account_submit'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed:
                    _busy ||
                        !_consent ||
                        (_requestId != null &&
                            !RegExp(r'^\d{6}$').hasMatch(_code.text))
                    ? null
                    : _submit,
                child: Text(
                  _requestId == null
                      ? str3(
                          lang,
                          'Tasdiqlash kodini olish',
                          'Получить код',
                          'Send verification code',
                        )
                      : str3(
                          lang,
                          'Akkauntni o‘chirish',
                          'Удалить аккаунт',
                          'Delete account',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
