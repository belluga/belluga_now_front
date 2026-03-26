import 'dart:async';

import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/fab_action_button.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FabMenu extends StatefulWidget {
  const FabMenu({
    super.key,
    required this.onNavigateToUser,
    required this.mapController,
    this.controller,
  });

  final VoidCallback onNavigateToUser;
  final MapScreenController mapController;
  final FabMenuController? controller;

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> {
  static const _condenseDelay = Duration(seconds: 2);

  late final FabMenuController _fabController =
      widget.controller ?? GetIt.I.get<FabMenuController>();
  late final MapScreenController _mapController = widget.mapController;

  Timer? _condenseTimer;

  @override
  void initState() {
    super.initState();
    _handleExpandedStream(_fabController.expandedStreamValue.value);
  }

  @override
  void dispose() {
    _condenseTimer?.cancel();
    super.dispose();
  }

  void _handleExpandedChange(bool expanded) {
    _condenseTimer?.cancel();
    if (!expanded) {
      _fabController.setCondensed(false);
      return;
    }
    _fabController.setRevertedOnClose(false);
    _fabController.setCondensed(false);
    _condenseTimer = Timer(_condenseDelay, () {
      _fabController.setCondensed(true);
    });
  }

  void _handleExpandedStream(bool expanded) {
    if (_fabController.lastExpanded == expanded) {
      return;
    }
    _fabController.lastExpanded = expanded;
    _handleExpandedChange(expanded);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<bool>(
      streamValue: _fabController.expandedStreamValue,
      builder: (_, expanded) {
        _handleExpandedStream(expanded);
        return StreamValueBuilder<bool>(
          streamValue: _fabController.condensedStreamValue,
          builder: (_, condensed) {
            return StreamValueBuilder<PoiFilterOptions?>(
              streamValue: _mapController.filterOptionsStreamValue,
              builder: (_, options) {
                final categories = options?.sortedCategories ?? const [];
                return StreamValueBuilder<Set<String>>(
                  streamValue: _mapController.activeCategoryKeysStreamValue,
                  builder: (_, activeCategoryKeys) {
                    return StreamValueBuilder<Set<String>>(
                      streamValue:
                          _mapController.activeTaxonomyTokensStreamValue,
                      builder: (_, activeTaxonomyTokens) {
                        return StreamValueBuilder<bool>(
                          streamValue: _mapController.isLoading,
                          builder: (_, isLoading) {
                            return StreamValueBuilder<bool>(
                              streamValue: _mapController
                                  .filterInteractionLockedStreamValue,
                              builder: (_, isFilterInteractionLocked) {
                                final interactionsEnabled =
                                    !isLoading && !isFilterInteractionLocked;
                                return StreamValueBuilder<CityCoordinate?>(
                                  streamValue:
                                      _mapController.userLocationStreamValue,
                                  builder: (_, __) {
                                    final navigateToUserEnabled =
                                        interactionsEnabled &&
                                            _mapController
                                                .hasResolvedUserLocation;
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (expanded) ...[
                                          FabActionButton(
                                            label: 'Ir para você',
                                            heroId: 'navigate-to-user',
                                            icon: Icons.my_location,
                                            backgroundColor:
                                                navigateToUserEnabled
                                                    ? scheme.secondaryContainer
                                                    : scheme.secondaryContainer
                                                        .withAlpha(128),
                                            foregroundColor:
                                                navigateToUserEnabled
                                                    ? scheme
                                                        .onSecondaryContainer
                                                    : scheme
                                                        .onSecondaryContainer
                                                        .withAlpha(176),
                                            onTap: navigateToUserEnabled
                                                ? widget.onNavigateToUser
                                                : null,
                                            condensed: condensed,
                                          ),
                                          const SizedBox(height: 8),
                                          ...categories.map((category) {
                                            final isActive = _mapController
                                                .isCategoryFilterActive(
                                                    category);
                                            final activeBackgroundColor =
                                                _resolveCategoryActiveBackgroundColor(
                                              category,
                                              fallback: scheme.primary,
                                            );
                                            final backgroundColor = isActive
                                                ? activeBackgroundColor
                                                : scheme.surfaceContainerHigh;
                                            final foregroundColor = isActive
                                                ? scheme.onPrimary
                                                : scheme.onSurfaceVariant;
                                            const fallbackIcon =
                                                Icons.filter_alt;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: FabActionButton(
                                                heroId:
                                                    'category-filter-${category.key}',
                                                label: _resolveCategoryLabel(
                                                  category,
                                                ),
                                                icon: fallbackIcon,
                                                iconWidget: _categoryVisual(
                                                  category,
                                                  isActive: isActive,
                                                  fallbackIcon: fallbackIcon,
                                                  fallbackColor:
                                                      foregroundColor,
                                                ),
                                                backgroundColor:
                                                    backgroundColor,
                                                foregroundColor:
                                                    foregroundColor,
                                                onTap: interactionsEnabled
                                                    ? () => _mapController
                                                            .toggleCatalogCategoryFilter(
                                                          category,
                                                        )
                                                    : null,
                                                condensed: condensed,
                                              ),
                                            );
                                          }),
                                          if (activeCategoryKeys.isNotEmpty ||
                                              activeTaxonomyTokens.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: FabActionButton(
                                                label: 'Limpar filtros',
                                                heroId: 'clear-filters',
                                                icon: Icons.filter_alt_off,
                                                backgroundColor: scheme.surface,
                                                foregroundColor:
                                                    scheme.onSurfaceVariant,
                                                onTap: interactionsEnabled
                                                    ? _mapController
                                                        .clearFilters
                                                    : null,
                                                condensed: condensed,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                        ],
                                        FloatingActionButton(
                                          heroTag: 'map-fab-main',
                                          onPressed:
                                              _fabController.toggleExpanded,
                                          child: Icon(expanded
                                              ? Icons.close
                                              : Icons.tune),
                                        ),
                                      ],
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
    );
  }

  Widget? _categoryVisual(
    PoiFilterCategory category, {
    required bool isActive,
    required IconData fallbackIcon,
    required Color fallbackColor,
  }) {
    final overrideVisual = category.markerOverrideVisual;
    if (overrideVisual != null && overrideVisual.isValid) {
      if (overrideVisual.isIcon) {
        final iconData =
            MapMarkerVisualResolver.resolveIcon(overrideVisual.icon);
        final configuredIconColor = MapMarkerVisualResolver.tryParseHexColor(
          overrideVisual.iconColorHex,
        );
        final iconColor =
            isActive ? (configuredIconColor ?? Colors.white) : fallbackColor;
        return Icon(
          iconData,
          size: 18,
          color: iconColor,
        );
      }
      final overrideImageUri = overrideVisual.imageUri?.trim() ?? '';
      if (overrideImageUri.isNotEmpty) {
        return _buildImageWidget(
          imageUri: overrideImageUri,
          fallbackIcon: fallbackIcon,
          fallbackColor: fallbackColor,
        );
      }
    }

    final legacyImageUri = category.imageUri?.trim() ?? '';
    if (legacyImageUri.isEmpty) {
      return null;
    }
    return _buildImageWidget(
      imageUri: legacyImageUri,
      fallbackIcon: fallbackIcon,
      fallbackColor: fallbackColor,
    );
  }

  Widget _buildImageWidget({
    required String imageUri,
    required IconData fallbackIcon,
    required Color fallbackColor,
  }) {
    return SizedBox.square(
      dimension: 20,
      child: Image.network(
        key: ValueKey(imageUri),
        imageUri,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          fallbackIcon,
          size: 18,
          color: fallbackColor,
        ),
      ),
    );
  }

  Color _resolveCategoryActiveBackgroundColor(
    PoiFilterCategory category, {
    required Color fallback,
  }) {
    final overrideVisual = category.markerOverrideVisual;
    if (overrideVisual == null || !overrideVisual.isIcon) {
      return fallback;
    }
    final color = MapMarkerVisualResolver.tryParseHexColor(
      overrideVisual.colorHex,
    );
    return color ?? fallback;
  }

  String _resolveCategoryLabel(PoiFilterCategory category) {
    final label = category.label.trim();
    if (label.isNotEmpty) {
      return label;
    }
    return category.key.trim();
  }
}
