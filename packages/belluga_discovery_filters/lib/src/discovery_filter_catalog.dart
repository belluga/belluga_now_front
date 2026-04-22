import 'discovery_filter_policy.dart';
import 'discovery_filter_entity_registry.dart';

part 'discovery_filter_catalog_item.dart';
part 'discovery_filter_taxonomy_config.dart';
part 'discovery_filter_taxonomy_group_option.dart';
part 'discovery_filter_taxonomy_term_option.dart';

class DiscoveryFilterCatalog {
  const DiscoveryFilterCatalog({
    required this.surface,
    this.filters = const <DiscoveryFilterCatalogItem>[],
    this.typeOptionsByEntity =
        const <String, List<DiscoveryFilterTypeOption>>{},
    this.taxonomyOptionsByKey =
        const <String, DiscoveryFilterTaxonomyGroupOption>{},
  });

  factory DiscoveryFilterCatalog.fromJson(Map<String, Object?> json) {
    final filters = _readMapList(json['filters'])
        .map(DiscoveryFilterCatalogItem.fromJson)
        .where((item) => item.isValid)
        .toList(growable: false);
    final typeOptionsByEntity = <String, List<DiscoveryFilterTypeOption>>{};
    final rawTypeOptions = _readMap(json['type_options']);

    for (final entry in rawTypeOptions.entries) {
      final entity = _readString(entry.key);
      if (entity == null) {
        continue;
      }

      final options = _readMapList(entry.value)
          .map(DiscoveryFilterTypeOption.fromJson)
          .where((option) => option.isValid)
          .toList(growable: false);
      if (options.isNotEmpty) {
        typeOptionsByEntity[entity] = options;
      }
    }
    final taxonomyOptionsByKey = <String, DiscoveryFilterTaxonomyGroupOption>{};
    final rawTaxonomyOptions = _readMap(json['taxonomy_options']);

    for (final entry in rawTaxonomyOptions.entries) {
      final taxonomyKey = _readString(entry.key);
      if (taxonomyKey == null) {
        continue;
      }

      final option = DiscoveryFilterTaxonomyGroupOption.fromJson(
        taxonomyKey,
        _readMap(entry.value),
      );
      if (option.isValid) {
        taxonomyOptionsByKey[taxonomyKey] = option;
      }
    }

    return DiscoveryFilterCatalog(
      surface: _readString(json['surface']) ?? '',
      filters: filters,
      typeOptionsByEntity: typeOptionsByEntity,
      taxonomyOptionsByKey: taxonomyOptionsByKey,
    );
  }

  final String surface;
  final List<DiscoveryFilterCatalogItem> filters;
  final Map<String, List<DiscoveryFilterTypeOption>> typeOptionsByEntity;
  final Map<String, DiscoveryFilterTaxonomyGroupOption> taxonomyOptionsByKey;

  bool get isEmpty =>
      filters.isEmpty &&
      typeOptionsByEntity.isEmpty &&
      taxonomyOptionsByKey.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'surface': surface,
        'filters':
            filters.map((filter) => filter.toJson()).toList(growable: false),
        'type_options': typeOptionsByEntity.map(
          (key, value) => MapEntry<String, Object?>(
            key,
            value.map((option) => option.toJson()).toList(growable: false),
          ),
        ),
        'taxonomy_options': taxonomyOptionsByKey.map(
          (key, value) => MapEntry<String, Object?>(key, value.toJson()),
        ),
      };
}

Map<String, Object?> _readMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, value) => MapEntry<String, Object?>(key.toString(), value),
    );
  }
  return const <String, Object?>{};
}

List<Map<String, Object?>> _readMapList(Object? value) {
  if (value is! Iterable) {
    return const <Map<String, Object?>>[];
  }

  return value
      .map(_readMap)
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

String? _readString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool? _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return switch (value.trim().toLowerCase()) {
      'true' || '1' || 'yes' => true,
      'false' || '0' || 'no' => false,
      _ => null,
    };
  }
  return null;
}

Set<String> _readStringSet(Object? value) {
  if (value == null) {
    return const <String>{};
  }
  if (value is String) {
    final normalized = _readString(value);
    return normalized == null ? const <String>{} : <String>{normalized};
  }
  if (value is Iterable) {
    return value.map(_readString).whereType<String>().toSet();
  }
  return const <String>{};
}

Map<String, Set<String>> _readStringSetMap(Object? value) {
  if (value is! Map) {
    return const <String, Set<String>>{};
  }

  final result = <String, Set<String>>{};
  for (final entry in value.entries) {
    final key = _readString(entry.key);
    if (key == null) {
      continue;
    }

    final values = _readStringSet(entry.value);
    result[key] = values;
  }
  return result;
}
