import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

class PoiQuery {
  const PoiQuery({
    this.northEast,
    this.southWest,
    this.origin,
    this.maxDistanceMeters,
    this.categories,
    this.categoryKeys,
    this.source,
    this.types,
    this.tags,
    this.taxonomy,
    this.searchTerm,
  });

  final CityCoordinate? northEast;
  final CityCoordinate? southWest;
  final CityCoordinate? origin;
  final double? maxDistanceMeters;
  final Set<CityPoiCategory>? categories;
  final Set<String>? categoryKeys;
  final String? source;
  final Set<String>? types;
  final Set<String>? tags;
  final Set<String>? taxonomy;
  final String? searchTerm;

  bool get hasBounds => northEast != null && southWest != null;

  bool matchesCategory(CityPoiCategory category) {
    final set = categories;
    if (set == null || set.isEmpty) {
      return true;
    }
    return set.contains(category);
  }

  bool matchesTags(Iterable<String> poiTags) {
    final set = tags;
    if (set == null || set.isEmpty) {
      return true;
    }
    if (poiTags.isEmpty) {
      return false;
    }
    return set.every(
      (tag) => poiTags.any(
        (poiTag) => poiTag.toLowerCase() == tag.toLowerCase(),
      ),
    );
  }

  bool containsCoordinate(CityCoordinate coordinate) {
    if (!hasBounds) {
      return true;
    }
    final north = northEast!.latitude;
    final east = northEast!.longitude;
    final south = southWest!.latitude;
    final west = southWest!.longitude;

    final lat = coordinate.latitude;
    final lon = coordinate.longitude;

    final withinLat = lat <= north && lat >= south;
    final withinLon =
        west <= east ? lon >= west && lon <= east : lon >= west || lon <= east;

    return withinLat && withinLon;
  }

  factory PoiQuery.compose({
    required PoiQuery currentQuery,
    CityCoordinate? northEast,
    CityCoordinate? southWest,
    CityCoordinate? origin,
    double? maxDistanceMeters,
    Iterable<CityPoiCategory>? categories,
    Iterable<String>? categoryKeys,
    String? source,
    Iterable<String>? types,
    Iterable<String>? tags,
    Iterable<String>? taxonomy,
    String? searchTerm,
  }) {
    Set<CityPoiCategory>? resolvedCategories;
    if (categories == null) {
      resolvedCategories = currentQuery.categories;
    } else if (categories.isEmpty) {
      resolvedCategories = null;
    } else {
      resolvedCategories =
          Set<CityPoiCategory>.unmodifiable(categories.toSet());
    }

    Set<String>? resolvedCategoryKeys;
    if (categoryKeys == null) {
      resolvedCategoryKeys = currentQuery.categoryKeys;
    } else if (categoryKeys.isEmpty) {
      resolvedCategoryKeys = null;
    } else {
      resolvedCategoryKeys = Set<String>.unmodifiable(
        categoryKeys.map((key) => key.trim().toLowerCase()).toSet(),
      );
    }

    Set<String>? resolvedTags;
    if (tags == null) {
      resolvedTags = currentQuery.tags;
    } else if (tags.isEmpty) {
      resolvedTags = null;
    } else {
      resolvedTags = Set<String>.unmodifiable(
        tags.map((tag) => tag.toLowerCase()).toSet(),
      );
    }

    Set<String>? resolvedTaxonomy;
    if (taxonomy == null) {
      resolvedTaxonomy = currentQuery.taxonomy;
    } else if (taxonomy.isEmpty) {
      resolvedTaxonomy = null;
    } else {
      resolvedTaxonomy = Set<String>.unmodifiable(
        taxonomy.map((token) => token.trim().toLowerCase()).toSet(),
      );
    }

    Set<String>? resolvedTypes;
    if (types == null) {
      resolvedTypes = currentQuery.types;
    } else if (types.isEmpty) {
      resolvedTypes = null;
    } else {
      resolvedTypes = Set<String>.unmodifiable(
        types
            .map((type) => type.trim().toLowerCase())
            .where((type) => type.isNotEmpty)
            .toSet(),
      );
    }

    final resolvedSource = source == null
        ? currentQuery.source
        : (source.trim().isEmpty ? null : source.trim().toLowerCase());

    final sanitizedSearch = searchTerm == null
        ? currentQuery.searchTerm
        : (searchTerm.trim().isEmpty ? null : searchTerm.trim());

    return PoiQuery(
      northEast: northEast ?? currentQuery.northEast,
      southWest: southWest ?? currentQuery.southWest,
      origin: origin ?? currentQuery.origin,
      maxDistanceMeters: maxDistanceMeters ?? currentQuery.maxDistanceMeters,
      categories: resolvedCategories,
      categoryKeys: resolvedCategoryKeys,
      source: resolvedSource,
      types: resolvedTypes,
      tags: resolvedTags,
      taxonomy: resolvedTaxonomy,
      searchTerm: sanitizedSearch,
    );
  }
}
