part of 'discovery_filter_catalog.dart';

class DiscoveryFilterCatalogItem {
  const DiscoveryFilterCatalogItem({
    required this.key,
    required this.label,
    required this.entities,
    this.iconKey,
    this.colorHex,
    this.target,
    this.types = const <String>{},
    this.typesByEntity = const <String, Set<String>>{},
    this.taxonomyKeys = const <String>{},
    this.taxonomyValuesByGroup = const <String, Set<String>>{},
    this.taxonomyConfigs = const <String, DiscoveryFilterTaxonomyConfig>{},
  });

  factory DiscoveryFilterCatalogItem.fromJson(Map<String, Object?> json) {
    final query = _readMap(json['query']);
    final taxonomyConfigs = <String, DiscoveryFilterTaxonomyConfig>{};
    final rawTaxonomyConfigs = _readMap(json['taxonomy_configs']);

    for (final entry in rawTaxonomyConfigs.entries) {
      final value = _readMap(entry.value);
      taxonomyConfigs[entry.key] = DiscoveryFilterTaxonomyConfig.fromJson(
        entry.key,
        value,
      );
    }

    final typesByEntity = _readStringSetMap(
      query['types_by_entity'] ?? json['types_by_entity'],
    );
    final flatTypes = _readStringSet(
      query['types'] ?? query['type'] ?? json['types'] ?? json['type'],
    );

    final taxonomyValuesByGroup = _readStringSetMap(
      query['taxonomy'] ??
          query['taxonomy_values_by_group'] ??
          json['taxonomy_values_by_group'],
    );
    final flatTaxonomies = taxonomyValuesByGroup.isNotEmpty
        ? const <String>{}
        : _readStringSet(
            query['taxonomies'] ??
                query['taxonomy'] ??
                json['taxonomies'] ??
                json['taxonomy'],
          );

    return DiscoveryFilterCatalogItem(
      key: _readString(json['key']) ?? _readString(json['id']) ?? '',
      label: _readString(json['label']) ?? '',
      iconKey: _readString(json['icon']) ?? _readString(json['icon_key']),
      colorHex: _readString(json['color']) ?? _readString(json['color_hex']),
      target: _readString(json['target']),
      entities: _readStringSet(
        query['entities'] ??
            query['entity'] ??
            json['entities'] ??
            json['entity'],
      ),
      types: <String>{
        ...flatTypes,
        for (final entry in typesByEntity.values) ...entry,
      },
      typesByEntity: typesByEntity,
      taxonomyKeys: <String>{
        ...flatTaxonomies,
        ...taxonomyValuesByGroup.keys,
        ...taxonomyConfigs.keys,
      },
      taxonomyValuesByGroup: taxonomyValuesByGroup,
      taxonomyConfigs: taxonomyConfigs,
    );
  }

  final String key;
  final String label;
  final String? iconKey;
  final String? colorHex;
  final String? target;
  final Set<String> entities;
  final Set<String> types;
  final Map<String, Set<String>> typesByEntity;
  final Set<String> taxonomyKeys;
  final Map<String, Set<String>> taxonomyValuesByGroup;
  final Map<String, DiscoveryFilterTaxonomyConfig> taxonomyConfigs;

  Map<String, Object?> toJson() {
    final query = <String, Object?>{
      'entities': entities.toList(growable: false),
      if (typesByEntity.isNotEmpty)
        'types_by_entity': typesByEntity.map(
          (key, value) => MapEntry<String, List<String>>(
            key,
            value.toList(growable: false),
          ),
        )
      else
        'types': types.toList(growable: false),
      if (taxonomyValuesByGroup.isNotEmpty)
        'taxonomy': taxonomyValuesByGroup.map(
          (key, value) => MapEntry<String, List<String>>(
            key,
            value.toList(growable: false),
          ),
        )
      else
        'taxonomies': taxonomyKeys.toList(growable: false),
    };

    return <String, Object?>{
      'key': key,
      'label': label,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorHex != null) 'color_hex': colorHex,
      if (target != null) 'target': target,
      'query': query,
      if (taxonomyConfigs.isNotEmpty)
        'taxonomy_configs': taxonomyConfigs.map(
          (key, value) => MapEntry<String, Object?>(key, value.toJson()),
        ),
    };
  }

  bool get isValid => key.isNotEmpty && label.isNotEmpty && entities.isNotEmpty;
}
