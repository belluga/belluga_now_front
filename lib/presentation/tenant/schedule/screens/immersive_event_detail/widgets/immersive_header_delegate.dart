import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/immersive_tab_bar.dart';
import 'package:flutter/material.dart';

class ImmersiveHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isConfirmed;
  final int currentTabIndex;
  final ValueChanged<int> onTabTapped;

  ImmersiveHeaderDelegate({
    required this.isConfirmed,
    required this.currentTabIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final tabs = [
      if (isConfirmed) 'Sua Galera',
      'O Rolê',
      'Line-up',
      'O Local',
    ];

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
    return oldDelegate.isConfirmed != isConfirmed ||
        oldDelegate.currentTabIndex != currentTabIndex;
  }
}
