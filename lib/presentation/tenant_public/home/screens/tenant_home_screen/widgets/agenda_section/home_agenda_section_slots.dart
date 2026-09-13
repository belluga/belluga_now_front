import 'package:flutter/widgets.dart';

typedef HomeAgendaScrollViewBuilder =
    Widget Function({
      required List<Widget> headerSlivers,
      required ScrollController scrollController,
    });

class HomeAgendaSectionSlots {
  HomeAgendaSectionSlots({
    required this.headerSlivers,
    required this.scrollViewBuilder,
  });

  final List<Widget> headerSlivers;
  final HomeAgendaScrollViewBuilder scrollViewBuilder;
}
