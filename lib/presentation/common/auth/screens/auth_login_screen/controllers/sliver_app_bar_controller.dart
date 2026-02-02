import 'package:flutter/material.dart';
import 'package:stream_value/main.dart';

class SliverAppBarController {
  SliverAppBarController() {
    // scrollController.addListener(scrollListener);
  }

  final scrollController = ScrollController();

  final double expandedBarHeight = 260.0;
  final double collapsedBarHeight = 56.0;

  final StreamValue<bool> isCollapsed = StreamValue<bool>(defaultValue: false);

  final StreamValue<bool> isExpanded = StreamValue<bool>(defaultValue: true);

  final StreamValue<bool> keyboardIsOpened = StreamValue<bool>(
    defaultValue: false,
  );

  void shrink() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      expandedBarHeight,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void expand() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void scheduleShrink() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      shrink();
    });
  }

  void scheduleExpand() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      expand();
    });
  }

  void dispose() {
    scrollController.dispose();
    isCollapsed.dispose();
    isExpanded.dispose();
    keyboardIsOpened.dispose();
  }

  // bool scrollListener() {

  //   final checkCollapseState = scrollController.hasClients && scrollController.offset > (expandedBarHeight - collapsedBarHeight);

  //   isCollapsed.addValue(checkCollapseState);

  //   return false;
  // }
}
