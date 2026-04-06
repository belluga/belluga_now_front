import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_tray_mode.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_filter_category_icon.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

const double _kTrayActionButtonHeight = 40;
const double _kTrayActionButtonMinWidth = 84;
const double _kFilterPillMinHeight = 48;

class MapAdaptiveTray extends StatelessWidget {
  const MapAdaptiveTray({
    super.key,
    required this.controller,
  });

  final MapScreenController controller;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: StreamValueBuilder<MapTrayMode>(
        streamValue: controller.mapTrayModeStreamValue,
        builder: (_, trayMode) {
          return StreamValueBuilder<PoiFilterOptions?>(
            streamValue: controller.filterOptionsStreamValue,
            builder: (_, filterOptions) {
              return StreamValueBuilder<List<CityPoiModel>?>(
                streamValue: controller.filteredPoisStreamValue,
                builder: (_, filteredPoisOrNull) {
                  final filteredPois =
                      filteredPoisOrNull ?? const <CityPoiModel>[];
                  return StreamValueBuilder<String?>(
                    streamValue: controller.activeFilterLabelStreamValue,
                    builder: (_, activeFilterLabel) {
                      return StreamValueBuilder<String?>(
                        streamValue: controller.pendingFilterLabelStreamValue,
                        builder: (_, pendingFilterLabel) {
                          return StreamValueBuilder<String?>(
                            streamValue:
                                controller.activeCatalogFilterKeyStreamValue,
                            builder: (_, activeCatalogFilterKey) {
                              return StreamValueBuilder<String?>(
                                streamValue: controller
                                    .appliedCatalogFilterKeyStreamValue,
                                builder: (_, appliedCatalogFilterKey) {
                                  return StreamValueBuilder<bool>(
                                    streamValue: controller
                                        .filterInteractionLockedStreamValue,
                                    builder: (_, filterPending) {
                                      final visualFilterLabel =
                                          activeFilterLabel
                                                      ?.trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? activeFilterLabel!.trim()
                                              : pendingFilterLabel?.trim();
                                      return AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        child: DecoratedBox(
                                          key: ValueKey<String>(
                                            '${trayMode.name}|${visualFilterLabel ?? 'none'}|${activeCatalogFilterKey ?? 'none'}|${appliedCatalogFilterKey ?? 'none'}|$filterPending',
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface
                                                .withValues(alpha: 0.96),
                                            borderRadius:
                                                BorderRadius.circular(28),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 18,
                                                offset: Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              18,
                                              14,
                                              18,
                                              18,
                                            ),
                                            child: switch (trayMode) {
                                              MapTrayMode.discovery =>
                                                _DiscoveryTrayBody(
                                                  controller: controller,
                                                  filterOptions: filterOptions,
                                                  filteredPois: filteredPois,
                                                  activeFilterLabel:
                                                      visualFilterLabel,
                                                  activeCatalogFilterKey:
                                                      activeCatalogFilterKey,
                                                  appliedCatalogFilterKey:
                                                      appliedCatalogFilterKey,
                                                  filterPending: filterPending,
                                                ),
                                              MapTrayMode.filters =>
                                                _FiltersTrayBody(
                                                  controller: controller,
                                                  filterOptions: filterOptions,
                                                  activeFilterLabel:
                                                      visualFilterLabel,
                                                  filterPending: filterPending,
                                                ),
                                              MapTrayMode.search =>
                                                _SearchTrayBody(
                                                  controller: controller,
                                                  filteredPois: filteredPois,
                                                ),
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DiscoveryTrayBody extends StatelessWidget {
  const _DiscoveryTrayBody({
    required this.controller,
    required this.filterOptions,
    required this.filteredPois,
    required this.activeFilterLabel,
    required this.activeCatalogFilterKey,
    required this.appliedCatalogFilterKey,
    required this.filterPending,
  });

  final MapScreenController controller;
  final PoiFilterOptions? filterOptions;
  final List<CityPoiModel> filteredPois;
  final String? activeFilterLabel;
  final String? activeCatalogFilterKey;
  final String? appliedCatalogFilterKey;
  final bool filterPending;

  @override
  Widget build(BuildContext context) {
    final categories = controller.visibleCatalogCategories(filterOptions);
    final hasActiveFilter = (activeFilterLabel?.trim().isNotEmpty ?? false);
    final activeCategory = _resolveDisplayedCategory(categories);
    final surfaceTitle =
        hasActiveFilter ? activeFilterLabel!.trim() : 'Perto de você';
    final surfaceSubtitle = hasActiveFilter
        ? 'Filtro ativo na exploração local'
        : '${filteredPois.length} lugares e eventos por perto';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrayGrabber(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surfaceTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    surfaceSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            _TrayActionTextButton(
              label: 'Ver tudo',
              onPressed: controller.showFiltersTray,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (hasActiveFilter)
          _SelectedFilterChip(
            controller: controller,
            category: activeCategory,
            activeFilterLabel: activeFilterLabel!,
            pending: filterPending,
          )
        else
          _CollapsedFilterScroller(
            controller: controller,
            categories: categories,
          ),
      ],
    );
  }

  PoiFilterCategory? _resolveDisplayedCategory(
      List<PoiFilterCategory> categories) {
    final activeKey = activeCatalogFilterKey?.trim().toLowerCase();
    if (activeKey != null && activeKey.isNotEmpty) {
      for (final category in categories) {
        if (category.key.trim().toLowerCase() == activeKey) {
          return category;
        }
      }
    }
    final appliedKey = appliedCatalogFilterKey?.trim().toLowerCase();
    if (appliedKey != null && appliedKey.isNotEmpty) {
      for (final category in categories) {
        if (category.key.trim().toLowerCase() == appliedKey) {
          return category;
        }
      }
    }
    for (final category in categories) {
      if (controller.isCategoryFilterActive(category)) {
        return category;
      }
    }
    final normalizedLabel = activeFilterLabel?.trim().toLowerCase();
    if (normalizedLabel != null && normalizedLabel.isNotEmpty) {
      for (final category in categories) {
        if (category.label.trim().toLowerCase() == normalizedLabel) {
          return category;
        }
      }
    }
    return null;
  }
}

class _FilterChipPalette {
  const _FilterChipPalette({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.controlBackgroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color controlBackgroundColor;

  factory _FilterChipPalette.resolve(
    BuildContext context,
    PoiFilterCategory? category, {
    required bool isActive,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = _FilterChipPalette(
      backgroundColor:
          isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      foregroundColor:
          isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
      controlBackgroundColor: isActive
          ? scheme.onPrimaryContainer.withValues(alpha: 0.12)
          : scheme.onSurfaceVariant.withValues(alpha: 0.08),
    );

    if (!isActive || category == null) {
      return fallback;
    }

    final overrideVisual = category.markerOverrideVisual;
    if (overrideVisual == null || !overrideVisual.isIcon) {
      return fallback;
    }

    final background =
        MapMarkerVisualResolver.tryParseHexColor(overrideVisual.colorHex) ??
            fallback.backgroundColor;
    final foreground =
        MapMarkerVisualResolver.tryParseHexColor(overrideVisual.iconColorHex) ??
            fallback.foregroundColor;

    return _FilterChipPalette(
      backgroundColor: background,
      foregroundColor: foreground,
      controlBackgroundColor: foreground.withValues(alpha: 0.16),
    );
  }
}

class _TrayActionTextButton extends StatelessWidget {
  const _TrayActionTextButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _kTrayActionButtonMinWidth,
        minHeight: _kTrayActionButtonHeight,
      ),
      child: SizedBox(
        key: ValueKey<String>('tray-action-button-$label'),
        height: _kTrayActionButtonHeight,
        child: TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(
              _kTrayActionButtonMinWidth,
              _kTrayActionButtonHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: loading
                ? const SizedBox(
                    key: ValueKey<String>('tray-action-button-loading'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                : Text(
                    label,
                    key: ValueKey<String>('tray-action-button-label-$label'),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedFilterScroller extends StatelessWidget {
  const _CollapsedFilterScroller({
    required this.controller,
    required this.categories,
  });

  final MapScreenController controller;
  final List<PoiFilterCategory> categories;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories.take(6).toList(growable: false);
    final shouldCenter = visibleCategories.length <= 3;

    final row = Row(
      mainAxisSize: shouldCenter ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var index = 0; index < visibleCategories.length; index++) ...[
          _CollapsedFilterIconChip(
            category: visibleCategories[index],
            isActive:
                controller.isCategoryFilterActive(visibleCategories[index]),
            onTap: () {
              controller.toggleCatalogCategoryFilter(visibleCategories[index]);
              controller.showDiscoveryTray();
            },
          ),
          if (index < visibleCategories.length - 1) const SizedBox(width: 10),
        ],
      ],
    );

    if (shouldCenter) {
      return Center(child: row);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: row,
    );
  }
}

class _CollapsedFilterIconChip extends StatelessWidget {
  const _CollapsedFilterIconChip({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  final PoiFilterCategory category;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _FilterChipPalette.resolve(
      context,
      category,
      isActive: isActive,
    );

    return Tooltip(
      message:
          category.label.trim().isEmpty ? category.key.trim() : category.label,
      child: Material(
        color: palette.backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: MapFilterCategoryIcon(
                category: category,
                isActive: isActive,
                fallbackIcon: Icons.filter_alt_rounded,
                fallbackColor: palette.foregroundColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedFilterChip extends StatelessWidget {
  const _SelectedFilterChip({
    required this.controller,
    required this.category,
    required this.activeFilterLabel,
    required this.pending,
  });

  final MapScreenController controller;
  final PoiFilterCategory? category;
  final String activeFilterLabel;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final palette = _FilterChipPalette.resolve(
      context,
      category,
      isActive: true,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _kFilterPillMinHeight),
      child: DecoratedBox(
        key: const ValueKey<String>('map-selected-filter-chip'),
        decoration: BoxDecoration(
          color: palette.backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category != null)
                MapFilterCategoryIcon(
                  category: category!,
                  isActive: true,
                  fallbackIcon: Icons.tune_rounded,
                  fallbackColor: palette.foregroundColor,
                )
              else
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: palette.foregroundColor,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  activeFilterLabel,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              if (pending)
                SizedBox(
                  key: const ValueKey<String>('map-selected-filter-loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      palette.foregroundColor,
                    ),
                  ),
                )
              else
                Tooltip(
                  message: 'Remover filtro',
                  child: Material(
                    color: palette.controlBackgroundColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const ValueKey<String>('map-selected-filter-clear'),
                      onTap: controller.clearFilters,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: palette.foregroundColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersTrayBody extends StatelessWidget {
  const _FiltersTrayBody({
    required this.controller,
    required this.filterOptions,
    required this.activeFilterLabel,
    required this.filterPending,
  });

  final MapScreenController controller;
  final PoiFilterOptions? filterOptions;
  final String? activeFilterLabel;
  final bool filterPending;

  @override
  Widget build(BuildContext context) {
    final categories = controller.visibleCatalogCategories(filterOptions);
    final hasActiveFilter = (activeFilterLabel?.trim().isNotEmpty ?? false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrayGrabber(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Filtrar experiências',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (hasActiveFilter)
              _TrayActionTextButton(
                label: 'Limpar',
                onPressed: filterPending ? null : controller.clearFilters,
                loading: filterPending,
              ),
            _TrayActionTextButton(
              label: 'Fechar',
              onPressed: controller.showDiscoveryTray,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories
              .map(
                (category) => _CategoryChoiceChip(
                  category: category,
                  isActive: controller.isCategoryFilterActive(category),
                  onTap: () {
                    controller.toggleCatalogCategoryFilter(category);
                    controller.showDiscoveryTray();
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _CategoryChoiceChip extends StatelessWidget {
  const _CategoryChoiceChip({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  final PoiFilterCategory category;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _FilterChipPalette.resolve(
      context,
      category,
      isActive: isActive,
    );
    return Material(
      color: palette.backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _kFilterPillMinHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MapFilterCategoryIcon(
                  category: category,
                  isActive: isActive,
                  fallbackIcon: Icons.filter_alt_rounded,
                  fallbackColor: palette.foregroundColor,
                ),
                const SizedBox(width: 8),
                Text(
                  category.label.trim().isEmpty
                      ? category.key.trim()
                      : category.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchTrayBody extends StatelessWidget {
  const _SearchTrayBody({
    required this.controller,
    required this.filteredPois,
  });

  final MapScreenController controller;
  final List<CityPoiModel> filteredPois;

  @override
  Widget build(BuildContext context) {
    final appliedSearch = controller.searchTermStreamValue.value?.trim() ?? '';
    final previewPois = filteredPois.take(3).toList(growable: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrayGrabber(),
        const SizedBox(height: 10),
        TextField(
          controller: controller.searchTextController,
          textInputAction: TextInputAction.search,
          onSubmitted: controller.searchPois,
          decoration: InputDecoration(
            hintText: 'Buscar lugares ou eventos',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: SizedBox(
              width: appliedSearch.isNotEmpty ? 96 : 48,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (appliedSearch.isNotEmpty)
                    IconButton(
                      onPressed: controller.clearSearch,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Limpar busca',
                    ),
                  IconButton(
                    onPressed: controller.showDiscoveryTray,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    tooltip: 'Fechar busca',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          onPressed: () =>
              controller.searchPois(controller.searchTextController.text),
          icon: const Icon(Icons.search_rounded),
          label: const Text('Buscar nesta área'),
        ),
        if (previewPois.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            appliedSearch.isEmpty
                ? 'Sugestões perto de você'
                : 'Resultados rápidos',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          for (final poi in previewPois)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.place_outlined),
              ),
              title: Text(poi.name),
              subtitle: poi.address.trim().isEmpty ? null : Text(poi.address),
              onTap: () => controller.handleMarkerTap(poi),
            ),
        ],
      ],
    );
  }
}

class _TrayGrabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
