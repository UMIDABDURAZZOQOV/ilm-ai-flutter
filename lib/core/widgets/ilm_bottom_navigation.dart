import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/integrated_beta.dart';
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
                // Keep whole destination names at the user's chosen text size.
                // When five columns are too narrow, all destinations wrap into
                // additional rows instead of splitting or shrinking words.
                final labelStyle = Theme.of(context).textTheme.labelSmall!
                    .copyWith(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    );
                var minSlot = 56.0;
                var labelHeight = 0.0;
                for (final item in items) {
                  final painter = TextPainter(
                    text: TextSpan(text: item.label, style: labelStyle),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: 1,
                  )..layout();
                  minSlot = math.max(minSlot, painter.width + 8);
                  labelHeight = math.max(labelHeight, painter.height);
                  painter.dispose();
                }
                var columns = (constraints.maxWidth / minSlot).floor().clamp(
                  1,
                  items.length,
                );
                final wrapped = columns < items.length;
                if (wrapped) {
                  // Horizontal icon/label rows need less height, leaving the
                  // lesson page usable even with a wide accessibility font.
                  columns = (constraints.maxWidth / (minSlot + 36))
                      .floor()
                      .clamp(1, items.length);
                }
                final slot = constraints.maxWidth / columns;
                final tileHeight = math.max(48.0, labelHeight + 8);
                final plateWidth = wrapped
                    ? slot - 8
                    : math.min(52.0, slot - 4);
                return Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      key: const ValueKey('ilm-nav-selection'),
                      duration: motionDuration(context, 280),
                      curve: Curves.easeInOutCubic,
                      start: slot * (index % columns) + (slot - plateWidth) / 2,
                      top: wrapped ? (index ~/ columns) * tileHeight + 4 : 6,
                      width: plateWidth,
                      height: wrapped ? tileHeight - 8 : 40,
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
                    Wrap(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          SizedBox(
                            width: slot,
                            height: wrapped ? tileHeight : null,
                            child: _NavigationTile(
                              key: ValueKey('ilm-nav-$i'),
                              item: items[i],
                              selected: i == index,
                              singleLine: wrapped,
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
    this.singleLine = false,
    required this.onSelect,
  });
  final IlmNavigationDestination item;
  final bool selected;
  final bool singleLine;
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

  Widget _isolatePaint(Widget child) =>
      reviewedLearning ? RepaintBoundary(child: child) : child;

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final content = <Widget>[
      SizedBox(
        height: widget.singleLine ? 32 : 40,
        child: Center(
          child: _isolatePaint(
            AnimatedScale(
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
                      widget.selected && _selection.isAnimating && !_reduced
                      ? math.sin(_selection.value * math.pi)
                      : 0.0;
                  final color = Color.lerp(c.textMuted, c.primary, progress)!;
                  return Transform.translate(
                    offset: Offset(0, -2 * progress - 2 * pulse),
                    child: Transform.scale(
                      scale: 1 + .08 * pulse,
                      child: widget.item.motionIcon == null
                          ? Icon(widget.item.icon, size: 28, color: color)
                          : IlmNavigationIcon(
                              icon: widget.item.motionIcon!,
                              progress: progress,
                              color: color,
                              accent:
                                  widget.item.motionIcon == IlmNavIcon.league
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
      ),
      const SizedBox(height: 4),
      AnimatedDefaultTextStyle(
        duration: motionDuration(context, 180),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          fontSize: 11,
          height: 1.2,
          fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
          color: widget.selected ? c.primary : c.textMuted,
        ),
        child: Text(
          widget.item.label,
          maxLines: widget.singleLine ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    ];
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
          constraints: BoxConstraints(minHeight: widget.singleLine ? 48 : 72),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.singleLine ? 4 : 2,
              vertical: widget.singleLine ? 4 : 6,
            ),
            child: widget.singleLine
                ? Row(
                    children: [
                      SizedBox(width: 32, child: content.first),
                      const SizedBox(width: 4),
                      Expanded(child: content.last),
                    ],
                  )
                : Column(mainAxisSize: MainAxisSize.min, children: content),
          ),
        ),
      ),
    );
  }
}
