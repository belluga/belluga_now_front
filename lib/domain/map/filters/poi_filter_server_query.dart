import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';

class PoiFilterServerQuery {
  PoiFilterServerQuery({
    this.sourceValue,
    Set<PoiFilterTypeValue>? typeValues,
    Set<PoiFilterKeyValue>? categoryKeyValues,
    Set<PoiFilterTaxonomyTokenValue>? taxonomyTokenValues,
    Set<PoiTagValue>? tagValues,
  })  : typeValues = Set<PoiFilterTypeValue>.unmodifiable(
          typeValues ?? const <PoiFilterTypeValue>{},
        ),
        categoryKeyValues = Set<PoiFilterKeyValue>.unmodifiable(
          categoryKeyValues ?? const <PoiFilterKeyValue>{},
        ),
        taxonomyTokenValues = Set<PoiFilterTaxonomyTokenValue>.unmodifiable(
          taxonomyTokenValues ?? const <PoiFilterTaxonomyTokenValue>{},
        ),
        tagValues = Set<PoiTagValue>.unmodifiable(
          tagValues ?? const <PoiTagValue>{},
        );

  final PoiFilterSourceValue? sourceValue;
  final Set<PoiFilterTypeValue> typeValues;
  final Set<PoiFilterKeyValue> categoryKeyValues;
  final Set<PoiFilterTaxonomyTokenValue> taxonomyTokenValues;
  final Set<PoiTagValue> tagValues;

  String? get source => _readNullableValue(sourceValue);

  Set<String> get types => _readTypeValues(typeValues);

  Set<String> get categoryKeys => _readCategoryKeyValues(categoryKeyValues);

  Set<String> get taxonomy => _readTaxonomyValues(taxonomyTokenValues);

  Set<String> get tags => _readTagValues(tagValues);

  bool get isEmpty =>
      sourceValue == null &&
      typeValues.isEmpty &&
      categoryKeyValues.isEmpty &&
      taxonomyTokenValues.isEmpty &&
      tagValues.isEmpty;

  static Set<String> _readTypeValues(Set<PoiFilterTypeValue> values) {
    return Set<String>.unmodifiable(
      values
          .map((value) => value.value.trim().toLowerCase())
          .where((value) => value.isNotEmpty),
    );
  }

  static Set<String> _readCategoryKeyValues(Set<PoiFilterKeyValue> values) {
    return Set<String>.unmodifiable(
      values
          .map((value) => value.value.trim().toLowerCase())
          .where((value) => value.isNotEmpty),
    );
  }

  static Set<String> _readTaxonomyValues(
    Set<PoiFilterTaxonomyTokenValue> values,
  ) {
    return Set<String>.unmodifiable(
      values
          .map((value) => value.value.trim().toLowerCase())
          .where((value) => value.isNotEmpty),
    );
  }

  static Set<String> _readTagValues(Set<PoiTagValue> values) {
    return Set<String>.unmodifiable(
      values
          .map((value) => value.value.trim().toLowerCase())
          .where((value) => value.isNotEmpty),
    );
  }

  static String? _readNullableValue(PoiFilterSourceValue? valueObject) {
    final raw = valueObject?.value;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }
}
