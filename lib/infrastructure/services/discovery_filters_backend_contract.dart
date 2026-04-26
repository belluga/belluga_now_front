import 'package:belluga_now/infrastructure/dal/dto/discovery_filters/discovery_filter_catalog_dto.dart';

abstract class DiscoveryFiltersBackendContract {
  Future<DiscoveryFilterCatalogDTO> getCatalog(String surface);
}
