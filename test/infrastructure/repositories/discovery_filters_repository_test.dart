import 'package:belluga_now/domain/repositories/value_objects/discovery_filters_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/dal/dto/discovery_filters/discovery_filter_catalog_dto.dart';
import 'package:belluga_now/infrastructure/repositories/discovery_filters_repository.dart';
import 'package:belluga_now/infrastructure/services/discovery_filters_backend_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fetchCatalog delegates to backend and returns package catalog',
      () async {
    final backend = _FakeDiscoveryFiltersBackend();
    final repository = DiscoveryFiltersRepository(backend: backend);

    final catalog = await repository.fetchCatalog(
      discoveryFiltersRepoText('public_map.primary'),
    );

    expect(backend.requestedSurfaces, <String>['public_map.primary']);
    expect(catalog.filters.single.key, 'events');
  });
}

class _FakeDiscoveryFiltersBackend implements DiscoveryFiltersBackendContract {
  final List<String> requestedSurfaces = <String>[];

  @override
  Future<DiscoveryFilterCatalogDTO> getCatalog(String surface) async {
    requestedSurfaces.add(surface);
    return DiscoveryFilterCatalogDTO.fromJson(
      <String, dynamic>{
        'surface': surface,
        'filters': <Object?>[
          <String, Object?>{
            'key': 'events',
            'label': 'Eventos',
            'target': 'map_poi',
            'query': <String, Object?>{
              'entities': <String>['event'],
            },
          },
        ],
        'type_options': const <String, Object?>{},
      },
    );
  }
}
