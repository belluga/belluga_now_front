import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_marker_override.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_server_query.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';

class PoiFilterCategory {
  PoiFilterCategory({
    this.category,
    required Set<PoiTagValue> tagValues,
    required this.keyValue,
    required this.labelValue,
    required this.countValue,
    this.imageUriValue,
    PoiBooleanValue? overrideMarkerValue,
    this.markerOverride,
    this.serverQuery,
  })  : tagValues = Set<PoiTagValue>.unmodifiable(tagValues),
        overrideMarkerValue =
            overrideMarkerValue ?? _buildDefaultOverrideMarkerValue();

  final PoiFilterKeyValue keyValue;
  final PoiFilterLabelValue labelValue;
  final PoiFilterImageUriValue? imageUriValue;
  final PoiFilterCountValue countValue;
  final CityPoiCategory? category;
  final Set<PoiTagValue> tagValues;
  final PoiBooleanValue overrideMarkerValue;
  final PoiFilterMarkerOverride? markerOverride;
  final PoiFilterServerQuery? serverQuery;

  String get key => keyValue.value;
  String get label => labelValue.value;
  String? get imageUri => imageUriValue?.value;
  int get count => countValue.value;
  bool get overrideMarker => overrideMarkerValue.value;

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

  static PoiBooleanValue _buildDefaultOverrideMarkerValue() {
    final value = PoiBooleanValue();
    value.parse('false');
    return value;
  }
}
