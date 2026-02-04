import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/fab_action_button.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/shared/poi_category_theme.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FabMenu extends StatefulWidget {
  const FabMenu({
    super.key,
    required this.onNavigateToUser,
    this.controller,
  });

  final VoidCallback onNavigateToUser;
  final FabMenuController? controller;

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> {
  static const _condenseDelay = Duration(seconds: 2);

  late final FabMenuController _fabController =
      widget.controller ?? GetIt.I.get<FabMenuController>();

  Timer? _condenseTimer;

  @override
  void initState() {
    super.initState();
    _handleExpandedStream(_fabController.expandedStreamValue.value);
    _handleFilterModeStream(_fabController.filterModeStreamValue.value);
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

  void _handleFilterModeStream(PoiFilterMode mode) {
    if (_fabController.lastFilterMode == mode) {
      return;
    }
    if (_fabController.ignoreNextFilterChangeStreamValue.value) {
      _fabController.setIgnoreNextFilterChange(false);
    } else {
      if (_fabController.lastFilterMode != null) {
        _fabController.previousFilterMode = _fabController.lastFilterMode!;
      }
      _fabController.setRevertedOnClose(false);
    }
    _fabController.lastFilterMode = mode;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<bool>(
      streamValue: _fabController.expandedStreamValue,
      builder: (_, expanded) {
        _handleExpandedStream(expanded);
        return StreamValueBuilder<PoiFilterMode>(
          streamValue: _fabController.filterModeStreamValue,
          builder: (_, mode) {
            _handleFilterModeStream(mode);
            final filterConfigs = [
              const _FilterConfig(
                mode: PoiFilterMode.events,
                label: 'Eventos agora',
                icon: BooraIcons.audiotrack,
              ),
              const _FilterConfig(
                mode: PoiFilterMode.restaurants,
                label: 'Restaurantes',
                icon: Icons.restaurant,
              ),
              const _FilterConfig(
                mode: PoiFilterMode.beaches,
                label: 'Praias',
                icon: Icons.beach_access,
              ),
              const _FilterConfig(
                mode: PoiFilterMode.lodging,
                label: 'Hospedagens',
                icon: Icons.hotel,
              ),
            ];

            return StreamValueBuilder<bool>(
              streamValue: _fabController.condensedStreamValue,
              builder: (_, condensed) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (expanded) ...[
                      FabActionButton(
                        label: 'Ir para você',
                        icon: Icons.my_location,
                        backgroundColor: scheme.secondaryContainer,
                        foregroundColor: scheme.onSecondaryContainer,
                        onTap: widget.onNavigateToUser,
                        condensed: condensed,
                      ),
                      const SizedBox(height: 8),
                      ...filterConfigs.map((config) {
                        final isActive = mode == config.mode;
                        final activeColor = _colorForFilter(config.mode, scheme);
                        final activeFg = isActive
                            ? _foregroundForColor(activeColor)
                            : scheme.onSurfaceVariant;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FabActionButton(
                            label: config.label,
                            icon: config.icon,
                            backgroundColor:
                                isActive ? activeColor : scheme.surface,
                            foregroundColor: activeFg,
                            onTap: () =>
                                _fabController.toggleFilterMode(config.mode),
                            condensed: condensed,
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                    FloatingActionButton(
                      heroTag: 'map-fab-main',
                      onPressed: () =>
                          _handleMainFabPressed(mode, expanded),
                      child: Icon(expanded ? Icons.close : Icons.tune),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleMainFabPressed(PoiFilterMode mode, bool expanded) {
    if (!expanded) {
      _fabController.toggleExpanded();
      return;
    }

    if (!_fabController.revertedOnCloseStreamValue.value &&
        mode != _fabController.previousFilterMode) {
      _fabController.setIgnoreNextFilterChange(true);
      _fabController.toggleFilterMode(_fabController.previousFilterMode);
      _fabController.setRevertedOnClose(true);
      return;
    }

    _fabController.toggleExpanded();
  }
}

class _FilterConfig {
  const _FilterConfig({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final PoiFilterMode mode;
  final String label;
  final IconData icon;
}

Color _colorForFilter(PoiFilterMode mode, ColorScheme scheme) {
  switch (mode) {
    case PoiFilterMode.events:
      return scheme.primary;
    case PoiFilterMode.restaurants:
      return categoryTheme(CityPoiCategory.restaurant, scheme).color;
    case PoiFilterMode.beaches:
      return categoryTheme(CityPoiCategory.beach, scheme).color;
    case PoiFilterMode.lodging:
      return categoryTheme(CityPoiCategory.lodging, scheme).color;
    case PoiFilterMode.none:
      return scheme.surfaceContainerHighest;
  }
}

Color _foregroundForColor(Color color) {
  final brightness = ThemeData.estimateBrightnessForColor(color);
  return brightness == Brightness.dark ? Colors.white : Colors.black87;
}
