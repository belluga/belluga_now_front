import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_search_term_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';

class PoiQuery {
  PoiQuery({
    this.northEast,
    this.southWest,
    this.origin,
    this.maxDistanceMetersValue,
    Set<CityPoiCategory>? categories,
    Set<PoiFilterKeyValue>? categoryKeyValues,
    this.sourceValue,
    Set<PoiFilterTypeValue>? typeValues,
    Set<PoiTagValue>? tagValues,
    Set<PoiFilterTaxonomyTokenValue>? taxonomyTokenValues,
    this.searchTermValue,
  })  : categories = _toUnmodifiableSet(categories),
        categoryKeyValues = _toUnmodifiableSet(categoryKeyValues),
        typeValues = _toUnmodifiableSet(typeValues),
        tagValues = _toUnmodifiableSet(tagValues),
        taxonomyTokenValues = _toUnmodifiableSet(taxonomyTokenValues);

  final CityCoordinate? northEast;
  final CityCoordinate? southWest;
  final CityCoordinate? origin;
  final DistanceInMetersValue? maxDistanceMetersValue;
  final Set<CityPoiCategory>? categories;
  final Set<PoiFilterKeyValue>? categoryKeyValues;
  final PoiFilterSourceValue? sourceValue;
  final Set<PoiFilterTypeValue>? typeValues;
  final Set<PoiTagValue>? tagValues;
  final Set<PoiFilterTaxonomyTokenValue>? taxonomyTokenValues;
  final PoiFilterSearchTermValue? searchTermValue;

  double? get maxDistanceMeters => maxDistanceMetersValue?.value;
  Set<String>? get categoryKeys => _readValueSet(categoryKeyValues);
  String? get source {
    final raw = sourceValue?.value;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }

  Set<String>? get types => _readValueSet(typeValues);
  Set<String>? get tags => _readValueSet(tagValues);
  Set<String>? get taxonomy => _readValueSet(taxonomyTokenValues);
  String? get searchTerm {
    final raw = searchTermValue?.value;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }

  bool get hasBounds => northEast != null && southWest != null;

  bool matchesCategory(CityPoiCategory category) {
    final set = categories;
    if (set == null || set.isEmpty) {
      return true;
    }
    return set.contains(category);
  }

  bool matchesTags(Iterable<PoiTagValue> poiTagValues) {
    final set = tagValues;
    if (set == null || set.isEmpty) {
      return true;
    }
    if (poiTagValues.isEmpty) {
      return false;
    }

    final normalizedPoiTags = poiTagValues
        .map((value) => value.value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    return set.every(
      (tag) => normalizedPoiTags.contains(tag.value.trim().toLowerCase()),
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
    DistanceInMetersValue? maxDistanceMetersValue,
    Iterable<CityPoiCategory>? categories,
    Iterable<PoiFilterKeyValue>? categoryKeyValues,
    PoiFilterSourceValue? sourceValue,
    Iterable<PoiFilterTypeValue>? typeValues,
    Iterable<PoiTagValue>? tagValues,
    Iterable<PoiFilterTaxonomyTokenValue>? taxonomyTokenValues,
    PoiFilterSearchTermValue? searchTermValue,
  }) {
    return PoiQuery(
      northEast: northEast ?? currentQuery.northEast,
      southWest: southWest ?? currentQuery.southWest,
      origin: origin ?? currentQuery.origin,
      maxDistanceMetersValue:
          maxDistanceMetersValue ?? currentQuery.maxDistanceMetersValue,
      categories: _resolveSet(
        incoming: categories,
        fallback: currentQuery.categories,
      ),
      categoryKeyValues: _resolveSet(
        incoming: categoryKeyValues,
        fallback: currentQuery.categoryKeyValues,
      ),
      sourceValue: sourceValue,
      typeValues: _resolveSet(
        incoming: typeValues,
        fallback: currentQuery.typeValues,
      ),
      tagValues: _resolveSet(
        incoming: tagValues,
        fallback: currentQuery.tagValues,
      ),
      taxonomyTokenValues: _resolveSet(
        incoming: taxonomyTokenValues,
        fallback: currentQuery.taxonomyTokenValues,
      ),
      searchTermValue: searchTermValue,
    );
  }

  static Set<T>? _toUnmodifiableSet<T>(Set<T>? values) {
    if (values == null) {
      return null;
    }
    return Set<T>.unmodifiable(values);
  }

  static Set<T>? _resolveSet<T>({
    required Iterable<T>? incoming,
    required Set<T>? fallback,
  }) {
    if (incoming == null) {
      return fallback;
    }
    final normalized = incoming.toSet();
    if (normalized.isEmpty) {
      return null;
    }
    return Set<T>.unmodifiable(normalized);
  }

  static Set<String>? _readValueSet<T>(Iterable<T>? values) {
    if (values == null) {
      return null;
    }
    final normalized = values
        .map((value) {
          if (value is PoiFilterKeyValue) {
            return value.value;
          }
          if (value is PoiFilterTypeValue) {
            return value.value;
          }
          if (value is PoiTagValue) {
            return value.value;
          }
          if (value is PoiFilterTaxonomyTokenValue) {
            return value.value;
          }
          return '';
        })
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    return Set<String>.unmodifiable(normalized);
  }
}
