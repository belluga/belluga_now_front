import 'package:belluga_now/domain/map/city_poi_category.dart';

class PoiFilterOptions {
  PoiFilterOptions({
    required this.categories,
    this.taxonomyGroups = const <PoiFilterTaxonomyGroup>[],
  });

  final List<PoiFilterCategory> categories;
  final List<PoiFilterTaxonomyGroup> taxonomyGroups;

  List<PoiFilterCategory> get sortedCategories =>
      List<PoiFilterCategory>.from(categories);

  Set<String> tagsForCategories(Iterable<CityPoiCategory> selected) {
    if (selected.isEmpty) {
      return const <String>{};
    }
    final normalized = selected.toSet();
    final tags = <String>{};
    for (final option in categories) {
      if (option.category != null && normalized.contains(option.category)) {
        tags.addAll(option.tags);
      }
    }
    return tags;
  }
}

class PoiFilterCategory {
  PoiFilterCategory({
    this.category,
    required Set<String> tags,
    String? key,
    String? label,
    this.imageUri,
    this.count = 0,
  })  : key = _resolveKey(key, category),
        label = _resolveLabel(label, key, category),
        tags = tags
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .map(
              (tag) => tag,
            )
            .toSet();

  final String key;
  final String label;
  final String? imageUri;
  final int count;
  final CityPoiCategory? category;
  final Set<String> tags;

  static String _resolveKey(String? rawKey, CityPoiCategory? category) {
    final normalized = (rawKey ?? '').trim().toLowerCase();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    if (category == null) {
      return '';
    }
    return category.name;
  }

  static String _resolveLabel(
    String? rawLabel,
    String? rawKey,
    CityPoiCategory? category,
  ) {
    final trimmed = (rawLabel ?? '').trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    if (category != null) {
      return switch (category) {
        CityPoiCategory.restaurant => 'Restaurantes',
        CityPoiCategory.beach => 'Praias',
        CityPoiCategory.nature => 'Natureza',
        CityPoiCategory.culture => 'Cultura',
        CityPoiCategory.monument => 'Histórico',
        CityPoiCategory.church => 'Histórico',
        CityPoiCategory.health => 'Saúde',
        CityPoiCategory.lodging => 'Hospedagem',
        CityPoiCategory.attraction => 'Atrações',
        CityPoiCategory.sponsor => 'Parceiros',
      };
    }
    final key = (rawKey ?? '').trim();
    if (key.isEmpty) {
      return 'Filtro';
    }
    return key;
  }
}

class PoiFilterTaxonomyGroup {
  const PoiFilterTaxonomyGroup({
    required this.type,
    required this.label,
    required this.terms,
  });

  final String type;
  final String label;
  final List<PoiFilterTaxonomyTerm> terms;
}

class PoiFilterTaxonomyTerm {
  const PoiFilterTaxonomyTerm({
    required this.type,
    required this.value,
    required this.label,
    required this.count,
  });

  final String type;
  final String value;
  final String label;
  final int count;

  String get token =>
      '${type.trim().toLowerCase()}:${value.trim().toLowerCase()}';
}
