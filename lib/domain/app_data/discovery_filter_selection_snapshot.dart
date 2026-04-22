export 'package:belluga_now/domain/app_data/discovery_filter_taxonomy_selection.dart';

import 'package:belluga_now/domain/app_data/discovery_filter_taxonomy_selection.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_discovery_filter_token_value.dart';

class AppDataDiscoveryFilterSelectionSnapshot {
  const AppDataDiscoveryFilterSelectionSnapshot({
    this.primaryKeys = const <AppDataDiscoveryFilterTokenValue>[],
    this.taxonomySelections = const <AppDataDiscoveryFilterTaxonomySelection>[],
  });

  final List<AppDataDiscoveryFilterTokenValue> primaryKeys;
  final List<AppDataDiscoveryFilterTaxonomySelection> taxonomySelections;

  bool get isEmpty {
    if (primaryKeys.isNotEmpty) {
      return false;
    }
    return taxonomySelections.every((selection) => selection.termKeys.isEmpty);
  }
}
