export 'main_filter_behavior.dart';
export 'main_filter_type.dart';
export 'main_filter_option_metadata.dart';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/main_filter_behavior.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option_metadata.dart';
import 'package:belluga_now/domain/map/filters/main_filter_type.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';

class MainFilterOption {
  MainFilterOption({
    required this.idValue,
    required this.labelValue,
    required this.iconNameValue,
    required this.type,
    required this.behavior,
    Set<CityPoiCategory>? categories,
    Set<PoiTagValue>? tagValues,
    MainFilterOptionMetadata? metadataValue,
  })  : categories = categories == null
            ? null
            : Set<CityPoiCategory>.unmodifiable(categories),
        tagValues =
            tagValues == null ? null : Set<PoiTagValue>.unmodifiable(tagValues),
        metadataValue = metadataValue ?? MainFilterOptionMetadata();

  final PoiFilterKeyValue idValue;
  final PoiFilterLabelValue labelValue;
  final PoiIconSymbolValue iconNameValue;
  final MainFilterType type;
  final MainFilterBehavior behavior;
  final Set<CityPoiCategory>? categories;
  final Set<PoiTagValue>? tagValues;
  final MainFilterOptionMetadata metadataValue;

  String get id => idValue.value;
  String get label => labelValue.value;
  String get iconName => iconNameValue.value;
  Set<String>? get tags => _readTagValues(tagValues);
  Map<String, Object?> get metadata => metadataValue.values;

  bool get opensPanel => behavior == MainFilterBehavior.opensPanel;
  bool get isQuickApply => behavior == MainFilterBehavior.quickApply;

  static Set<String>? _readTagValues(Set<PoiTagValue>? values) {
    if (values == null) {
      return null;
    }
    final normalized = values
        .map((value) => value.value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    return Set<String>.unmodifiable(normalized);
  }
}
