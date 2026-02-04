import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_app_bar.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_body.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class HomeAgendaSection extends StatefulWidget {
  const HomeAgendaSection({
    super.key,
    required this.builder,
    this.controller,
  });

  final Widget Function(BuildContext context, HomeAgendaSectionSlots slots)
      builder;
  final TenantHomeAgendaController? controller;

  @override
  State<HomeAgendaSection> createState() => _HomeAgendaSectionState();
}

class _HomeAgendaSectionState extends State<HomeAgendaSection> {
  late final TenantHomeAgendaController _controller =
      widget.controller ?? GetIt.I.get<TenantHomeAgendaController>();

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    await _controller.init(startWithHistory: false);
    _controller.setInviteFilter(InviteFilter.none);
    _controller.setSearchActive(false);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      HomeAgendaSectionSlots(
        header: SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedHeaderDelegate(
            minHeight: kToolbarHeight,
            maxHeight: kToolbarHeight,
            child: HomeAgendaAppBar(controller: _controller),
          ),
        ),
        body: HomeAgendaBody(controller: _controller),
      ),
    );
  }
}

class HomeAgendaSectionSlots {
  HomeAgendaSectionSlots({
    required this.header,
    required this.body,
  });

  final Widget header;
  final Widget body;
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
