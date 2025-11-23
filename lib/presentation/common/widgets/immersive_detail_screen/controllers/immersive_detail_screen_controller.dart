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
  List<ImmersiveTabItem> tabItems;

  late final StreamValue<int> currentTabIndexStreamValue;

  final GlobalKey<NestedScrollViewState> nestedScrollViewKey =
      GlobalKey<NestedScrollViewState>();

  double _topPadding = 0;
  bool _isProgrammaticScroll = false;

  // Track visibility of each tab
  final Map<int, double> _tabVisibility = {};

  void setTopPadding(double topPadding) => _topPadding = topPadding;

  void updateTabs(List<ImmersiveTabItem> updatedTabs) {
    tabItems = updatedTabs;
    _tabVisibility.removeWhere((index, _) => index >= tabItems.length);

    if (tabItems.isEmpty) {
      currentTabIndexStreamValue.addValue(0);
      return;
    }

    if (currentTabIndexStreamValue.value >= tabItems.length) {
      currentTabIndexStreamValue.addValue(tabItems.length - 1);
    }
  }

  void onTabVisibilityChanged(int index, double visibleFraction) {
    if (index >= tabItems.length) return;

    // Don't auto-switch during programmatic scrolling
    if (_isProgrammaticScroll) return;

    _tabVisibility[index] = visibleFraction;

    // Find the tab with highest visibility that's >25%
    int? mostVisibleTab;
    double highestVisibility = 0.25; // Minimum threshold

    _tabVisibility.forEach((tabIndex, visibility) {
      if (visibility > highestVisibility) {
        highestVisibility = visibility;
        mostVisibleTab = tabIndex;
      }
    });

    // Switch to the most visible tab if it's different from current
    if (mostVisibleTab != null &&
        mostVisibleTab != currentTabIndexStreamValue.value) {
      currentTabIndexStreamValue.addValue(mostVisibleTab!);
    }
  }

  void onTabTapped(int index) {
    if (index >= tabItems.length) return;

    currentTabIndexStreamValue.addValue(index);

    final nestedState = nestedScrollViewKey.currentState;
    if (nestedState == null) return;

    // Set flag to prevent auto tab switching during programmatic scroll
    _isProgrammaticScroll = true;

    // For the first tab, try scrolling to negative offset to compensate for any padding
    if (index == 0) {
      // Test different offsets to find the right one
      const testOffset = -48.0; // Try negative tab bar height

      nestedState.innerController
          .animateTo(
        testOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        _isProgrammaticScroll = false;
      });
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

    nestedState.innerController
        .animateTo(
      adjustedTarget,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
      _isProgrammaticScroll = false;
    });
  }

  void dispose() {
    scrollController.dispose();
    currentTabIndexStreamValue.dispose();
  }
}
