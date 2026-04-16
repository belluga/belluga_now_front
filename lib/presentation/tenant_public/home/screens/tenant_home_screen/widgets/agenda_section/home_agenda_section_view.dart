import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_app_bar.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_body.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section_slots.dart';
import 'package:flutter/material.dart';

class HomeAgendaSectionView extends StatefulWidget {
  const HomeAgendaSectionView({
    super.key,
    required this.controller,
    required this.builder,
    this.scrollController,
  });

  final TenantHomeAgendaController controller;
  final Widget Function(BuildContext context, HomeAgendaSectionSlots slots)
      builder;
  final ScrollController? scrollController;

  @override
  State<HomeAgendaSectionView> createState() => _HomeAgendaSectionViewState();
}

class _HomeAgendaSectionViewState extends State<HomeAgendaSectionView> {
  static const int _coordinatedScrollSyncWarmupFrames = 8;

  ScrollController? _attachedScrollController;

  @override
  void initState() {
    super.initState();
    _attachScrollController(widget.scrollController);
  }

  @override
  void didUpdateWidget(covariant HomeAgendaSectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _detachScrollController(oldWidget.scrollController);
      _attachScrollController(widget.scrollController);
    }
  }

  @override
  void dispose() {
    _detachScrollController(_attachedScrollController);
    super.dispose();
  }

  void _attachScrollController(ScrollController? controller) {
    _attachedScrollController = controller;
    controller?.addListener(_handleCoordinatedScrollChanged);
    _syncCoordinatedScrollState();
    _scheduleCoordinatedScrollStateSync(
      controller,
      remainingFrames: _coordinatedScrollSyncWarmupFrames,
    );
  }

  void _detachScrollController(ScrollController? controller) {
    controller?.removeListener(_handleCoordinatedScrollChanged);
    if (identical(_attachedScrollController, controller)) {
      _attachedScrollController = null;
    }
  }

  void _handleCoordinatedScrollChanged() {
    _syncCoordinatedScrollState();
  }

  void _scheduleCoordinatedScrollStateSync(
    ScrollController? controller, {
    required int remainingFrames,
  }) {
    if (controller == null || remainingFrames <= 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_attachedScrollController, controller)) {
        return;
      }
      _syncCoordinatedScrollState();
      // External controllers can attach or restore offset a few frames after
      // the widget subscribes, without emitting a scroll delta.
      if (!controller.hasClients || controller.offset == 0.0) {
        WidgetsBinding.instance.scheduleFrame();
        _scheduleCoordinatedScrollStateSync(
          controller,
          remainingFrames: remainingFrames - 1,
        );
      }
    });
  }

  void _syncCoordinatedScrollState() {
    final controller = _attachedScrollController;
    final pixels =
        controller != null && controller.hasClients ? controller.offset : 0.0;
    widget.controller.updateRadiusActionCompactStateFromOuterScroll(pixels);
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
            child: HomeAgendaAppBar(controller: widget.controller),
          ),
        ),
        body: HomeAgendaBody(controller: widget.controller),
      ),
    );
  }
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
