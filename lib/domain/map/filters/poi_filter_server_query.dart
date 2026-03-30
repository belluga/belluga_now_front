import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';

class PoiFilterServerQuery {
  PoiFilterServerQuery({
    this.sourceValue,
    List<PoiFilterTypeValue>? typeValues,
    List<PoiFilterKeyValue>? categoryKeyValues,
    List<PoiFilterTaxonomyTokenValue>? taxonomyTokenValues,
    List<PoiTagValue>? tagValues,
  })  : typeValues = List<PoiFilterTypeValue>.unmodifiable(
          typeValues ?? const <PoiFilterTypeValue>[],
        ),
        categoryKeyValues = List<PoiFilterKeyValue>.unmodifiable(
          categoryKeyValues ?? const <PoiFilterKeyValue>[],
        ),
        taxonomyTokenValues = List<PoiFilterTaxonomyTokenValue>.unmodifiable(
          taxonomyTokenValues ?? const <PoiFilterTaxonomyTokenValue>[],
        ),
        tagValues = List<PoiTagValue>.unmodifiable(
          tagValues ?? const <PoiTagValue>[],
        );

  final PoiFilterSourceValue? sourceValue;
  final List<PoiFilterTypeValue> typeValues;
  final List<PoiFilterKeyValue> categoryKeyValues;
  final List<PoiFilterTaxonomyTokenValue> taxonomyTokenValues;
  final List<PoiTagValue> tagValues;

  bool get isEmpty =>
      sourceValue == null &&
      typeValues.isEmpty &&
      categoryKeyValues.isEmpty &&
      taxonomyTokenValues.isEmpty &&
      tagValues.isEmpty;
}
