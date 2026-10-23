import 'package:flutter/material.dart';

/// Directional fade-through with retained tab state and isolated input/focus.
/// Static gates stay outside frame builders; only transforms/alpha animate.
class IlmTabView extends StatefulWidget {
  const IlmTabView({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;
  @override
  State<IlmTabView> createState() => _IlmTabViewState();
}

class _IlmTabViewState extends State<IlmTabView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _incoming, _exitProgress;
  late Animation<double> _outgoing;
  late Animation<Offset> _enterOffset, _exitOffset;
  int? _previous;
  bool _reduced = false, _acceptInput = true;
  static const _still = AlwaysStoppedAnimation<Offset>(Offset.zero);
  static const _hidden = AlwaysStoppedAnimation<double>(0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
    // One page is painted at a time; full-screen opacity layers never overlap.
    _incoming = CurveTween(
      curve: const Interval(.30, 1, curve: Curves.easeOutCubic),
    ).animate(_controller);
    _exitProgress = CurveTween(
      curve: const Interval(0, .30, curve: Curves.easeOutCubic),
    ).animate(_controller);
    _outgoing = ReverseAnimation(_exitProgress);
    _enterOffset = Tween<Offset>(
      begin: const Offset(12, 0),
      end: Offset.zero,
    ).animate(_incoming);
    _exitOffset = _still;
    _controller.addListener(_updateInput);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _previous != null) {
        setState(() => _previous = null);
      }
    });
  }

  void _updateInput() {
    final accept = _incoming.value >= .5;
    if (accept != _acceptInput) setState(() => _acceptInput = accept);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _previous = null;
      _acceptInput = true;
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant IlmTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    final oldOpacity = _incoming.value;
    final oldOffset = _enterOffset.value;
    var direction = widget.index > oldWidget.index ? 1.0 : -1.0;
    if (Directionality.of(context) == TextDirection.rtl) direction *= -1;
    _previous = _reduced ? null : oldWidget.index;
    _outgoing = Tween<double>(begin: oldOpacity, end: 0).animate(_exitProgress);
    _enterOffset = Tween<Offset>(
      begin: Offset(12 * direction, 0),
      end: Offset.zero,
    ).animate(_incoming);
    _exitOffset = Tween<Offset>(
      begin: oldOffset,
      end: Offset(-8 * direction, 0),
    ).animate(_exitProgress);
    _acceptInput = _reduced;
    if (_reduced) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var i = 0; i < widget.children.length; i++)
        Offstage(
          offstage: i != widget.index && i != _previous,
          child: TickerMode(
            enabled: i == widget.index,
            child: ExcludeFocus(
              excluding: i != widget.index,
              child: ExcludeSemantics(
                excluding: i != widget.index,
                child: IgnorePointer(
                  ignoring: i != widget.index || !_acceptInput,
                  child: FadeTransition(
                    alwaysIncludeSemantics: i == widget.index,
                    opacity: i == widget.index
                        ? _incoming
                        : i == _previous
                        ? _outgoing
                        : _hidden,
                    child: AnimatedBuilder(
                      animation: i == widget.index
                          ? _enterOffset
                          : i == _previous
                          ? _exitOffset
                          : _still,
                      child: RepaintBoundary(child: widget.children[i]),
                      builder: (context, child) => Transform.translate(
                        offset: i == widget.index
                            ? _enterOffset.value
                            : i == _previous
                            ? _exitOffset.value
                            : Offset.zero,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
