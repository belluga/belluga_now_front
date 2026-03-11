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
    List<String> parseStringList(dynamic raw) {
      if (raw is! List) {
        return const <String>[];
      }
      return raw
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }

    final categories = parseStringList(json['categories']);
    final fallbackCategoryKeys = parseStringList(json['category_keys']);
    final taxonomy = parseStringList(json['taxonomy']);
    final tags = parseStringList(json['tags']);
    final source = json['source']?.toString().trim();
    final types = parseStringList(json['types']);

    return MapFilterCategoryQueryDTO(
      categoryKeys: categories.isNotEmpty ? categories : fallbackCategoryKeys,
      taxonomy: taxonomy,
      tags: tags,
      source: source == null || source.isEmpty ? null : source,
      types: types,
    );
  }
}
