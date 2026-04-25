import 'discovery_filter_catalog.dart';
import 'discovery_filter_policy.dart';
import 'discovery_filter_selection.dart';
import 'discovery_filter_taxonomy_scope.dart';

part 'discovery_filter_selection_repair_result.dart';

class DiscoveryFilterSelectionRepair {
  const DiscoveryFilterSelectionRepair();

  DiscoveryFilterSelectionRepairResult repair({
    required DiscoveryFilterSelection selection,
    required Iterable<DiscoveryFilterCatalogItem> catalog,
    required DiscoveryFilterPolicy policy,
    DiscoveryFilterCatalog? catalogEnvelope,
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

    final allowedTaxonomies = _allowedTaxonomies(
      catalogByKey: catalogByKey,
      primaryKeys: normalizedPrimaryKeys,
      catalogEnvelope: catalogEnvelope,
    );

    final taxonomyTerms = <String, Set<String>>{};
    final droppedTaxonomyTerms = <String, Set<String>>{};

    for (final entry in selection.taxonomyTermKeys.entries) {
      if (!allowedTaxonomies.contains(entry.key)) {
        if (entry.value.isNotEmpty) {
          droppedTaxonomyTerms[entry.key] = Set<String>.of(entry.value);
        }
        continue;
      }

      final termOptions = catalogEnvelope?.taxonomyOptionsByKey[entry.key];
      final allowedTerms = termOptions == null || termOptions.termsTruncated
          ? null
          : termOptions.terms.map((term) => term.value).toSet();
      final candidateTerms = allowedTerms == null
          ? Set<String>.of(entry.value)
          : entry.value.where(allowedTerms.contains).toSet();
      final normalizedTerms =
          policy.taxonomySelectionMode == DiscoveryFilterSelectionMode.single
              ? candidateTerms.take(1).toSet()
              : candidateTerms;

      if (normalizedTerms.isNotEmpty) {
        taxonomyTerms[entry.key] = normalizedTerms;
      }
      final droppedTerms = entry.value.difference(normalizedTerms);
      if (droppedTerms.isNotEmpty) {
        droppedTaxonomyTerms[entry.key] = droppedTerms;
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

  Set<String> _allowedTaxonomies({
    required Map<String, DiscoveryFilterCatalogItem> catalogByKey,
    required Set<String> primaryKeys,
    required DiscoveryFilterCatalog? catalogEnvelope,
  }) {
    final envelope = catalogEnvelope;
    if (envelope == null) {
      if (primaryKeys.isEmpty) {
        return const <String>{};
      }
      final allowed = <String>{};
      for (final key in primaryKeys) {
        final item = catalogByKey[key];
        if (item == null) {
          continue;
        }
        allowed.addAll(item.taxonomyKeys);
        allowed.addAll(item.taxonomyValuesByGroup.keys);
        allowed.addAll(item.taxonomyConfigs.keys);
      }
      return allowed;
    }
    return resolveDiscoveryFilterAllowedTaxonomyKeys(
      catalog: envelope,
      selection: DiscoveryFilterSelection(primaryKeys: primaryKeys),
    );
  }
}
