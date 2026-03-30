import 'package:belluga_now/domain/map/value_objects/main_filter_option_metadata_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';

class MainFilterOptionMetadataEntry {
  MainFilterOptionMetadataEntry({
    required this.keyValue,
    required this.valueValue,
  });

  final PoiFilterKeyValue keyValue;
  final MainFilterOptionMetadataValue valueValue;

  String get key => keyValue.value;
  String get value => valueValue.value;
}
