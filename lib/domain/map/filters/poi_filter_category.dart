import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_server_query.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_marker_override.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';

typedef PoiFilterCategoryRawString = String;
typedef PoiFilterCategoryRawTag = String;
typedef PoiFilterCategoryRawTagSet = Set<PoiFilterCategoryRawTag>;
typedef PoiFilterCategoryRawCount = int;
typedef PoiFilterCategoryRawBool = bool;

class PoiFilterCategory {
  PoiFilterCategory({
    this.category,
    required PoiFilterCategoryRawTagSet tags,
    PoiFilterCategoryRawString? key,
    PoiFilterCategoryRawString? label,
    PoiFilterCategoryRawString? imageUri,
    PoiFilterCategoryRawCount count = 0,
    this.overrideMarker = false,
    this.markerOverride,
    this.serverQuery,
  })  : keyValue = _buildKeyValue(_resolveKey(key, category)),
        labelValue = _buildLabelValue(_resolveLabel(label, key, category)),
        imageUriValue = _buildImageUriValue(imageUri),
        countValue = _buildCountValue(count),
        tagValues = _buildTagValues(tags);

  final PoiFilterKeyValue keyValue;
  final PoiFilterLabelValue labelValue;
  final PoiFilterImageUriValue? imageUriValue;
  final PoiFilterCountValue countValue;
  final CityPoiCategory? category;
  final Set<PoiTagValue> tagValues;
  final PoiFilterCategoryRawBool overrideMarker;
  final PoiFilterMarkerOverride? markerOverride;
  final PoiFilterServerQuery? serverQuery;

  String get key => keyValue.value;
  String get label => labelValue.value;
  String? get imageUri => imageUriValue?.value;
  int get count => countValue.value;
  CityPoiVisual? get markerOverrideVisual {
    if (!overrideMarker) {
      return null;
    }

    return markerOverride?.toPoiVisual();
  }

  Set<String> get tags => Set<String>.unmodifiable(
        tagValues
            .map((tag) => tag.value)
            .whereType<String>()
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty),
      );

  static String _resolveKey(
    PoiFilterCategoryRawString? rawKey,
    CityPoiCategory? category,
  ) {
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
    PoiFilterCategoryRawString? rawLabel,
    PoiFilterCategoryRawString? rawKey,
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
        CityPoiCategory.monument => 'Historico',
        CityPoiCategory.church => 'Historico',
        CityPoiCategory.health => 'Saude',
        CityPoiCategory.lodging => 'Hospedagem',
        CityPoiCategory.attraction => 'Atracoes',
        CityPoiCategory.sponsor => 'Parceiros',
      };
    }
    final key = (rawKey ?? '').trim();
    if (key.isEmpty) {
      return 'Filtro';
    }
    return key;
  }

  static PoiFilterKeyValue _buildKeyValue(PoiFilterCategoryRawString raw) {
    final value = PoiFilterKeyValue()..parse(raw.trim().toLowerCase());
    return value;
  }

  static PoiFilterLabelValue _buildLabelValue(PoiFilterCategoryRawString raw) {
    final value = PoiFilterLabelValue()..parse(raw.trim());
    return value;
  }

  static PoiFilterImageUriValue? _buildImageUriValue(
    PoiFilterCategoryRawString? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = PoiFilterImageUriValue()..parse(normalized);
    return value;
  }

  static PoiFilterCountValue _buildCountValue(PoiFilterCategoryRawCount raw) {
    final value = PoiFilterCountValue()..parse(raw.toString());
    return value;
  }

  static Set<PoiTagValue> _buildTagValues(PoiFilterCategoryRawTagSet rawTags) {
    final values = <PoiTagValue>{};
    for (final raw in rawTags) {
      final normalized = raw.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = PoiTagValue()..parse(normalized);
      values.add(value);
    }
    return Set<PoiTagValue>.unmodifiable(values);
  }
}
