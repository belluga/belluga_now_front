import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';

class ImmersiveDetailScreenController {
  ImmersiveDetailScreenController({
    required this.tabItems,
    int initialTabIndex = 0,
  })  : scrollController = ScrollController(),
        currentTabIndexStreamValue =
            StreamValue<int>(defaultValue: initialTabIndex);

  late final ScrollController scrollController;
  final List<ImmersiveTabItem> tabItems;

  late final StreamValue<int> currentTabIndexStreamValue;

  final GlobalKey columnKey = GlobalKey();
  final GlobalKey<NestedScrollViewState> nestedScrollViewKey =
      GlobalKey<NestedScrollViewState>();

  double _topPadding = 0;

  void setTopPadding(double topPadding) => _topPadding = topPadding;

  void onTabTapped(int index) {
    currentTabIndexStreamValue.addValue(index);

    final nestedState = nestedScrollViewKey.currentState;
    if (nestedState == null) return;

    // For the first tab, try scrolling to negative offset to compensate for any padding
    if (index == 0) {
      // Test different offsets to find the right one
      const testOffset = -48.0; // Try negative tab bar height
      print("Tab 0 - Scrolling to: $testOffset");
      
      nestedState.innerController.animateTo(
        testOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // For other tabs, use simple sum of heights
    double targetScroll = 0;
    for (int i = 0; i < index; i++) {
      final tabContext = tabItems[i].key.currentContext;
      if (tabContext != null) {
        final renderBox = tabContext.findRenderObject() as RenderBox?;
        targetScroll += renderBox?.size.height ?? 0;
      }
    }

    // The inner controller's scroll 0 is AFTER the pinned header
    // So we need to subtract the pinned header height
    const tabBarHeight = 48.0;
    final pinnedHeaderHeight = _topPadding + kToolbarHeight + tabBarHeight;
    final adjustedTarget = targetScroll - pinnedHeaderHeight;

    print(
        "Tab $index - Raw target: $targetScroll, Pinned header: $pinnedHeaderHeight, Adjusted: $adjustedTarget");

    nestedState.innerController.animateTo(
      adjustedTarget,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void dispose() {
    scrollController.dispose();
    currentTabIndexStreamValue.dispose();
  }
}
