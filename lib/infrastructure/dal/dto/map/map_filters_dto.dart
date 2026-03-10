class MapFiltersDTO {
  const MapFiltersDTO({
    required this.categories,
    required this.tags,
    required this.taxonomyTerms,
  });

  final List<MapFilterCategoryDTO> categories;
  final List<MapFilterTagDTO> tags;
  final List<MapFilterTaxonomyTermDTO> taxonomyTerms;

  factory MapFiltersDTO.fromJson(Map<String, dynamic> json) {
    return MapFiltersDTO(
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MapFilterCategoryDTO.fromJson)
          .toList(growable: false),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MapFilterTagDTO.fromJson)
          .toList(growable: false),
      taxonomyTerms: (json['taxonomy_terms'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MapFilterTaxonomyTermDTO.fromJson)
          .toList(growable: false),
    );
  }
}

class MapFilterCategoryDTO {
  const MapFilterCategoryDTO({
    required this.key,
    required this.label,
    required this.count,
    required this.imageUri,
    required this.query,
  });

  final String key;
  final String label;
  final int count;
  final String? imageUri;
  final MapFilterCategoryQueryDTO query;

  factory MapFilterCategoryDTO.fromJson(Map<String, dynamic> json) {
    final rawImageUri = (json['image_uri'] ?? '').toString().trim();
    final rawQuery = json['query'];
    final queryMap = rawQuery is Map
        ? Map<String, dynamic>.from(rawQuery)
        : const <String, dynamic>{};
    return MapFilterCategoryDTO(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      imageUri: rawImageUri.isEmpty ? null : rawImageUri,
      query: MapFilterCategoryQueryDTO.fromJson(queryMap),
    );
  }
}

class MapFilterCategoryQueryDTO {
  const MapFilterCategoryQueryDTO({
    required this.categoryKeys,
    required this.taxonomy,
    required this.tags,
    this.source,
    required this.types,
  });

  final List<String> categoryKeys;
  final List<String> taxonomy;
  final List<String> tags;
  final String? source;
  final List<String> types;

  bool get isEmpty =>
      categoryKeys.isEmpty &&
      taxonomy.isEmpty &&
      tags.isEmpty &&
      (source == null || source!.trim().isEmpty) &&
      types.isEmpty;

  factory MapFilterCategoryQueryDTO.fromJson(Map<String, dynamic> json) {
    List<String> _parseStringList(dynamic raw) {
      if (raw is! List) {
        return const <String>[];
      }
      return raw
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }

    final categories = _parseStringList(json['categories']);
    final fallbackCategoryKeys = _parseStringList(json['category_keys']);
    final taxonomy = _parseStringList(json['taxonomy']);
    final tags = _parseStringList(json['tags']);
    final source = json['source']?.toString().trim();
    final types = _parseStringList(json['types']);

    return MapFilterCategoryQueryDTO(
      categoryKeys:
          categories.isNotEmpty ? categories : fallbackCategoryKeys,
      taxonomy: taxonomy,
      tags: tags,
      source: source == null || source.isEmpty ? null : source,
      types: types,
    );
  }
}

class MapFilterTagDTO {
  const MapFilterTagDTO({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;

  factory MapFilterTagDTO.fromJson(Map<String, dynamic> json) {
    return MapFilterTagDTO(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MapFilterTaxonomyTermDTO {
  const MapFilterTaxonomyTermDTO({
    required this.type,
    required this.value,
    required this.label,
    required this.count,
  });

  final String type;
  final String value;
  final String label;
  final int count;

  factory MapFilterTaxonomyTermDTO.fromJson(Map<String, dynamic> json) {
    return MapFilterTaxonomyTermDTO(
      type: (json['type'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
