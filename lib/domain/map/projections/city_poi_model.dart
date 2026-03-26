import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/map_poi.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_path_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_slug_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_updated_at_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';

typedef CityPoiModelRawString = String;
typedef CityPoiModelRawBoolean = bool;
typedef CityPoiModelRawCount = int;
typedef CityPoiModelRawMeters = double;
typedef CityPoiModelRawTimestamp = DateTime;
typedef CityPoiModelDynamicValue = dynamic;

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
    CityPoiModelRawBoolean isDynamic = false,
    this.movementRadiusValue,
    List<PoiTagValue>? tagValues,
    CityPoiModelRawString refType = 'static',
    CityPoiModelRawString refId = '',
    CityPoiModelRawString? refSlug,
    CityPoiModelRawString? refPath,
    CityPoiModelRawString stackKey = '',
    CityPoiModelRawCount stackCount = 1,
    List<CityPoiModel>? stackItems,
    CityPoiModelRawBoolean isHappeningNow = false,
    CityPoiModelRawTimestamp? updatedAt,
    CityPoiModelRawMeters? distanceMeters,
    this.visual,
  })  : tagValues = List.unmodifiable(tagValues ?? const <PoiTagValue>[]),
        stackItems = List.unmodifiable(stackItems ?? const <CityPoiModel>[]),
        isDynamicValue = _buildBooleanValue(isDynamic),
        refTypeValue = _buildRefTypeValue(refType),
        refIdValue = _buildRefIdValue(refId),
        refSlugValue = _buildRefSlugValue(refSlug),
        refPathValue = _buildRefPathValue(refPath),
        stackKeyValue = _buildStackKeyValue(stackKey),
        stackCountValue = _buildStackCountValue(stackCount),
        isHappeningNowValue = _buildBooleanValue(isHappeningNow),
        updatedAtValue = _buildUpdatedAtValue(updatedAt),
        distanceMetersValue = _buildDistanceValue(distanceMeters);

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
  final PoiBooleanValue isDynamicValue;
  final DistanceInMetersValue? movementRadiusValue;
  final List<PoiTagValue> tagValues;
  final PoiReferenceTypeValue refTypeValue;
  final PoiReferenceIdValue refIdValue;
  final PoiReferenceSlugValue? refSlugValue;
  final PoiReferencePathValue? refPathValue;
  final PoiStackKeyValue stackKeyValue;
  final PoiStackCountValue stackCountValue;
  final List<CityPoiModel> stackItems;
  final PoiBooleanValue isHappeningNowValue;
  final PoiUpdatedAtValue? updatedAtValue;
  final DistanceInMetersValue? distanceMetersValue;
  final CityPoiVisual? visual;

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
  bool get isDynamic => isDynamicValue.value;

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

  String get refType => refTypeValue.value;
  String get refId => refIdValue.value;
  String? get refSlug => _readNullableValue(refSlugValue);
  String? get refPath => _readNullableValue(refPathValue);
  String get stackKey => stackKeyValue.value;
  int get stackCount => stackCountValue.value;
  bool get isHappeningNow => isHappeningNowValue.value;
  DateTime? get updatedAt => updatedAtValue?.value;
  double? get distanceMeters => distanceMetersValue?.value;

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
    CityPoiModelRawBoolean? isDynamic,
    DistanceInMetersValue? movementRadiusValue,
    List<PoiTagValue>? tagValues,
    CityPoiModelRawString? refType,
    CityPoiModelRawString? refId,
    CityPoiModelRawString? refSlug,
    CityPoiModelRawString? refPath,
    CityPoiModelRawString? stackKey,
    CityPoiModelRawCount? stackCount,
    List<CityPoiModel>? stackItems,
    CityPoiModelRawBoolean? isHappeningNow,
    CityPoiModelRawTimestamp? updatedAt,
    CityPoiModelRawMeters? distanceMeters,
    CityPoiVisual? visual,
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
      visual: visual ?? this.visual,
    );
  }

  static PoiBooleanValue _buildBooleanValue(CityPoiModelRawBoolean raw) {
    final value = PoiBooleanValue()..parse(raw.toString());
    return value;
  }

  static PoiReferenceTypeValue _buildRefTypeValue(CityPoiModelRawString raw) {
    final value = PoiReferenceTypeValue()..parse(raw.trim());
    return value;
  }

  static PoiReferenceIdValue _buildRefIdValue(CityPoiModelRawString raw) {
    final value = PoiReferenceIdValue()..parse(raw.trim());
    return value;
  }

  static PoiReferenceSlugValue? _buildRefSlugValue(
    CityPoiModelRawString? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = PoiReferenceSlugValue()..parse(normalized);
    return value;
  }

  static PoiReferencePathValue? _buildRefPathValue(
    CityPoiModelRawString? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = PoiReferencePathValue()..parse(normalized);
    return value;
  }

  static PoiStackKeyValue _buildStackKeyValue(CityPoiModelRawString raw) {
    final value = PoiStackKeyValue()..parse(raw.trim());
    return value;
  }

  static PoiStackCountValue _buildStackCountValue(CityPoiModelRawCount raw) {
    final value = PoiStackCountValue()..parse(raw.toString());
    return value;
  }

  static PoiUpdatedAtValue? _buildUpdatedAtValue(
    CityPoiModelRawTimestamp? raw,
  ) {
    if (raw == null) {
      return null;
    }
    final value = PoiUpdatedAtValue()..parse(raw.toIso8601String());
    return value;
  }

  static DistanceInMetersValue? _buildDistanceValue(
    CityPoiModelRawMeters? raw,
  ) {
    if (raw == null) {
      return null;
    }
    final value = DistanceInMetersValue()..parse(raw.toString());
    return value;
  }

  static String? _readNullableValue(CityPoiModelDynamicValue valueObject) {
    final raw = valueObject?.value as String?;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }
}
