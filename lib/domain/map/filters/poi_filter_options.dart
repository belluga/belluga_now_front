import 'package:belluga_now/domain/map/city_poi_category.dart';

class PoiFilterOptions {
  PoiFilterOptions({required this.categories});

  final List<PoiFilterCategory> categories;

  List<PoiFilterCategory> get sortedCategories => List<PoiFilterCategory>
      .from(categories)
    ..sort((a, b) => a.category.index.compareTo(b.category.index));

  Set<String> tagsForCategories(Iterable<CityPoiCategory> selected) {
    if (selected.isEmpty) {
      return const <String>{};
    }
    final normalized = selected.toSet();
    final tags = <String>{};
    for (final option in categories) {
      if (normalized.contains(option.category)) {
        tags.addAll(option.tags);
      }
    }
    return tags;
  }
}

class PoiFilterCategory {
  PoiFilterCategory({required this.category, required Set<String> tags})
      : tags = tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).map(
              (tag) => tag,
            ).toSet();

  final CityPoiCategory category;
  final Set<String> tags;
}
