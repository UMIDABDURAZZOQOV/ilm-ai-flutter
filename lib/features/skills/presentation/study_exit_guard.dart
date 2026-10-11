import 'package:flutter/material.dart';
import 'skill_ui.dart';

/// Both Android back and the close button go through the same confirmation.
class StudyExitGuard extends StatefulWidget {
  const StudyExitGuard({
    super.key,
    required this.active,
    required this.saving,
    required this.language,
    required this.child,
  });
  final bool active;
  final bool saving;
  final String language;
  final Widget child;

  @override
  State<StudyExitGuard> createState() => _StudyExitGuardState();
}

class _StudyExitGuardState extends State<StudyExitGuard> {
  bool _allowExit = false;
  bool _dialogOpen = false;

  Future<void> _confirm() async {
    if (_dialogOpen || widget.saving) return;
    _dialogOpen = true;
    final lang = widget.language;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.school_rounded,
          size: 44,
          color: Color(0xFF58CC02),
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
          str3(
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
    canPop: !widget.saving && (_allowExit || !widget.active),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirm();
    },
    child: widget.child,
  );
}
