import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_search_term_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';

typedef PoiQueryRawString = String;
typedef PoiQueryRawMeters = double;
typedef PoiQueryRawToken = String;
typedef PoiQueryRawTokenSet = Set<PoiQueryRawToken>;
typedef PoiQueryRawTokenIterable = Iterable<PoiQueryRawToken>;
typedef PoiQueryDynamicValue = dynamic;
typedef PoiQueryDynamicIterable = Iterable<PoiQueryDynamicValue>;

class PoiQuery {
  PoiQuery({
    this.northEast,
    this.southWest,
    this.origin,
    PoiQueryRawMeters? maxDistanceMeters,
    this.categories,
    PoiQueryRawTokenSet? categoryKeys,
    PoiQueryRawString? source,
    PoiQueryRawTokenSet? types,
    PoiQueryRawTokenSet? tags,
    PoiQueryRawTokenSet? taxonomy,
    PoiQueryRawString? searchTerm,
  })  : maxDistanceMetersValue = _buildDistanceValue(maxDistanceMeters),
        categoryKeyValues = _buildCategoryKeyValues(categoryKeys),
        sourceValue = _buildSourceValue(source),
        typeValues = _buildTypeValues(types),
        tagValues = _buildTagValues(tags),
        taxonomyTokenValues = _buildTaxonomyValues(taxonomy),
        searchTermValue = _buildSearchTermValue(searchTerm);

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
  Set<String>? get categoryKeys => _readStringSet(categoryKeyValues);
  String? get source => _readNullableValue(sourceValue);
  Set<String>? get types => _readStringSet(typeValues);
  Set<String>? get tags => _readStringSet(tagValues);
  Set<String>? get taxonomy => _readStringSet(taxonomyTokenValues);
  String? get searchTerm => _readNullableValue(searchTermValue);

  bool get hasBounds => northEast != null && southWest != null;

  bool matchesCategory(CityPoiCategory category) {
    final set = categories;
    if (set == null || set.isEmpty) {
      return true;
    }
    return set.contains(category);
  }

  bool matchesTags(PoiQueryRawTokenIterable poiTags) {
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
    PoiQueryRawMeters? maxDistanceMeters,
    Iterable<CityPoiCategory>? categories,
    PoiQueryRawTokenIterable? categoryKeys,
    PoiQueryRawString? source,
    PoiQueryRawTokenIterable? types,
    PoiQueryRawTokenIterable? tags,
    PoiQueryRawTokenIterable? taxonomy,
    PoiQueryRawString? searchTerm,
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

  static DistanceInMetersValue? _buildDistanceValue(PoiQueryRawMeters? raw) {
    if (raw == null) {
      return null;
    }
    final value = DistanceInMetersValue()..parse(raw.toString());
    return value;
  }

  static Set<PoiFilterKeyValue>? _buildCategoryKeyValues(
    PoiQueryRawTokenIterable? rawValues,
  ) {
    return _buildStringValueSet(
      rawValues,
      () => PoiFilterKeyValue(),
    );
  }

  static PoiFilterSourceValue? _buildSourceValue(PoiQueryRawString? raw) {
    final normalized = raw?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = PoiFilterSourceValue()..parse(normalized);
    return value;
  }

  static Set<PoiFilterTypeValue>? _buildTypeValues(
    PoiQueryRawTokenIterable? rawValues,
  ) {
    return _buildStringValueSet(
      rawValues,
      () => PoiFilterTypeValue(),
    );
  }

  static Set<PoiTagValue>? _buildTagValues(
      PoiQueryRawTokenIterable? rawValues) {
    return _buildStringValueSet(
      rawValues,
      () => PoiTagValue(),
    );
  }

  static Set<PoiFilterTaxonomyTokenValue>? _buildTaxonomyValues(
    PoiQueryRawTokenIterable? rawValues,
  ) {
    return _buildStringValueSet(
      rawValues,
      () => PoiFilterTaxonomyTokenValue(),
    );
  }

  static PoiFilterSearchTermValue? _buildSearchTermValue(
      PoiQueryRawString? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = PoiFilterSearchTermValue()..parse(normalized);
    return value;
  }

  static Set<T>? _buildStringValueSet<T>(
    PoiQueryRawTokenIterable? rawValues,
    T Function() createValue,
  ) {
    if (rawValues == null) {
      return null;
    }
    final values = <T>{};
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = createValue();
      if (value is PoiFilterKeyValue) {
        value.parse(normalized);
        values.add(value as T);
      } else if (value is PoiFilterTypeValue) {
        value.parse(normalized);
        values.add(value as T);
      } else if (value is PoiTagValue) {
        value.parse(normalized);
        values.add(value as T);
      } else if (value is PoiFilterTaxonomyTokenValue) {
        value.parse(normalized);
        values.add(value as T);
      }
    }
    return Set<T>.unmodifiable(values);
  }

  static Set<String>? _readStringSet(PoiQueryDynamicIterable? values) {
    if (values == null) {
      return null;
    }
    return Set<String>.unmodifiable(
      values
          .map((value) => value.value as String?)
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );
  }

  static String? _readNullableValue(PoiQueryDynamicValue valueObject) {
    final raw = valueObject?.value as String?;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }
}
