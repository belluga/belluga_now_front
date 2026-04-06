import 'dart:math' as math;

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_tray_mode.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_filter_category_icon.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

const double _kFilterPillMinHeight = 48;
const double _kCompactFilterChipSize = 48;
const double _kFilterClusterSpacing = 10;
const int _kCollapsedFilterRows = 2;
const double _kSearchLauncherSize = 48;
const double _kSearchPreviewVisualSize = 46;

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
                                        child: trayMode == MapTrayMode.search
                                            ? _TraySurface(
                                                key: const ValueKey<String>(
                                                  'map-tray-surface-search',
                                                ),
                                                dragEnabled: true,
                                                onCollapse: controller
                                                    .showDiscoveryTray,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                    18,
                                                    14,
                                                    18,
                                                    18,
                                                  ),
                                                  child: _SearchTrayBody(
                                                    controller: controller,
                                                    filteredPois: filteredPois,
                                                  ),
                                                ),
                                              )
                                            : _FloatingFilterCluster(
                                                key: ValueKey<String>(
                                                  '${trayMode.name}|${visualFilterLabel ?? 'none'}|${activeCatalogFilterKey ?? 'none'}|${appliedCatalogFilterKey ?? 'none'}|$filterPending',
                                                ),
                                                controller: controller,
                                                filterOptions: filterOptions,
                                                activeFilterLabel:
                                                    visualFilterLabel,
                                                activeCatalogFilterKey:
                                                    activeCatalogFilterKey,
                                                appliedCatalogFilterKey:
                                                    appliedCatalogFilterKey,
                                                filterPending: filterPending,
                                                expanded: trayMode ==
                                                    MapTrayMode.filters,
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

class _TraySurface extends StatelessWidget {
  const _TraySurface({
    super.key,
    required this.child,
    this.dragEnabled = false,
    this.onExpand,
    this.onCollapse,
  });

  final Widget child;
  final bool dragEnabled;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: dragEnabled
          ? (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -240) {
                onExpand?.call();
              } else if (velocity > 240) {
                onCollapse?.call();
              }
            }
          : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _FloatingFilterCluster extends StatelessWidget {
  const _FloatingFilterCluster({
    super.key,
    required this.controller,
    required this.filterOptions,
    required this.activeFilterLabel,
    required this.activeCatalogFilterKey,
    required this.appliedCatalogFilterKey,
    required this.filterPending,
    required this.expanded,
  });

  final MapScreenController controller;
  final PoiFilterOptions? filterOptions;
  final String? activeFilterLabel;
  final String? activeCatalogFilterKey;
  final String? appliedCatalogFilterKey;
  final bool filterPending;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final categories = controller.visibleCatalogCategories(filterOptions);
    final activeCategory = _resolveDisplayedCategory(categories);
    final activeLabel = activeFilterLabel?.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsedCapacity = _collapsedCapacity(
          maxWidth: constraints.maxWidth,
          hasExpandedActiveChip: activeCategory != null &&
              activeLabel != null &&
              activeLabel.isNotEmpty,
        );
        final hasOverflow = categories.length > collapsedCapacity;
        final visibleCategories = expanded || !hasOverflow
            ? categories
            : categories.take(collapsedCapacity).toList(growable: false);

        return _TraySurface(
          key: ValueKey<String>(
            'map-tray-surface-${expanded ? 'filters' : 'discovery'}',
          ),
          dragEnabled: hasOverflow,
          onExpand: hasOverflow ? controller.showFiltersTray : null,
          onCollapse: hasOverflow ? controller.showDiscoveryTray : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasOverflow) ...[
                  _FilterClusterHandle(
                    expanded: expanded,
                    onToggle: expanded
                        ? controller.showDiscoveryTray
                        : controller.showFiltersTray,
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: visibleCategories.isEmpty
                          ? const SizedBox.shrink()
                          : Wrap(
                              key: ValueKey<String>(
                                'map-filter-cluster-wrap-${expanded ? 'expanded' : 'collapsed'}',
                              ),
                              spacing: _kFilterClusterSpacing,
                              runSpacing: _kFilterClusterSpacing,
                              children: visibleCategories.map(
                                (category) {
                                  final matchesPersistedKey =
                                      _matchesCategoryKey(
                                    category,
                                    activeCatalogFilterKey:
                                        activeCatalogFilterKey,
                                    appliedCatalogFilterKey:
                                        appliedCatalogFilterKey,
                                  );
                                  return _FloatingFilterChip(
                                    category: category,
                                    isActive: controller.isCategoryFilterActive(
                                          category,
                                        ) ||
                                        matchesPersistedKey,
                                    activeFilterLabel: activeLabel,
                                    pending:
                                        filterPending && matchesPersistedKey,
                                    enabled: !filterPending,
                                    onTap: () {
                                      controller.toggleCatalogCategoryFilter(
                                        category,
                                      );
                                      controller.showDiscoveryTray();
                                    },
                                    onClear: controller.clearFilters,
                                  );
                                },
                              ).toList(growable: false),
                            ),
                    ),
                    if (visibleCategories.isNotEmpty) const SizedBox(width: 16),
                    Align(
                      alignment: Alignment.topRight,
                      child: _DockSearchLauncher(
                        onTap: controller.showSearchTray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

  int _collapsedCapacity({
    required double maxWidth,
    required bool hasExpandedActiveChip,
  }) {
    final effectiveWidth =
        maxWidth.isFinite ? math.max(0, maxWidth - 36) : 384.0;
    final perRow = math.max(
      1,
      ((effectiveWidth + _kFilterClusterSpacing) /
              (_kCompactFilterChipSize + _kFilterClusterSpacing))
          .floor(),
    );
    final baseCapacity = perRow * _kCollapsedFilterRows;
    if (!hasExpandedActiveChip) {
      return baseCapacity;
    }
    return math.max(1, baseCapacity - math.min(2, perRow - 1));
  }

  bool _matchesCategoryKey(
    PoiFilterCategory category, {
    required String? activeCatalogFilterKey,
    required String? appliedCatalogFilterKey,
  }) {
    final normalizedKey = category.key.trim().toLowerCase();
    if (normalizedKey.isEmpty) {
      return false;
    }
    final activeKey = activeCatalogFilterKey?.trim().toLowerCase();
    if (activeKey != null && activeKey == normalizedKey) {
      return true;
    }
    final appliedKey = appliedCatalogFilterKey?.trim().toLowerCase();
    return appliedKey != null && appliedKey == normalizedKey;
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

class _FilterClusterHandle extends StatelessWidget {
  const _FilterClusterHandle({
    required this.expanded,
    required this.onToggle,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: expanded ? 'Recolher filtros' : 'Expandir filtros',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey<String>('map-filter-cluster-handle'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: _TrayGrabber(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingFilterChip extends StatelessWidget {
  const _FloatingFilterChip({
    required this.category,
    required this.isActive,
    required this.activeFilterLabel,
    required this.pending,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final PoiFilterCategory category;
  final bool isActive;
  final String? activeFilterLabel;
  final bool pending;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = _FilterChipPalette.resolve(
      context,
      category,
      isActive: isActive,
    );

    if (!isActive) {
      return Tooltip(
        message: category.label.trim().isEmpty
            ? category.key.trim()
            : category.label,
        child: Material(
          key: ValueKey<String>('map-compact-filter-chip-${category.key}'),
          color: palette.backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: _kCompactFilterChipSize,
              height: _kCompactFilterChipSize,
              child: Center(
                child: MapFilterCategoryIcon(
                  category: category,
                  isActive: false,
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
              MapFilterCategoryIcon(
                category: category,
                isActive: true,
                fallbackIcon: Icons.tune_rounded,
                fallbackColor: palette.foregroundColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  (activeFilterLabel?.trim().isNotEmpty ?? false)
                      ? activeFilterLabel!.trim()
                      : (category.label.trim().isEmpty
                          ? category.key.trim()
                          : category.label),
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
                      onTap: onClear,
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
          onChanged: controller.handleSearchInputChanged,
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
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SearchSuggestionCard(
                poi: poi,
                onTap: () => controller.handleMarkerTap(poi),
              ),
            ),
        ],
      ],
    );
  }
}

class _DockSearchLauncher extends StatelessWidget {
  const _DockSearchLauncher({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Buscar',
      child: Material(
        key: const ValueKey<String>('map-dock-search-launcher'),
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: _kSearchLauncherSize * 0.62,
          highlightShape: BoxShape.circle,
          child: SizedBox(
            width: _kSearchLauncherSize,
            height: _kSearchLauncherSize,
            child: Center(
              child: Icon(
                Icons.search_rounded,
                size: 21,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchSuggestionCard extends StatelessWidget {
  const _SearchSuggestionCard({
    required this.poi,
    required this.onTap,
  });

  final CityPoiModel poi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        );

    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _SearchSuggestionVisual(poi: poi),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      poi.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resolveSearchSuggestionMeta(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveSearchSuggestionMeta() {
    final meta = <String>[];
    final distance = _formatDistance();
    final address = _formatLocationContext();
    if (distance != null) {
      meta.add(distance);
    }
    if (address != null) {
      meta.add(address);
    }
    if (meta.isEmpty) {
      meta.add(_categoryLabel());
    }
    return meta.join(' • ');
  }

  String _categoryLabel() {
    return switch (poi.category) {
      CityPoiCategory.restaurant => 'Restaurante',
      CityPoiCategory.health => 'Saúde',
      CityPoiCategory.monument => 'Monumento',
      CityPoiCategory.church => 'Igreja',
      CityPoiCategory.beach => 'Praia',
      CityPoiCategory.lodging => 'Hospedagem',
      CityPoiCategory.culture => poi.isDynamic ? 'Evento' : 'Cultura',
      CityPoiCategory.nature => 'Natureza',
      CityPoiCategory.sponsor => 'Destaque',
      CityPoiCategory.attraction => 'Lugar',
    };
  }

  String? _formatDistance() {
    final distance = poi.distanceMeters;
    if (distance == null || !distance.isFinite || distance <= 0) {
      return null;
    }
    if (distance < 1000) {
      return '${distance.round()}m';
    }
    final inKm = distance / 1000;
    return '${inKm.toStringAsFixed(inKm >= 10 ? 0 : 1)} km';
  }

  String? _formatLocationContext() {
    final address = poi.address.trim();
    if (address.isEmpty) {
      return null;
    }
    final compact = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (compact.isEmpty) {
      return address;
    }
    return compact.join(' • ');
  }
}

class _SearchSuggestionVisual extends StatelessWidget {
  const _SearchSuggestionVisual({
    required this.poi,
  });

  final CityPoiModel poi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUri =
        poi.visual?.isImage == true ? poi.visual?.imageUri?.trim() : null;
    final assetPath = poi.assetPath?.trim();

    Widget child;
    if (imageUri != null && imageUri.isNotEmpty) {
      child = BellugaNetworkImage(
        imageUri,
        width: _kSearchPreviewVisualSize,
        height: _kSearchPreviewVisualSize,
        fit: BoxFit.cover,
        clipBorderRadius: BorderRadius.circular(14),
      );
    } else if (assetPath != null && assetPath.isNotEmpty) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          assetPath,
          width: _kSearchPreviewVisualSize,
          height: _kSearchPreviewVisualSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(scheme),
        ),
      );
    } else {
      child = _buildPlaceholder(scheme);
    }

    return SizedBox(
      width: _kSearchPreviewVisualSize,
      height: _kSearchPreviewVisualSize,
      child: child,
    );
  }

  Widget _buildPlaceholder(ColorScheme scheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          Icons.place_outlined,
          color: scheme.onPrimaryContainer,
          size: 20,
        ),
      ),
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
