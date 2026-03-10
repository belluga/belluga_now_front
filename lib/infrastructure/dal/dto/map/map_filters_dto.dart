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
  });

  final String key;
  final String label;
  final int count;
  final String? imageUri;

  factory MapFilterCategoryDTO.fromJson(Map<String, dynamic> json) {
    final rawImageUri = (json['image_uri'] ?? '').toString().trim();
    return MapFilterCategoryDTO(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      imageUri: rawImageUri.isEmpty ? null : rawImageUri,
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
