export 'discovery_filters_repository_contract_text_value.dart';

import 'discovery_filters_repository_contract_text_value.dart';

DiscoveryFiltersRepositoryContractTextValue discoveryFiltersRepoText(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = false,
}) {
  if (raw is DiscoveryFiltersRepositoryContractTextValue) {
    return raw;
  }
  return DiscoveryFiltersRepositoryContractTextValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}
