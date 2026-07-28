export 'package:belluga_now/domain/app_data/discovery_filter_entity_type_selection.dart';
export 'package:belluga_now/domain/app_data/discovery_filter_taxonomy_selection.dart';

import 'package:belluga_now/domain/app_data/discovery_filter_entity_type_selection.dart';
import 'package:belluga_now/domain/app_data/discovery_filter_taxonomy_selection.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_discovery_filter_token_value.dart';

class AppDataDiscoveryFilterSelectionSnapshot {
  const AppDataDiscoveryFilterSelectionSnapshot({
    this.primaryKeys = const <AppDataDiscoveryFilterTokenValue>[],
    this.taxonomySelections = const <AppDataDiscoveryFilterTaxonomySelection>[],
    this.typeFilterSelections =
        const <AppDataDiscoveryFilterEntityTypeSelection>[],
  });

  final List<AppDataDiscoveryFilterTokenValue> primaryKeys;
  final List<AppDataDiscoveryFilterTaxonomySelection> taxonomySelections;
  final List<AppDataDiscoveryFilterEntityTypeSelection> typeFilterSelections;

  bool get hasTypeFilterSelections =>
      typeFilterSelections.any((selection) => !selection.isEmpty);

  List<AppDataDiscoveryFilterTokenValue> typeFiltersForEntity(
    AppDataDiscoveryFilterTokenValue entityKey,
  ) {
    for (final selection in typeFilterSelections) {
      if (selection.entityKey.value == entityKey.value && !selection.isEmpty) {
        return selection.typeKeys;
      }
    }
    return const <AppDataDiscoveryFilterTokenValue>[];
  }

  bool get isEmpty {
    if (primaryKeys.isNotEmpty) {
      return false;
    }
    return taxonomySelections.every((selection) => selection.termKeys.isEmpty);
  }
}
