import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';

typedef PoiFilterServerQueryRawString = String;
typedef PoiFilterServerQueryToken = String;
typedef PoiFilterServerQueryTokenSet = Set<PoiFilterServerQueryToken>;
typedef PoiFilterServerQueryTokenIterable = Iterable<PoiFilterServerQueryToken>;
typedef PoiFilterServerQueryDynamicValue = dynamic;
typedef PoiFilterServerQueryDynamicIterable
    = Iterable<PoiFilterServerQueryDynamicValue>;

class PoiFilterServerQuery {
  PoiFilterServerQuery({
    PoiFilterServerQueryRawString? source,
    PoiFilterServerQueryTokenSet types = const <PoiFilterServerQueryToken>{},
    PoiFilterServerQueryTokenSet categoryKeys =
        const <PoiFilterServerQueryToken>{},
    PoiFilterServerQueryTokenSet taxonomy = const <PoiFilterServerQueryToken>{},
    PoiFilterServerQueryTokenSet tags = const <PoiFilterServerQueryToken>{},
  })  : sourceValue = _buildSourceValue(source),
        typeValues = _buildTypeValues(types),
        categoryKeyValues = _buildCategoryKeyValues(categoryKeys),
        taxonomyTokenValues = _buildTaxonomyTokenValues(taxonomy),
        tagValues = _buildTagValues(tags);

  final PoiFilterSourceValue? sourceValue;
  final Set<PoiFilterTypeValue> typeValues;
  final Set<PoiFilterKeyValue> categoryKeyValues;
  final Set<PoiFilterTaxonomyTokenValue> taxonomyTokenValues;
  final Set<PoiTagValue> tagValues;

  String? get source => _readNullableValue(sourceValue);

  Set<String> get types => _readStringSet(typeValues);

  Set<String> get categoryKeys => _readStringSet(categoryKeyValues);

  Set<String> get taxonomy => _readStringSet(taxonomyTokenValues);

  Set<String> get tags => _readStringSet(tagValues);

  bool get isEmpty =>
      sourceValue == null &&
      typeValues.isEmpty &&
      categoryKeyValues.isEmpty &&
      taxonomyTokenValues.isEmpty &&
      tagValues.isEmpty;

  static PoiFilterSourceValue? _buildSourceValue(
    PoiFilterServerQueryRawString? raw,
  ) {
    final normalized = raw?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return PoiFilterSourceValue()..parse(normalized);
  }

  static Set<PoiFilterTypeValue> _buildTypeValues(
    PoiFilterServerQueryTokenIterable rawValues,
  ) {
    return _buildStringValueSet(
      rawValues,
      () => PoiFilterTypeValue(),
    );
  }

  static Set<PoiFilterKeyValue> _buildCategoryKeyValues(
    PoiFilterServerQueryTokenIterable rawValues,
  ) {
    return _buildStringValueSet(
      rawValues,
      () => PoiFilterKeyValue(),
    );
  }

  static Set<PoiFilterTaxonomyTokenValue> _buildTaxonomyTokenValues(
    PoiFilterServerQueryTokenIterable rawValues,
  ) {
    return _buildStringValueSet(
      rawValues,
      () => PoiFilterTaxonomyTokenValue(),
    );
  }

  static Set<PoiTagValue> _buildTagValues(
    PoiFilterServerQueryTokenIterable rawValues,
  ) {
    return _buildStringValueSet(
      rawValues,
      () => PoiTagValue(),
    );
  }

  static Set<T> _buildStringValueSet<T>(
    PoiFilterServerQueryTokenIterable rawValues,
    T Function() createValue,
  ) {
    final values = <T>{};
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = createValue();
      if (value is PoiFilterTypeValue) {
        value.parse(normalized);
        values.add(value as T);
      } else if (value is PoiFilterKeyValue) {
        value.parse(normalized);
        values.add(value as T);
      } else if (value is PoiFilterTaxonomyTokenValue) {
        value.parse(normalized);
        values.add(value as T);
      } else if (value is PoiTagValue) {
        value.parse(normalized);
        values.add(value as T);
      }
    }
    return Set<T>.unmodifiable(values);
  }

  static Set<String> _readStringSet(
      PoiFilterServerQueryDynamicIterable values) {
    return Set<String>.unmodifiable(
      values
          .map((value) => value.value as String?)
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );
  }

  static String? _readNullableValue(
      PoiFilterServerQueryDynamicValue valueObject) {
    final raw = valueObject?.value as String?;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }
}
