import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';

class DiscoveryFilterCatalogDTO {
  const DiscoveryFilterCatalogDTO({
    required this.surface,
    required this.filters,
    required this.typeOptionsByEntity,
    required this.taxonomyOptionsByKey,
  });

  factory DiscoveryFilterCatalogDTO.fromJson(Map<String, dynamic> json) {
    final filters = _normalizeMapList(json['filters'])
        .map(DiscoveryFilterCatalogItem.fromJson)
        .where((filter) => filter.isValid)
        .toList(growable: false);
    final typeOptionsByEntity = <String, List<DiscoveryFilterTypeOption>>{};
    final rawTypeOptions = _normalizeMap(json['type_options']);

    for (final entry in rawTypeOptions.entries) {
      final entity = entry.key.trim().toLowerCase();
      if (entity.isEmpty) {
        continue;
      }

      final options = _normalizeMapList(entry.value)
          .map(DiscoveryFilterTypeOption.fromJson)
          .where((option) => option.isValid)
          .toList(growable: false);
      if (options.isNotEmpty) {
        typeOptionsByEntity[entity] = options;
      }
    }
    final taxonomyOptionsByKey = <String, DiscoveryFilterTaxonomyGroupOption>{};
    final rawTaxonomyOptions = _normalizeMap(json['taxonomy_options']);

    for (final entry in rawTaxonomyOptions.entries) {
      final taxonomyKey = entry.key.trim().toLowerCase();
      if (taxonomyKey.isEmpty) {
        continue;
      }

      final option = DiscoveryFilterTaxonomyGroupOption.fromJson(
        taxonomyKey,
        _normalizeMap(entry.value),
      );
      if (option.isValid) {
        taxonomyOptionsByKey[taxonomyKey] = option;
      }
    }

    return DiscoveryFilterCatalogDTO(
      surface: (json['surface'] ?? '').toString().trim(),
      filters: filters,
      typeOptionsByEntity: typeOptionsByEntity,
      taxonomyOptionsByKey: taxonomyOptionsByKey,
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

  static List<Map<String, Object?>> _normalizeMapList(Object? raw) {
    if (raw is! Iterable) {
      return const <Map<String, Object?>>[];
    }

    return raw
        .map(_normalizeMap)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, Object?> _normalizeMap(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry<String, Object?>(key.toString(), value),
      );
    }
    return const <String, Object?>{};
  }
}
