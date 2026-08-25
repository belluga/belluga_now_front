import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';

/// Resolves user-facing context only from labels in the effective catalog.
String? publicDiscoveryFilterEmptyStateMessage({
  required DiscoveryFilterCatalog catalog,
  required DiscoveryFilterSelection selection,
}) {
  if (selection.isEmpty) {
    return null;
  }

  final segments = <String>[];
  final selectedFilters = catalog.filters
      .where((filter) => selection.primaryKeys.contains(filter.key))
      .toList(growable: false);
  segments.addAll(selectedFilters.map((filter) => filter.label));

  if (selectedFilters.isEmpty) {
    return null;
  }

  for (final groupEntry in catalog.taxonomyOptionsByKey.entries) {
    final groupKey = groupEntry.key;
    final selectedTerms = selection.taxonomyTermKeys[groupKey];
    if (selectedTerms == null || selectedTerms.isEmpty) {
      continue;
    }
    DiscoveryFilterTaxonomyConfig? config;
    var isAllowed = false;
    for (final filter in selectedFilters) {
      final filterConfig = filter.taxonomyConfigs[groupKey];
      if (filterConfig != null) {
        config = filterConfig;
      }
      if (filter.taxonomyConfigs.containsKey(groupKey) ||
          resolveDiscoveryFilterAllowedTaxonomyKeys(
            catalog: catalog,
            selection: DiscoveryFilterSelection(
              primaryKeys: <String>{filter.key},
            ),
          ).contains(groupKey)) {
        isAllowed = true;
      }
    }
    if (!isAllowed) {
      continue;
    }
    final group = groupEntry.value;
    final labels = group.terms
        .where((term) => selectedTerms.contains(term.value))
        .map((term) => term.label)
        .toList(growable: false);
    if (labels.isEmpty) {
      continue;
    }
    final override = config?.labelOverride?.trim();
    final groupLabel = override?.isNotEmpty == true ? override! : group.label;
    segments.add('$groupLabel: ${labels.join(', ')}');
  }

  if (segments.isEmpty) {
    return null;
  }
  return 'Nenhum resultado para os filtros selecionados: ${segments.join(' · ')}.';
}
