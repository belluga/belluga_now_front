import 'package:flutter/material.dart';

enum ImmersiveHorizontalSwipeDirection { backward, forward }

typedef ImmersiveTabHorizontalSwipeHandler =
    bool Function({
      required ImmersiveHorizontalSwipeDirection direction,
      required ValueChanged<int> activateTab,
      required int currentTabIndex,
    });

typedef ImmersiveTabSliversBuilder =
    List<Widget> Function(BuildContext context);

/// Configuration for a tab in an immersive detail screen.
///
/// Each tab consists of a title, content widget, and optional footer.
/// This model enables dynamic tab configuration for reusable immersive screens.
class ImmersiveTabItem {
  ImmersiveTabItem({
    required this.title,
    this.content,
    this.sliversBuilder,
    this.footer,
    this.onActivated,
    this.onHorizontalSwipeEnd,
  }) : assert(
         (content == null) != (sliversBuilder == null),
         'Provide exactly one of content or sliversBuilder.',
       );

  /// The title displayed in the tab bar
  final String title;

  /// The content widget displayed when this tab is active
  final Widget? content;

  /// Optional sliver representation for tabs that already own sliver content.
  /// Box-only tabs are wrapped by the immersive screen.
  final ImmersiveTabSliversBuilder? sliversBuilder;

  /// Optional footer widget specific to this tab
  /// If null, the screen's default footer will be used
  final Widget? footer;

  /// Optional activation hook invoked whenever this tab becomes active.
  final VoidCallback? onActivated;

  /// Optional swipe handler for the active tab. When it returns true, the
  /// screen-level default tab swipe behavior is skipped.
  final ImmersiveTabHorizontalSwipeHandler? onHorizontalSwipeEnd;

  final key = GlobalKey();
}
