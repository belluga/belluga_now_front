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
    scrollController.animateTo(
      expandedBarHeight,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void expand() {
    scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // bool scrollListener() {

  //   final checkCollapseState = scrollController.hasClients && scrollController.offset > (expandedBarHeight - collapsedBarHeight);

  //   isCollapsed.addValue(checkCollapseState);

  //   return false;
  // }
}
