import 'package:flutter/material.dart';
import 'study_exit_dialog.dart';

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
      animationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 180),
              reverseDuration: Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
            ),
      builder: (ctx) => StudyExitDialog(
        language: lang,
        status: saved
            ? StudyExitStatus.saved
            : widget.saveBeforeExit != null
            ? StudyExitStatus.saveFailed
            : StudyExitStatus.unsaved,
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
