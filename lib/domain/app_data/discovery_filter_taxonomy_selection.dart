import 'package:belluga_now/domain/app_data/value_object/app_data_discovery_filter_token_value.dart';

class AppDataDiscoveryFilterTaxonomySelection {
  const AppDataDiscoveryFilterTaxonomySelection({
    required this.taxonomyKey,
    this.termKeys = const <AppDataDiscoveryFilterTokenValue>[],
  });

  final AppDataDiscoveryFilterTokenValue taxonomyKey;
  final List<AppDataDiscoveryFilterTokenValue> termKeys;

  bool get isEmpty => taxonomyKey.value.isEmpty || termKeys.isEmpty;
}
