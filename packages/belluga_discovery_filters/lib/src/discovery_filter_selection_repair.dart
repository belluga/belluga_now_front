import 'discovery_filter_catalog.dart';
import 'discovery_filter_policy.dart';
import 'discovery_filter_selection.dart';

part 'discovery_filter_selection_repair_result.dart';

class DiscoveryFilterSelectionRepair {
  const DiscoveryFilterSelectionRepair();

  DiscoveryFilterSelectionRepairResult repair({
    required DiscoveryFilterSelection selection,
    required Iterable<DiscoveryFilterCatalogItem> catalog,
    required DiscoveryFilterPolicy policy,
  }) {
    final catalogByKey = <String, DiscoveryFilterCatalogItem>{
      for (final item in catalog)
        if (item.isValid) item.key: item,
    };

    final primaryKeys = <String>[];
    final droppedPrimary = <String>{};

    for (final key in selection.primaryKeys) {
      if (catalogByKey.containsKey(key)) {
        primaryKeys.add(key);
      } else {
        droppedPrimary.add(key);
      }
    }

    final normalizedPrimaryKeys =
        policy.primarySelectionMode == DiscoveryFilterSelectionMode.single
            ? primaryKeys.take(1).toSet()
            : primaryKeys.toSet();

    if (normalizedPrimaryKeys.length != primaryKeys.length) {
      droppedPrimary.addAll(primaryKeys.skip(normalizedPrimaryKeys.length));
    }

    final allowedTaxonomies = <String>{};
    for (final key in normalizedPrimaryKeys) {
      allowedTaxonomies.addAll(catalogByKey[key]?.taxonomyKeys ?? const {});
    }

    final taxonomyTerms = <String, Set<String>>{};
    final droppedTaxonomyTerms = <String, Set<String>>{};

    for (final entry in selection.taxonomyTermKeys.entries) {
      if (!allowedTaxonomies.contains(entry.key)) {
        if (entry.value.isNotEmpty) {
          droppedTaxonomyTerms[entry.key] = Set<String>.of(entry.value);
        }
        continue;
      }

      final normalizedTerms =
          policy.taxonomySelectionMode == DiscoveryFilterSelectionMode.single
              ? entry.value.take(1).toSet()
              : Set<String>.of(entry.value);

      if (normalizedTerms.isNotEmpty) {
        taxonomyTerms[entry.key] = normalizedTerms;
      }
      if (normalizedTerms.length != entry.value.length) {
        droppedTaxonomyTerms[entry.key] =
            entry.value.skip(normalizedTerms.length).toSet();
      }
    }

    final repaired = DiscoveryFilterSelection(
      primaryKeys: normalizedPrimaryKeys,
      taxonomyTermKeys: taxonomyTerms,
    );

    return DiscoveryFilterSelectionRepairResult(
      selection: repaired,
      changed: droppedPrimary.isNotEmpty ||
          droppedTaxonomyTerms.isNotEmpty ||
          repaired.primaryKeys.length != selection.primaryKeys.length ||
          repaired.taxonomyTermKeys.length != selection.taxonomyTermKeys.length,
      droppedPrimaryKeys: droppedPrimary,
      droppedTaxonomyTerms: droppedTaxonomyTerms,
    );
  }
}
