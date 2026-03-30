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
    List<PoiFilterKeyValue>? categoryKeyValues,
    this.sourceValue,
    List<PoiFilterTypeValue>? typeValues,
    List<PoiTagValue>? tagValues,
    List<PoiFilterTaxonomyTokenValue>? taxonomyTokenValues,
    this.searchTermValue,
  })  : categoryKeyValues = _normalizeCategoryKeyValues(categoryKeyValues),
        typeValues = _normalizeTypeValues(typeValues),
        tagValues = _normalizeTagValues(tagValues),
        taxonomyTokenValues =
            _normalizeTaxonomyTokenValues(taxonomyTokenValues);

  final CityCoordinate? northEast;
  final CityCoordinate? southWest;
  final CityCoordinate? origin;
  final DistanceInMetersValue? maxDistanceMetersValue;
  final List<PoiFilterKeyValue>? categoryKeyValues;
  final PoiFilterSourceValue? sourceValue;
  final List<PoiFilterTypeValue>? typeValues;
  final List<PoiTagValue>? tagValues;
  final List<PoiFilterTaxonomyTokenValue>? taxonomyTokenValues;
  final PoiFilterSearchTermValue? searchTermValue;

  bool get hasBounds => northEast != null && southWest != null;

  bool matchesCategory(CityPoiCategory category) {
    final keys = categoryKeyValues;
    if (keys == null || keys.isEmpty) {
      return true;
    }
    final normalizedCategory = category.name.trim().toLowerCase();
    return keys
        .map((value) => value.value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .contains(normalizedCategory);
  }

  bool matchesTags(List<PoiTagValue> poiTagValues) {
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
    List<PoiFilterKeyValue>? categoryKeyValues,
    PoiFilterSourceValue? sourceValue,
    List<PoiFilterTypeValue>? typeValues,
    List<PoiTagValue>? tagValues,
    List<PoiFilterTaxonomyTokenValue>? taxonomyTokenValues,
    PoiFilterSearchTermValue? searchTermValue,
  }) {
    return PoiQuery(
      northEast: northEast ?? currentQuery.northEast,
      southWest: southWest ?? currentQuery.southWest,
      origin: origin ?? currentQuery.origin,
      maxDistanceMetersValue:
          maxDistanceMetersValue ?? currentQuery.maxDistanceMetersValue,
      categoryKeyValues: _resolveCategoryKeyValues(
        incoming: categoryKeyValues,
        fallback: currentQuery.categoryKeyValues,
      ),
      sourceValue: sourceValue,
      typeValues: _resolveTypeValues(
        incoming: typeValues,
        fallback: currentQuery.typeValues,
      ),
      tagValues: _resolveTagValues(
        incoming: tagValues,
        fallback: currentQuery.tagValues,
      ),
      taxonomyTokenValues: _resolveTaxonomyTokenValues(
        incoming: taxonomyTokenValues,
        fallback: currentQuery.taxonomyTokenValues,
      ),
      searchTermValue: searchTermValue,
    );
  }

  static List<PoiFilterKeyValue>? _normalizeCategoryKeyValues(
    List<PoiFilterKeyValue>? values,
  ) {
    if (values == null) {
      return null;
    }
    final normalized = values.toSet().toList(growable: false);
    if (normalized.isEmpty) {
      return null;
    }
    return List<PoiFilterKeyValue>.unmodifiable(normalized);
  }

  static List<PoiFilterTypeValue>? _normalizeTypeValues(
    List<PoiFilterTypeValue>? values,
  ) {
    if (values == null) {
      return null;
    }
    final normalized = values.toSet().toList(growable: false);
    if (normalized.isEmpty) {
      return null;
    }
    return List<PoiFilterTypeValue>.unmodifiable(normalized);
  }

  static List<PoiTagValue>? _normalizeTagValues(List<PoiTagValue>? values) {
    if (values == null) {
      return null;
    }
    final normalized = values.toSet().toList(growable: false);
    if (normalized.isEmpty) {
      return null;
    }
    return List<PoiTagValue>.unmodifiable(normalized);
  }

  static List<PoiFilterTaxonomyTokenValue>? _normalizeTaxonomyTokenValues(
    List<PoiFilterTaxonomyTokenValue>? values,
  ) {
    if (values == null) {
      return null;
    }
    final normalized = values.toSet().toList(growable: false);
    if (normalized.isEmpty) {
      return null;
    }
    return List<PoiFilterTaxonomyTokenValue>.unmodifiable(normalized);
  }

  static List<PoiFilterKeyValue>? _resolveCategoryKeyValues({
    required List<PoiFilterKeyValue>? incoming,
    required List<PoiFilterKeyValue>? fallback,
  }) {
    if (incoming == null) {
      return fallback;
    }
    return _normalizeCategoryKeyValues(incoming);
  }

  static List<PoiFilterTypeValue>? _resolveTypeValues({
    required List<PoiFilterTypeValue>? incoming,
    required List<PoiFilterTypeValue>? fallback,
  }) {
    if (incoming == null) {
      return fallback;
    }
    return _normalizeTypeValues(incoming);
  }

  static List<PoiTagValue>? _resolveTagValues({
    required List<PoiTagValue>? incoming,
    required List<PoiTagValue>? fallback,
  }) {
    if (incoming == null) {
      return fallback;
    }
    return _normalizeTagValues(incoming);
  }

  static List<PoiFilterTaxonomyTokenValue>? _resolveTaxonomyTokenValues({
    required List<PoiFilterTaxonomyTokenValue>? incoming,
    required List<PoiFilterTaxonomyTokenValue>? fallback,
  }) {
    if (incoming == null) {
      return fallback;
    }
    return _normalizeTaxonomyTokenValues(incoming);
  }
}
