import 'discovery_filter_catalog.dart';
import 'discovery_filter_selection.dart';

Set<String> resolveDiscoveryFilterAllowedTaxonomyKeys({
  required DiscoveryFilterCatalog catalog,
  required DiscoveryFilterSelection selection,
}) {
  if (selection.primaryKeys.isEmpty) {
    return catalog.taxonomyOptionsByKey.keys.toSet();
  }

  final allowed = <String>{};
  final selectedFilters = catalog.filters.where(
    (item) => selection.primaryKeys.contains(item.key),
  );

  void appendAll(Iterable<String> rawKeys) {
    for (final rawKey in rawKeys) {
      final key = rawKey.trim();
      if (key.isNotEmpty) {
        allowed.add(key);
      }
    }
  }

  for (final item in selectedFilters) {
    appendAll(item.taxonomyKeys);
    appendAll(item.taxonomyValuesByGroup.keys);
    appendAll(item.taxonomyConfigs.keys);

    for (final entity in item.entities) {
      final entityKey = entity.trim();
      if (entityKey.isEmpty) {
        continue;
      }
      final selectedTypes = item.typesByEntity[entityKey] ?? item.types;
      for (final option in catalog.typeOptionsByEntity[entityKey] ?? const []) {
        if (selectedTypes.isNotEmpty &&
            !selectedTypes.contains(option.value)) {
          continue;
        }
        appendAll(option.allowedTaxonomyKeys);
      }
    }
  }

  return allowed;
}

bool hasVisibleDiscoveryFilterTaxonomyGroups({
  required DiscoveryFilterCatalog catalog,
  required DiscoveryFilterSelection selection,
}) {
  if (selection.primaryKeys.isEmpty) {
    return catalog.taxonomyOptionsByKey.values.any(
      (option) => option.terms.isNotEmpty,
    );
  }

  final allowedKeys = resolveDiscoveryFilterAllowedTaxonomyKeys(
    catalog: catalog,
    selection: selection,
  );
  if (allowedKeys.isEmpty) {
    return false;
  }

  for (final key in allowedKeys) {
    if (catalog.taxonomyOptionsByKey[key]?.terms.isNotEmpty ?? false) {
      return true;
    }
  }
  return false;
}
