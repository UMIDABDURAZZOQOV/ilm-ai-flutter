import 'package:flutter/material.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'skill_ui.dart';

/// Both Android back and the close button go through the same confirmation.
class StudyExitGuard extends StatefulWidget {
  const StudyExitGuard({
    super.key,
    required this.active,
    required this.saving,
    required this.language,
    required this.child,
    this.saveBeforeExit,
  });
  final bool active;
  final bool saving;
  final String language;
  final Widget child;

  /// Only flows with a persisted local draft supply this. Practice stays unsaved.
  final Future<bool> Function()? saveBeforeExit;

  @override
  State<StudyExitGuard> createState() => _StudyExitGuardState();
}

class _StudyExitGuardState extends State<StudyExitGuard> {
  bool _allowExit = false;
  bool _dialogOpen = false;
  bool _preparing = false;

  Future<void> _confirm() async {
    if (_dialogOpen || widget.saving) return;
    _dialogOpen = true;
    final lang = widget.language;
    var saved = false;
    if (widget.saveBeforeExit != null) {
      setState(() => _preparing = true);
      try {
        saved = await widget.saveBeforeExit!();
      } catch (_) {
        saved = false;
      }
      if (!mounted) return;
      setState(() => _preparing = false);
    }
    if (!mounted) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.school_rounded,
          size: 44,
          color:
              Theme.of(ctx).extension<AppColors>()?.colors.primary ??
              const Color(0xFF2A1F6B),
        ),
        title: Text(
          str3(
            lang,
            'Darsdan chiqasizmi?',
            'Выйти из урока?',
            'Leave this lesson?',
          ),
        ),
        content: Text(
          saved
              ? str3(
                  lang,
                  'Urinish shu qurilmada saqlandi. Dars muddati tugamagan bo‘lsa, keyin davom ettirasiz. Oldingi yutuqlaringiz saqlanadi.',
                  'Попытка сохранена на этом устройстве. Вы сможете продолжить, если срок урока не истёк. Предыдущие достижения сохранятся.',
                  'Your attempt is saved on this device. You can resume while the lesson is still valid. Your earlier progress is safe.',
                )
              : widget.saveBeforeExit != null
              ? str3(
                  lang,
                  'Oxirgi o‘zgarishlarni saqlab bo‘lmadi. Chiqsangiz, ular yo‘qolishi mumkin. Oldingi yutuqlaringiz saqlanadi.',
                  'Не удалось сохранить последние изменения. Если выйти, они могут потеряться. Предыдущие достижения сохранятся.',
                  'Your latest changes could not be saved. Leaving may lose them. Your earlier progress is safe.',
                )
              : str3(
                  lang,
                  'Tugallanmagan urinish saqlanmaydi. Oldingi yutuqlaringiz qoladi.',
                  'Незавершённая попытка не сохранится. Предыдущие достижения останутся.',
                  'This unfinished attempt will not be saved. Your earlier progress is safe.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(str3(lang, 'Chiqish', 'Выйти', 'Leave')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              str3(lang, 'Davom etish', 'Продолжить', 'Keep learning'),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _dialogOpen = false;
    if (leave != true || widget.saving) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_preparing && !widget.saving && (_allowExit || !widget.active),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirm();
    },
    child: Stack(
      children: [
        AbsorbPointer(absorbing: _preparing, child: widget.child),
        if (_preparing)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    ),
  );
}
