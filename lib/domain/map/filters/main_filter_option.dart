export 'main_filter_behavior.dart';
export 'main_filter_type.dart';
export 'main_filter_option_metadata.dart';

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
    List<PoiTagValue>? tagValues,
    MainFilterOptionMetadata? metadataValue,
  })  : tagValues = tagValues == null
            ? null
            : List<PoiTagValue>.unmodifiable(tagValues),
        metadataValue = metadataValue ?? MainFilterOptionMetadata();

  final PoiFilterKeyValue idValue;
  final PoiFilterLabelValue labelValue;
  final PoiIconSymbolValue iconNameValue;
  final MainFilterType type;
  final MainFilterBehavior behavior;
  final List<PoiTagValue>? tagValues;
  final MainFilterOptionMetadata metadataValue;

  String get id => idValue.value;
  String get label => labelValue.value;
  String get iconName => iconNameValue.value;
  List<PoiTagValue>? get tags => _readTagValues(tagValues);
  MainFilterOptionMetadata get metadata => metadataValue;

  bool get opensPanel => behavior == MainFilterBehavior.opensPanel;
  bool get isQuickApply => behavior == MainFilterBehavior.quickApply;

  static List<PoiTagValue>? _readTagValues(List<PoiTagValue>? values) {
    if (values == null) {
      return null;
    }
    return List<PoiTagValue>.unmodifiable(
      values.where((value) => value.value.trim().isNotEmpty),
    );
  }
}
