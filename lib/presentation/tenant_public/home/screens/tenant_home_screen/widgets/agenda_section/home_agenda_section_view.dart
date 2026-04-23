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
                final filterExtent = showFilterPanel
                    ? _filterPanelExtent(catalog, selection)
                    : 0.0;
                final headerHeight = kToolbarHeight + filterExtent;

                return widget.builder(
                  context,
                  HomeAgendaSectionSlots(
                    header: SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedHeaderDelegate(
                        minHeight: headerHeight,
                        maxHeight: headerHeight,
                        child: _HomeAgendaHeader(
                          controller: widget.controller,
                          catalog: catalog,
                          selection: selection,
                          showFilterPanel: showFilterPanel,
                        ),
                      ),
                    ),
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

  double _filterPanelExtent(
    DiscoveryFilterCatalog catalog,
    DiscoveryFilterSelection selection,
  ) {
    return _hasVisibleTaxonomyGroups(catalog, selection) ? 184 : 72;
  }

  bool _hasVisibleTaxonomyGroups(
    DiscoveryFilterCatalog catalog,
    DiscoveryFilterSelection selection,
  ) {
    if (selection.primaryKeys.isEmpty) {
      return catalog.taxonomyOptionsByKey.values.any(
        (option) => option.terms.isNotEmpty,
      );
    }
    final selectedFilters = catalog.filters.where(
      (item) => selection.primaryKeys.contains(item.key),
    );
    var hasExplicitTaxonomyScope = false;
    for (final item in selectedFilters) {
      for (final taxonomyKey in item.taxonomyKeys) {
        hasExplicitTaxonomyScope = true;
        if ((catalog.taxonomyOptionsByKey[taxonomyKey]?.terms.isNotEmpty ??
            false)) {
          return true;
        }
      }
      for (final entity in item.entities) {
        final selectedTypes = item.typesByEntity[entity] ?? item.types;
        for (final option in catalog.typeOptionsByEntity[entity] ??
            const <DiscoveryFilterTypeOption>[]) {
          if (selectedTypes.isNotEmpty &&
              !selectedTypes.contains(option.value)) {
            continue;
          }
          for (final taxonomyKey in option.allowedTaxonomyKeys) {
            hasExplicitTaxonomyScope = true;
            if ((catalog.taxonomyOptionsByKey[taxonomyKey]?.terms.isNotEmpty ??
                false)) {
              return true;
            }
          }
        }
      }
    }
    return !hasExplicitTaxonomyScope &&
        catalog.taxonomyOptionsByKey.values.any(
          (option) => option.terms.isNotEmpty,
        );
  }
}

class _HomeAgendaHeader extends StatelessWidget {
  const _HomeAgendaHeader({
    required this.controller,
    required this.catalog,
    required this.selection,
    required this.showFilterPanel,
  });

  final TenantHomeAgendaController controller;
  final DiscoveryFilterCatalog catalog;
  final DiscoveryFilterSelection selection;
  final bool showFilterPanel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: kToolbarHeight,
            child: HomeAgendaAppBar(controller: controller),
          ),
          if (showFilterPanel)
            _HomeAgendaFilterPanel(
              controller: controller,
              catalog: catalog,
              selection: selection,
            ),
        ],
      ),
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
            return Semantics(
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
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
