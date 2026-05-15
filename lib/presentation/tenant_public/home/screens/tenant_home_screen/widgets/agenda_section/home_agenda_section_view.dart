import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_app_bar.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_body.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section_slots.dart';
import 'package:belluga_now/presentation/shared/widgets/discovery_filter_visual_icon.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

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
      if (_coordinatedScrollPixels(controller) == 0.0) {
        WidgetsBinding.instance.scheduleFrame();
        _scheduleCoordinatedScrollStateSync(
          controller,
          remainingFrames: remainingFrames - 1,
        );
      }
    });
  }

  void _syncCoordinatedScrollState() {
    final pixels = _coordinatedScrollPixels(_attachedScrollController);
    widget.controller.updateRadiusActionCompactStateFromOuterScroll(pixels);
  }

  double _coordinatedScrollPixels(ScrollController? controller) {
    if (controller == null || !controller.hasClients) {
      return 0.0;
    }

    if (controller.positions.isEmpty) {
      return controller.offset;
    }

    var resolvedPixels = 0.0;
    for (final position in controller.positions) {
      if (position.pixels > resolvedPixels) {
        resolvedPixels = position.pixels;
      }
    }
    return resolvedPixels;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<DiscoveryFilterCatalog>(
      streamValue: widget.controller.discoveryFilterCatalogStreamValue,
      builder: (context, catalog) {
        return StreamValueBuilder<DiscoveryFilterSelection>(
          streamValue: widget.controller.discoveryFilterSelectionStreamValue,
          builder: (context, selection) {
            return StreamValueBuilder<bool>(
              streamValue:
                  widget.controller.isDiscoveryFilterPanelVisibleStreamValue,
              builder: (context, isPanelVisible) {
                final showFilterPanel =
                    isPanelVisible && catalog.filters.isNotEmpty;

                return widget.builder(
                  context,
                  HomeAgendaSectionSlots(
                    headerSlivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedHeaderDelegate(
                          minHeight: kToolbarHeight,
                          maxHeight: kToolbarHeight,
                          child: SizedBox(
                            height: kToolbarHeight,
                            child: HomeAgendaAppBar(
                              controller: widget.controller,
                              onFilterPressed: () =>
                                  _handleFilterPressed(isPanelVisible),
                            ),
                          ),
                        ),
                      ),
                      if (showFilterPanel)
                        SliverToBoxAdapter(
                          child: _HomeAgendaFilterPanelReveal(
                            onRevealFinished: widget
                                .controller.completeDiscoveryFilterPanelReveal,
                            child: _HomeAgendaFilterPanel(
                              controller: widget.controller,
                              catalog: catalog,
                              selection: selection,
                            ),
                          ),
                        ),
                    ],
                    body: HomeAgendaBody(controller: widget.controller),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleFilterPressed(bool isPanelVisible) {
    if (isPanelVisible) {
      widget.controller.closeDiscoveryFilterPanel();
      return;
    }
    widget.controller.openDiscoveryFilterPanelForReveal();
  }
}

class _HomeAgendaFilterPanelReveal extends StatefulWidget {
  const _HomeAgendaFilterPanelReveal({
    required this.child,
    required this.onRevealFinished,
  });

  final Widget child;
  final VoidCallback onRevealFinished;

  @override
  State<_HomeAgendaFilterPanelReveal> createState() =>
      _HomeAgendaFilterPanelRevealState();
}

class _HomeAgendaFilterPanelRevealState
    extends State<_HomeAgendaFilterPanelReveal> {
  final GlobalKey _panelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final panelContext = _panelKey.currentContext;
      if (panelContext == null) {
        widget.onRevealFinished();
        return;
      }
      Scrollable.ensureVisible(
        panelContext,
        alignment: 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ).whenComplete(widget.onRevealFinished);
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _panelKey,
      child: widget.child,
    );
  }
}

class _HomeAgendaFilterPanel extends StatelessWidget {
  const _HomeAgendaFilterPanel({
    required this.controller,
    required this.catalog,
    required this.selection,
  });

  final TenantHomeAgendaController controller;
  final DiscoveryFilterCatalog catalog;
  final DiscoveryFilterSelection selection;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: controller.isInitialLoadingStreamValue,
      builder: (context, isInitialLoading) {
        return StreamValueBuilder<bool>(
          streamValue: controller.isPageLoadingStreamValue,
          builder: (context, isPageLoading) {
            return Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Semantics(
                container: true,
                label: 'Painel de filtros de eventos',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: DiscoveryFilterBar(
                    catalog: catalog,
                    selection: selection,
                    policy: controller.discoveryFilterPolicy,
                    isLoading: isInitialLoading || isPageLoading,
                    iconBuilder: buildDiscoveryFilterVisualIcon,
                    onSelectionChanged: controller.setDiscoveryFilterSelection,
                  ),
                ),
              ),
            );
          },
        );
      },
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
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
