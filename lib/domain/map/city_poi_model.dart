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
    this.refType = 'static',
    this.refId = '',
    this.refSlug,
    this.refPath,
    this.stackKey = '',
    this.stackCount = 1,
    List<CityPoiModel>? stackItems,
    this.isHappeningNow = false,
    this.updatedAt,
    this.distanceMeters,
  })  : tagValues = List.unmodifiable(tagValues ?? const <PoiTagValue>[]),
        stackItems = List.unmodifiable(stackItems ?? const <CityPoiModel>[]);

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
  final String refType;
  final String refId;
  final String? refSlug;
  final String? refPath;
  final String stackKey;
  final int stackCount;
  final List<CityPoiModel> stackItems;
  final bool isHappeningNow;
  final DateTime? updatedAt;
  final double? distanceMeters;

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

  bool get hasStack => stackCount > 1 && stackItems.isNotEmpty;

  CityPoiModel copyWith({
    CityPoiIdValue? idValue,
    CityPoiNameValue? nameValue,
    CityPoiDescriptionValue? descriptionValue,
    CityPoiAddressValue? addressValue,
    CityPoiCategory? category,
    CityCoordinate? coordinate,
    PoiPriorityValue? priorityValue,
    AssetPathValue? assetPathValue,
    bool? isDynamic,
    DistanceInMetersValue? movementRadiusValue,
    List<PoiTagValue>? tagValues,
    String? refType,
    String? refId,
    String? refSlug,
    String? refPath,
    String? stackKey,
    int? stackCount,
    List<CityPoiModel>? stackItems,
    bool? isHappeningNow,
    DateTime? updatedAt,
    double? distanceMeters,
  }) {
    return CityPoiModel(
      idValue: idValue ?? this.idValue,
      nameValue: nameValue ?? this.nameValue,
      descriptionValue: descriptionValue ?? this.descriptionValue,
      addressValue: addressValue ?? this.addressValue,
      category: category ?? this.category,
      coordinate: coordinate ?? this.coordinate,
      priorityValue: priorityValue ?? this.priorityValue,
      assetPathValue: assetPathValue ?? this.assetPathValue,
      isDynamic: isDynamic ?? this.isDynamic,
      movementRadiusValue: movementRadiusValue ?? this.movementRadiusValue,
      tagValues: tagValues ?? this.tagValues,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      refSlug: refSlug ?? this.refSlug,
      refPath: refPath ?? this.refPath,
      stackKey: stackKey ?? this.stackKey,
      stackCount: stackCount ?? this.stackCount,
      stackItems: stackItems ?? this.stackItems,
      isHappeningNow: isHappeningNow ?? this.isHappeningNow,
      updatedAt: updatedAt ?? this.updatedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}
