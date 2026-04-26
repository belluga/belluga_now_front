import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';

class DiscoveryFilterCatalogDTO {
  const DiscoveryFilterCatalogDTO({
    required this.surface,
    required this.filters,
    required this.typeOptionsByEntity,
    required this.taxonomyOptionsByKey,
  });

  factory DiscoveryFilterCatalogDTO.fromJson(Map<String, dynamic> json) {
    final catalog = DiscoveryFilterCatalog.fromJson(
      Map<String, Object?>.from(json),
    );

    return DiscoveryFilterCatalogDTO(
      surface: catalog.surface,
      filters: catalog.filters,
      typeOptionsByEntity: catalog.typeOptionsByEntity,
      taxonomyOptionsByKey: catalog.taxonomyOptionsByKey,
    );
  }

  final String surface;
  final List<DiscoveryFilterCatalogItem> filters;
  final Map<String, List<DiscoveryFilterTypeOption>> typeOptionsByEntity;
  final Map<String, DiscoveryFilterTaxonomyGroupOption> taxonomyOptionsByKey;

  DiscoveryFilterCatalog toDomain() {
    return DiscoveryFilterCatalog(
      surface: surface,
      filters: filters,
      typeOptionsByEntity: typeOptionsByEntity,
      taxonomyOptionsByKey: taxonomyOptionsByKey,
    );
  }
}
