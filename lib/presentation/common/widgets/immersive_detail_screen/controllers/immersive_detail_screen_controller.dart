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
  double _topPadding = 0;
  final List<ImmersiveTabItem> tabItems;

  late final StreamValue<int> currentTabIndexStreamValue;

  void setTopPadding(double topPadding) => _topPadding = topPadding;

  double _calculateTabOffset(int index) {
    double offset = 0;
    for (int i = 0; i < index; i++) {
      final tabContext = tabItems[i].key.currentContext;
      offset += tabContext?.size?.height ?? 0;
    }
    return offset + _topPadding;
  }
    

  void onTabTapped(int index) {

    currentTabIndexStreamValue.addValue(index);

    // final pinnedHeaderHeight = _topPadding + kToolbarHeight + 48.0;

    // print("pinnedHeaderHeight: $pinnedHeaderHeight");

    final _currentContentOffset = _calculateTabOffset(index);
    print("_currentContentOffset: $_currentContentOffset");

    final targetScroll = _currentContentOffset;
    print("targetScroll: $targetScroll");

    scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // if (tabContext != null) {
    //   final tabBox = tabContext.findRenderObject() as RenderBox;

    //   // Get tab position relative to the column
    //   final tabOffset = tabBox.localToGlobal(Offset.zero, ancestor: columnBox);
    //   final tabRelativeY = tabOffset.dy;

    //   // 3. Calculate absolute target scroll offset
    //   // Based on testing, the correct target is simply the relative Y position
    //   // minus the pinned header height. This brings the tab to exactly below the header.
    //   final targetScroll = tabRelativeY - pinnedHeaderHeight;

    //   // Ensure we don't scroll to negative offset
    //   final clampedTarget = targetScroll < 0 ? 0.0 : targetScroll;

    //   _scrollController
    //       .animateTo(
    //     clampedTarget,
    //     duration: const Duration(milliseconds: 300),
    //     curve: Curves.easeInOut,
    //   )
    //       .then((_) {
    //     if (mounted) {
    //       setState(() {
    //         _isManualScrolling = false;
    //       });
    //     }
    //   });
    // }
  }

  void dispose() {
    scrollController.dispose();
    currentTabIndexStreamValue.dispose();
  }
}
