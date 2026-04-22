import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/domain/repositories/discovery_filters_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/discovery_filters/laravel_discovery_filters_http_service.dart';
import 'package:belluga_now/infrastructure/services/discovery_filters_backend_contract.dart';

class DiscoveryFiltersRepository implements DiscoveryFiltersRepositoryContract {
  DiscoveryFiltersRepository({
    DiscoveryFiltersBackendContract? backend,
  }) : _backend = backend ?? LaravelDiscoveryFiltersHttpService();

  final DiscoveryFiltersBackendContract _backend;

  @override
  Future<DiscoveryFilterCatalog> fetchCatalog(
    DiscoveryFiltersRepoText surface,
  ) async {
    final dto = await _backend.getCatalog(surface.value);
    return dto.toDomain();
  }
}
