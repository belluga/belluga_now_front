import 'package:flutter/material.dart';

enum ImmersiveHorizontalSwipeDirection { backward, forward }

typedef ImmersiveTabHorizontalSwipeHandler = bool Function({
  required ImmersiveHorizontalSwipeDirection direction,
  required ValueChanged<int> activateTab,
  required int currentTabIndex,
});

/// Configuration for a tab in an immersive detail screen.
///
/// Each tab consists of a title, content widget, and optional footer.
/// This model enables dynamic tab configuration for reusable immersive screens.
class ImmersiveTabItem {
  ImmersiveTabItem({
    required this.title,
    required this.content,
    this.footer,
    this.onHorizontalSwipeEnd,
  });

  /// The title displayed in the tab bar
  final String title;

  /// The content widget displayed when this tab is active
  final Widget content;

  /// Optional footer widget specific to this tab
  /// If null, the screen's default footer will be used
  final Widget? footer;

  /// Optional swipe handler for the active tab. When it returns true, the
  /// screen-level default tab swipe behavior is skipped.
  final ImmersiveTabHorizontalSwipeHandler? onHorizontalSwipeEnd;

  final key = GlobalKey();
}
