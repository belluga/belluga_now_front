import 'dart:async';

import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
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
                final taxonomyGroups = options?.taxonomyGroups ?? const [];
                return StreamValueBuilder<Set<String>>(
                  streamValue: _mapController.activeCategoryKeysStreamValue,
                  builder: (_, activeCategoryKeys) {
                    return StreamValueBuilder<Set<String>>(
                      streamValue:
                          _mapController.activeTaxonomyTokensStreamValue,
                      builder: (_, activeTaxonomyTokens) {
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
                              ...categories.map((category) {
                                final isActive = activeCategoryKeys.contains(
                                    category.key.trim().toLowerCase());
                                final activeColor =
                                    _colorForCategoryKey(category.key, scheme);
                                final activeFg = isActive
                                    ? _foregroundForColor(activeColor)
                                    : scheme.onSurfaceVariant;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: FabActionButton(
                                    label: category.label,
                                    icon: _iconForCategoryKey(category.key),
                                    iconWidget: _categoryImage(
                                      category,
                                      fallbackIcon: _iconForCategoryKey(
                                        category.key,
                                      ),
                                      fallbackColor: activeFg,
                                    ),
                                    backgroundColor:
                                        isActive ? activeColor : scheme.surface,
                                    foregroundColor: activeFg,
                                    onTap: () => _mapController
                                        .toggleCatalogCategoryFilter(category),
                                    condensed: condensed,
                                  ),
                                );
                              }),
                              if (taxonomyGroups.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 8,
                                  ),
                                  child: _TaxonomyFiltersCard(
                                    groups: taxonomyGroups,
                                    activeTokens: activeTaxonomyTokens,
                                    onToggle:
                                        _mapController.toggleTaxonomyFilter,
                                  ),
                                ),
                              if (activeCategoryKeys.isNotEmpty ||
                                  activeTaxonomyTokens.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: FabActionButton(
                                    label: 'Limpar filtros',
                                    icon: Icons.filter_alt_off,
                                    backgroundColor: scheme.surface,
                                    foregroundColor: scheme.onSurfaceVariant,
                                    onTap: _mapController.clearFilters,
                                    condensed: condensed,
                                  ),
                                ),
                              const SizedBox(height: 4),
                            ],
                            FloatingActionButton(
                              heroTag: 'map-fab-main',
                              onPressed: _fabController.toggleExpanded,
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
          },
        );
      },
    );
  }

  Widget? _categoryImage(
    PoiFilterCategory category, {
    required IconData fallbackIcon,
    required Color fallbackColor,
  }) {
    final imageUri = category.imageUri?.trim() ?? '';
    if (imageUri.isEmpty) {
      return null;
    }
    return SizedBox.square(
      dimension: 20,
      child: ClipOval(
        child: Image.network(
          imageUri,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            fallbackIcon,
            size: 18,
            color: fallbackColor,
          ),
        ),
      ),
    );
  }

  IconData _iconForCategoryKey(String key) {
    switch (key.trim().toLowerCase()) {
      case 'event':
        return BooraIcons.audiotrack;
      case 'restaurant':
        return Icons.restaurant;
      case 'beach':
        return Icons.beach_access;
      case 'lodging':
        return Icons.hotel;
      case 'nature':
        return Icons.park;
      case 'historic':
      case 'culture':
        return Icons.account_balance;
      default:
        return Icons.place;
    }
  }

  Color _colorForCategoryKey(String key, ColorScheme scheme) {
    switch (key.trim().toLowerCase()) {
      case 'event':
        return scheme.primary;
      case 'restaurant':
        return const Color(0xFFFF7043);
      case 'beach':
        return const Color(0xFF03A9F4);
      case 'lodging':
        return const Color(0xFF7E57C2);
      case 'nature':
        return const Color(0xFF66BB6A);
      case 'historic':
      case 'culture':
        return const Color(0xFF8D6E63);
      default:
        return scheme.primary;
    }
  }
}

Color _foregroundForColor(Color color) {
  final brightness = ThemeData.estimateBrightnessForColor(color);
  return brightness == Brightness.dark ? Colors.white : Colors.black87;
}

class _TaxonomyFiltersCard extends StatelessWidget {
  const _TaxonomyFiltersCard({
    required this.groups,
    required this.activeTokens,
    required this.onToggle,
  });

  final List<PoiFilterTaxonomyGroup> groups;
  final Set<String> activeTokens;
  final ValueChanged<PoiFilterTaxonomyTerm> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Taxonomias',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ...groups.map((group) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: group.terms.map((term) {
                          final selected = activeTokens.contains(term.token);
                          return FilterChip(
                            selected: selected,
                            label: Text(term.label),
                            onSelected: (_) => onToggle(term),
                          );
                        }).toList(growable: false),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
