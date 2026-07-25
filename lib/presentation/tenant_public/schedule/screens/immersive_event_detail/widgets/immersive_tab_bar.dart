import 'package:belluga_now/presentation/shared/widgets/auto_reveal_horizontal_item.dart';
import 'package:flutter/material.dart';

class ImmersiveTabBar extends StatefulWidget {
  const ImmersiveTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabTapped,
    super.key,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;

  @override
  State<ImmersiveTabBar> createState() => _ImmersiveTabBarState();
}

class _ImmersiveTabBarState extends State<ImmersiveTabBar> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollAffordances);
    _scheduleAffordanceRefresh();
  }

  @override
  void didUpdateWidget(covariant ImmersiveTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length ||
        oldWidget.selectedIndex != widget.selectedIndex) {
      _scheduleAffordanceRefresh();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateScrollAffordances)
      ..dispose();
    super.dispose();
  }

  void _scheduleAffordanceRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _updateScrollAffordances();
    });
  }

  void _updateScrollAffordances() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final canScrollLeft = position.pixels > 0.5;
    final canScrollRight = position.maxScrollExtent - position.pixels > 0.5;

    if (canScrollLeft == _canScrollLeft && canScrollRight == _canScrollRight) {
      return;
    }

    setState(() {
      _canScrollLeft = canScrollLeft;
      _canScrollRight = canScrollRight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.64);
    final textStyle = theme.textTheme.labelLarge;

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(widget.tabs.length, (index) {
              final isSelected = index == widget.selectedIndex;
              return AutoRevealHorizontalItem(
                selected: isSelected,
                child: Semantics(
                  container: true,
                  label: widget.tabs[index],
                  button: true,
                  selected: isSelected,
                  onTap: () => widget.onTabTapped(index),
                  child: InkWell(
                    key: Key('immersiveTab_$index'),
                    excludeFromSemantics: true,
                    onTap: () => widget.onTabTapped(index),
                    child: ExcludeSemantics(
                      child: Container(
                        key: Key(
                          isSelected
                              ? 'immersiveTabSelected_$index'
                              : 'immersiveTabUnselected_$index',
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          key: Key('immersiveTabLabel_$index'),
                          widget.tabs[index],
                          style: TextStyle(
                            color: isSelected ? selectedColor : unselectedColor,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ).merge(textStyle),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (_canScrollLeft)
          _OverflowHint(
            alignment: Alignment.centerLeft,
            icon: Icons.chevron_left,
            backgroundColor: colorScheme.surface,
          ),
        if (_canScrollRight)
          _OverflowHint(
            alignment: Alignment.centerRight,
            icon: Icons.chevron_right,
            backgroundColor: colorScheme.surface,
          ),
      ],
    );
  }
}

class _OverflowHint extends StatelessWidget {
  const _OverflowHint({
    required this.alignment,
    required this.icon,
    required this.backgroundColor,
  });

  final Alignment alignment;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final revealFromLeft = alignment == Alignment.centerLeft;
    final hintKey = Key(
      revealFromLeft
          ? 'immersiveTabOverflowHintLeft'
          : 'immersiveTabOverflowHintRight',
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: alignment,
              child: Container(
                key: hintKey,
                width: 28,
                height: constraints.maxHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: revealFromLeft
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    end: revealFromLeft
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    colors: [
                      backgroundColor,
                      backgroundColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
