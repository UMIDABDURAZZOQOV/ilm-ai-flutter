import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'ilm_navigation_icons.dart';
import 'motion.dart';

class IlmNavigationDestination {
  const IlmNavigationDestination({
    required this.icon,
    required this.label,
    this.motionIcon,
  });
  final IconData icon;
  final String label;
  final IlmNavIcon? motionIcon;
}

/// A persistent selection plate moves between destinations, while each vector
/// icon performs one short, interruptible gesture. No looping animation.
class IlmBottomNavigation extends StatelessWidget {
  const IlmBottomNavigation({
    super.key,
    required this.index,
    required this.items,
    required this.onChanged,
  });
  final int index;
  final List<IlmNavigationDestination> items;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return Material(
      color: c.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / items.length;
                final plateWidth = math.min(52.0, slot - 4);
                return Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      key: const ValueKey('ilm-nav-selection'),
                      duration: motionDuration(context, 280),
                      curve: Curves.easeInOutCubic,
                      start: slot * index + (slot - plateWidth) / 2,
                      top: 6,
                      width: plateWidth,
                      height: 40,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: AnimatedContainer(
                            duration: motionDuration(context, 180),
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: c.primary.withValues(alpha: .12),
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Transform.translate(
                                offset: const Offset(0, 3),
                                child: Transform.rotate(
                                  angle: math.pi / 4,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: BrandPalette.turquoise,
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _NavigationTile(
                              key: ValueKey('ilm-nav-$i'),
                              item: items[i],
                              selected: i == index,
                              onSelect: () => onChanged(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationTile extends StatefulWidget {
  const _NavigationTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onSelect,
  });
  final IlmNavigationDestination item;
  final bool selected;
  final VoidCallback onSelect;
  @override
  State<_NavigationTile> createState() => _NavigationTileState();
}

class _NavigationTileState extends State<_NavigationTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _selection;
  bool _pressed = false, _reduced = false;

  @override
  void initState() {
    super.initState();
    _selection = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 180),
      value: widget.selected ? 1 : 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) _selection.value = widget.selected ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant _NavigationTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    if (_reduced) {
      _selection.value = widget.selected ? 1 : 0;
    } else if (widget.selected) {
      _selection.forward(from: 0);
    } else {
      _selection.reverse();
    }
  }

  void _select() {
    if (widget.selected) return;
    HapticFeedback.selectionClick();
    widget.onSelect(); // Callback is immediate; motion never gates navigation.
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return Semantics(
      button: true,
      selected: widget.selected,
      inMutuallyExclusiveGroup: true,
      label: widget.item.label,
      excludeSemantics: true,
      onTap: _select,
      child: InkWell(
        onTap: _select,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        borderRadius: BorderRadius.circular(16),
        splashColor: c.primary.withValues(alpha: .10),
        highlightColor: Colors.transparent,
        focusColor: c.primary.withValues(alpha: .12),
        onHighlightChanged: (pressed) {
          if (_pressed != pressed) setState(() => _pressed = pressed);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  child: Center(
                    child: AnimatedScale(
                      scale: _reduced
                          ? 1
                          : _pressed
                          ? .94
                          : 1,
                      duration: motionDuration(context, 100),
                      curve: Curves.easeOutCubic,
                      child: AnimatedBuilder(
                        animation: _selection,
                        builder: (context, _) {
                          final progress = Curves.easeOutCubic.transform(
                            _selection.value,
                          );
                          final pulse =
                              widget.selected &&
                                  _selection.isAnimating &&
                                  !_reduced
                              ? math.sin(_selection.value * math.pi)
                              : 0.0;
                          final color = Color.lerp(
                            c.textMuted,
                            c.primary,
                            progress,
                          )!;
                          return Transform.translate(
                            offset: Offset(0, -2 * progress - 2 * pulse),
                            child: Transform.scale(
                              scale: 1 + .08 * pulse,
                              child: widget.item.motionIcon == null
                                  ? Icon(
                                      widget.item.icon,
                                      size: 28,
                                      color: color,
                                    )
                                  : IlmNavigationIcon(
                                      icon: widget.item.motionIcon!,
                                      progress: progress,
                                      color: color,
                                      accent:
                                          widget.item.motionIcon ==
                                              IlmNavIcon.league
                                          ? BrandPalette.accentOrange
                                          : BrandPalette.turquoise,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: motionDuration(context, 180),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.selected ? c.primary : c.textMuted,
                  ),
                  child: Text(
                    widget.item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
