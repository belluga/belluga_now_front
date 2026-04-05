import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_tray_mode.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_filter_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

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
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: DecoratedBox(
                          key: ValueKey<String>(
                            '${trayMode.name}|${activeFilterLabel ?? 'none'}',
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                            child: switch (trayMode) {
                              MapTrayMode.discovery => _DiscoveryTrayBody(
                                  controller: controller,
                                  filterOptions: filterOptions,
                                  filteredPois: filteredPois,
                                  activeFilterLabel: activeFilterLabel,
                                ),
                              MapTrayMode.filters => _FiltersTrayBody(
                                  controller: controller,
                                  filterOptions: filterOptions,
                                ),
                              MapTrayMode.search => _SearchTrayBody(
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
  });

  final MapScreenController controller;
  final PoiFilterOptions? filterOptions;
  final List<CityPoiModel> filteredPois;
  final String? activeFilterLabel;

  @override
  Widget build(BuildContext context) {
    final categories =
        filterOptions?.sortedCategories ?? const <PoiFilterCategory>[];
    final hasActiveFilter = (activeFilterLabel?.trim().isNotEmpty ?? false);
    final activeCategory = _resolveActiveCategory(categories);
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
            TextButton(
              onPressed: controller.showFiltersTray,
              child: const Text('Ver tudo'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (hasActiveFilter)
          _SelectedFilterChip(
            category: activeCategory,
            activeFilterLabel: activeFilterLabel!,
          )
        else
          _CollapsedFilterScroller(
            controller: controller,
            categories: categories,
          ),
      ],
    );
  }

  PoiFilterCategory? _resolveActiveCategory(
      List<PoiFilterCategory> categories) {
    for (final category in categories) {
      if (controller.isCategoryFilterActive(category)) {
        return category;
      }
    }
    return null;
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
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor =
        isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final foregroundColor =
        isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Tooltip(
      message:
          category.label.trim().isEmpty ? category.key.trim() : category.label,
      child: Material(
        color: backgroundColor,
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
                fallbackColor: foregroundColor,
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
    required this.category,
    required this.activeFilterLabel,
  });

  final PoiFilterCategory? category;
  final String activeFilterLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
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
                fallbackColor: scheme.onPrimaryContainer,
              )
            else
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                activeFilterLabel,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersTrayBody extends StatelessWidget {
  const _FiltersTrayBody({
    required this.controller,
    required this.filterOptions,
  });

  final MapScreenController controller;
  final PoiFilterOptions? filterOptions;

  @override
  Widget build(BuildContext context) {
    final categories =
        filterOptions?.sortedCategories ?? const <PoiFilterCategory>[];
    final taxonomyGroups =
        filterOptions?.taxonomyGroups ?? const <PoiFilterTaxonomyGroup>[];

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
            TextButton(
              onPressed: controller.showDiscoveryTray,
              child: const Text('Fechar'),
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
        for (final group in taxonomyGroups) ...[
          const SizedBox(height: 18),
          Text(
            group.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: group.terms
                .map(
                  (term) => FilterChip(
                    selected: controller.isTaxonomyFilterActive(term),
                    label: Text(term.label),
                    onSelected: (_) {
                      controller.toggleTaxonomyFilter(term);
                      controller.showDiscoveryTray();
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ],
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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapFilterCategoryIcon(
                category: category,
                isActive: isActive,
                fallbackIcon: Icons.filter_alt_rounded,
                fallbackColor: isActive
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                category.label.trim().isEmpty
                    ? category.key.trim()
                    : category.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isActive
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
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
