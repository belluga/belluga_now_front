import 'dart:async';

import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_app_bar.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_body.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section_slots.dart';
import 'package:belluga_now/presentation/shared/widgets/discovery_filter_visual_icon.dart';
import 'package:belluga_now/presentation/shared/widgets/size_reporting_widget.dart';
import 'package:flutter/foundation.dart' show setEquals;
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
  final GlobalKey _taxonomyPanelRevealKey = GlobalKey();
  static const int _coordinatedScrollSyncWarmupFrames = 8;
  static const double _defaultFilterPanelExtent = 60;

  ScrollController? _attachedScrollController;
  double _filterPanelExtent = _defaultFilterPanelExtent;

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

    // Some delayed-attach/test-double controllers can report `hasClients`
    // before exposing concrete positions. Fall back safely in that edge case.
    if (controller.positions.isEmpty) {
      try {
        return controller.offset;
      } on StateError catch (_) {
        return 0.0;
      }
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
        return StreamValueBuilder<bool>(
          streamValue:
              widget.controller.hasCanonicalDiscoveryFilterCatalogStreamValue,
          builder: (context, hasCanonicalCatalog) {
            return StreamValueBuilder<DiscoveryFilterSelection>(
              streamValue:
                  widget.controller.discoveryFilterSelectionStreamValue,
              builder: (context, selection) {
                final showFilterPanel =
                    hasCanonicalCatalog && catalog.filters.isNotEmpty;
                final hasTaxonomyGroups =
                    showFilterPanel &&
                    hasDiscoveryFilterTaxonomyGroups(
                      catalog: catalog,
                      selection: selection,
                      policy: widget.controller.discoveryFilterPolicy,
                    );

                return StreamValueBuilder<bool>(
                  streamValue: widget
                      .controller
                      .isDiscoveryFilterPanelVisibleStreamValue,
                  builder: (context, isTaxonomyPanelVisible) => widget.builder(
                    context,
                    HomeAgendaSectionSlots(
                      headerSlivers: [
                        if (showFilterPanel)
                          SliverToBoxAdapter(
                            child: Offstage(
                              offstage: true,
                              child: SizeReportingWidget(
                                onSizeChanged: _updateFilterPanelExtent,
                                child: _HomeAgendaFilterPanel(
                                  controller: widget.controller,
                                  catalog: catalog,
                                  selection: selection,
                                  compact: true,
                                  isTaxonomyPanelExpanded:
                                      isTaxonomyPanelVisible,
                                  onTaxonomyPanelToggled: () =>
                                      _toggleTaxonomyPanel(hasTaxonomyGroups),
                                  onPrimarySelectionChanged: (next) =>
                                      _revealTaxonomyPanelForTypeChange(
                                        catalog,
                                        next,
                                      ),
                                  autoRevealSelectedChips: false,
                                ),
                              ),
                            ),
                          ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _PinnedHeaderDelegate(
                            minHeight: kToolbarHeight,
                            maxHeight: kToolbarHeight,
                            child: SizedBox(
                              height: kToolbarHeight,
                              child: HomeAgendaAppBar(
                                controller: widget.controller,
                              ),
                            ),
                          ),
                        ),
                        if (showFilterPanel)
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _PinnedHeaderDelegate(
                              minHeight: _filterPanelExtent,
                              maxHeight: _filterPanelExtent,
                              child: _HomeAgendaFilterPanel(
                                controller: widget.controller,
                                catalog: catalog,
                                selection: selection,
                                compact: true,
                                isTaxonomyPanelExpanded: isTaxonomyPanelVisible,
                                onTaxonomyPanelToggled: () =>
                                    _toggleTaxonomyPanel(hasTaxonomyGroups),
                                onPrimarySelectionChanged: (next) =>
                                    _revealTaxonomyPanelForTypeChange(
                                      catalog,
                                      next,
                                    ),
                              ),
                            ),
                          ),
                        if (hasTaxonomyGroups && isTaxonomyPanelVisible)
                          SliverToBoxAdapter(
                            child: KeyedSubtree(
                              key: _taxonomyPanelRevealKey,
                              child: _HomeAgendaFilterPanel(
                                controller: widget.controller,
                                catalog: catalog,
                                selection: selection,
                                compact: false,
                              ),
                            ),
                          ),
                      ],
                      scrollViewBuilder:
                          ({
                            required headerSlivers,
                            required scrollController,
                          }) => HomeAgendaBody(
                            controller: widget.controller,
                            catalog: catalog,
                            selection: selection,
                            headerSlivers: headerSlivers,
                            scrollController: scrollController,
                          ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _toggleTaxonomyPanel(bool hasTaxonomyGroups) {
    if (!hasTaxonomyGroups) return;
    if (widget.controller.isDiscoveryFilterPanelVisibleStreamValue.value) {
      widget.controller.closeDiscoveryFilterPanel();
      return;
    }
    widget.controller.openDiscoveryFilterPanelForReveal();
    _revealTaxonomyPanelInViewport();
  }

  void _updateFilterPanelExtent(Size size) {
    final nextExtent = size.height <= 0
        ? _defaultFilterPanelExtent
        : size.height;
    if ((nextExtent - _filterPanelExtent).abs() < 0.5 || !mounted) {
      return;
    }
    setState(() {
      _filterPanelExtent = nextExtent;
    });
  }

  void _revealTaxonomyPanelForTypeChange(
    DiscoveryFilterCatalog catalog,
    DiscoveryFilterSelection selection,
  ) {
    if (!hasDiscoveryFilterTaxonomyGroups(
      catalog: catalog,
      selection: selection,
      policy: widget.controller.discoveryFilterPolicy,
    )) {
      return;
    }
    _revealTaxonomyPanelInViewport();
  }

  void _revealTaxonomyPanelInViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _taxonomyPanelRevealKey.currentContext;
      if (targetContext == null) {
        widget.controller.completeDiscoveryFilterPanelReveal();
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 1.0,
        ).whenComplete(widget.controller.completeDiscoveryFilterPanelReveal),
      );
    });
  }
}

class _HomeAgendaFilterPanel extends StatelessWidget {
  const _HomeAgendaFilterPanel({
    required this.controller,
    required this.catalog,
    required this.selection,
    this.compact = false,
    this.isTaxonomyPanelExpanded = false,
    this.onTaxonomyPanelToggled,
    this.onPrimarySelectionChanged,
    this.autoRevealSelectedChips = true,
  });

  final TenantHomeAgendaController controller;
  final DiscoveryFilterCatalog catalog;
  final DiscoveryFilterSelection selection;
  final bool autoRevealSelectedChips;
  final bool compact;
  final bool isTaxonomyPanelExpanded;
  final VoidCallback? onTaxonomyPanelToggled;
  final ValueChanged<DiscoveryFilterSelection>? onPrimarySelectionChanged;

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
                    showPrimary: compact,
                    showTaxonomyGroups: !compact,
                    showCompactControls: compact,
                    isTaxonomyPanelExpanded: isTaxonomyPanelExpanded,
                    onTaxonomyPanelToggled: onTaxonomyPanelToggled,
                    isLoading: isInitialLoading || isPageLoading,
                    autoRevealSelectedChips: autoRevealSelectedChips,
                    iconBuilder: buildDiscoveryFilterVisualIcon,
                    onSelectionChanged: (next) {
                      final primaryChanged = !setEquals(
                        selection.primaryKeys,
                        next.primaryKeys,
                      );
                      controller.setDiscoveryFilterSelection(next);
                      if (primaryChanged) onPrimarySelectionChanged?.call(next);
                    },
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
      child: SizedBox.expand(
        child: ClipRect(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
