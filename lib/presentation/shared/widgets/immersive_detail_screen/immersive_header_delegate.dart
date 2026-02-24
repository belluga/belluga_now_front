import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/immersive_tab_bar.dart';
import 'package:flutter/material.dart';

class ImmersiveHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final int currentTabIndex;
  final ValueChanged<int> onTabTapped;
  final ColorScheme? colorScheme;
  final double topPadding;

  ImmersiveHeaderDelegate({
    required this.tabs,
    required this.currentTabIndex,
    required this.onTabTapped,
    this.colorScheme,
    this.topPadding = 0,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final effectiveColorScheme = colorScheme ?? theme.colorScheme;

    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      color: effectiveColorScheme.surface,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Tabs
            ImmersiveTabBar(
              tabs: tabs,
              selectedIndex: currentTabIndex,
              onTabTapped: onTabTapped,
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 48.0 + topPadding;

  @override
  double get minExtent => 48.0 + topPadding;

  @override
  bool shouldRebuild(covariant ImmersiveHeaderDelegate oldDelegate) {
    return oldDelegate.currentTabIndex != currentTabIndex ||
        oldDelegate.tabs.length != tabs.length ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.topPadding != topPadding;
  }
}
