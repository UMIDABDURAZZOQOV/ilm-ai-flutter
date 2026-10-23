import 'package:flutter/material.dart';

/// A short directional fade-through. Each tab retains the same element/state;
/// only the selected tab can receive input, focus or accessibility actions.
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
  int? _previous;
  double _direction = 1, _outgoingOpacity = 1;
  bool _reduced = false;
  static const _incoming = Interval(.18, 1, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
          value: 1,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && _previous != null) {
            setState(() => _previous = null);
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _previous = null;
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant IlmTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _outgoingOpacity = _controller.isAnimating
        ? _incoming.transform(_controller.value)
        : 1;
    _previous = _reduced ? null : oldWidget.index;
    _direction = widget.index > oldWidget.index ? 1 : -1;
    if (Directionality.of(context) == TextDirection.rtl) _direction *= -1;
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final incoming = _incoming.transform(_controller.value);
      final outgoing =
          1 -
          const Interval(
            0,
            .30,
            curve: Curves.easeOutCubic,
          ).transform(_controller.value);
      return Stack(
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
                      ignoring: i != widget.index || incoming < .5,
                      child: Opacity(
                        alwaysIncludeSemantics: i == widget.index,
                        opacity: i == widget.index
                            ? incoming
                            : outgoing * _outgoingOpacity,
                        child: Transform.translate(
                          offset: Offset(
                            i == widget.index
                                ? 12 * _direction * (1 - incoming)
                                : -8 * _direction * (1 - outgoing),
                            0,
                          ),
                          child: RepaintBoundary(child: widget.children[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
