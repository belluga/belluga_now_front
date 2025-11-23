import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/immersive_tab_bar.dart';
import 'package:flutter/material.dart';

class ImmersiveHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final int currentTabIndex;
  final ValueChanged<int> onTabTapped;

  ImmersiveHeaderDelegate({
    required this.tabs,
    required this.currentTabIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      color: Colors.white,
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
    );
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant ImmersiveHeaderDelegate oldDelegate) {
    return oldDelegate.currentTabIndex != currentTabIndex ||
        oldDelegate.tabs.length != tabs.length;
  }
}
