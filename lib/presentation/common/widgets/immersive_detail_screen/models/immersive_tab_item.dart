import 'package:flutter/material.dart';

/// Configuration for a tab in an immersive detail screen.
///
/// Each tab consists of a title, content widget, and optional footer.
/// This model enables dynamic tab configuration for reusable immersive screens.
class ImmersiveTabItem {
  ImmersiveTabItem({
    required this.title,
    required this.content,
    this.footer,
  });

  /// The title displayed in the tab bar
  final String title;

  /// The content widget displayed when this tab is active
  final Widget content;

  /// Optional footer widget specific to this tab
  /// If null, the screen's default footer will be used
  final Widget? footer;

  final key = GlobalKey();
}
