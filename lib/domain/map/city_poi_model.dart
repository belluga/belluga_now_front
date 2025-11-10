import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/map_poi.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';

class CityPoiModel implements MapPoi {
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
  final CityPoiDescriptionValue descriptionValue;
  final CityPoiAddressValue addressValue;
  @override
  final CityPoiCategory category;

  @override
  final CityCoordinate coordinate;
  final PoiPriorityValue priorityValue;
  final AssetPathValue? assetPathValue;
  @override
  final bool isDynamic;
  final DistanceInMetersValue? movementRadiusValue;
  final List<PoiTagValue> tagValues;

  @override
  String get id => idValue.value;

  @override
  String get name => nameValue.value;

  @override
  String get description => descriptionValue.value;

  @override
  String get address => addressValue.value;

  @override
  int get priority => priorityValue.value;

  @override
  String? get assetPath => assetPathValue?.value;

  @override
  double? get movementRadiusMeters =>
      movementRadiusValue?.value ?? movementRadiusValue?.defaultValue;

  @override
  List<String> get tags => tagValues
      .map((tag) => tag.value)
      .whereType<String>()
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}
