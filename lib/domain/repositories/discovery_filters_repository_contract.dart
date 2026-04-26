import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/domain/repositories/value_objects/discovery_filters_repository_contract_values.dart';

typedef DiscoveryFiltersRepoText = DiscoveryFiltersRepositoryContractTextValue;

abstract class DiscoveryFiltersRepositoryContract {
  Future<DiscoveryFilterCatalog> fetchCatalog(DiscoveryFiltersRepoText surface);
}
