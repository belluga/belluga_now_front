import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';

class CityPoiModel {
  CityPoiModel({
    required this.idValue,
    required this.nameValue,
    required this.descriptionValue,
    required this.addressValue,
    required this.category,
    required this.coordinate,
    required this.priorityValue,
    this.assetPathValue,
    this.isDynamic = false,
    this.movementRadiusValue,
    List<PoiTagValue>? tagValues,
  }) : tagValues = List.unmodifiable(tagValues ?? const <PoiTagValue>[]);

  final CityPoiIdValue idValue;
  final CityPoiNameValue nameValue;
  final DescriptionValue descriptionValue;
  final CityPoiAddressValue addressValue;
  final CityPoiCategory category;
  final CityCoordinate coordinate;
  final PoiPriorityValue priorityValue;
  final AssetPathValue? assetPathValue;
  final bool isDynamic;
  final DistanceInMetersValue? movementRadiusValue;
  final List<PoiTagValue> tagValues;

  String get id => idValue.value;
  String get name => nameValue.value;
  String get description => descriptionValue.value;
  String get address => addressValue.value;
  int get priority => priorityValue.value;

  String? get assetPath => assetPathValue?.value;
  double? get movementRadiusMeters =>
      movementRadiusValue?.value ?? movementRadiusValue?.defaultValue;
  List<String> get tags => tagValues
      .map((tag) => tag.value)
      .whereType<String>()
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}
