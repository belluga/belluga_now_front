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
    PoiBooleanValue? isDynamicValue,
    this.movementRadiusValue,
    List<PoiTagValue>? tagValues,
    PoiReferenceTypeValue? refTypeValue,
    PoiReferenceIdValue? refIdValue,
    this.refSlugValue,
    this.refPathValue,
    PoiStackKeyValue? stackKeyValue,
    PoiStackCountValue? stackCountValue,
    List<CityPoiModel>? stackItems,
    PoiBooleanValue? isHappeningNowValue,
    this.updatedAtValue,
    this.distanceMetersValue,
    this.visual,
  })  : tagValues = List.unmodifiable(tagValues ?? const <PoiTagValue>[]),
        stackItems = List.unmodifiable(stackItems ?? const <CityPoiModel>[]),
        isDynamicValue = isDynamicValue ?? _defaultFalseBooleanValue(),
        refTypeValue = refTypeValue ?? _defaultRefTypeValue(),
        refIdValue = refIdValue ?? _defaultRefIdValue(),
        stackKeyValue = stackKeyValue ?? _defaultStackKeyValue(),
        stackCountValue = stackCountValue ?? _defaultStackCountValue(),
        isHappeningNowValue =
            isHappeningNowValue ?? _defaultFalseBooleanValue();

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
  String? get refSlug {
    final raw = refSlugValue?.value;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }

  String? get refPath {
    final raw = refPathValue?.value;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }

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
    PoiBooleanValue? isDynamicValue,
    DistanceInMetersValue? movementRadiusValue,
    List<PoiTagValue>? tagValues,
    PoiReferenceTypeValue? refTypeValue,
    PoiReferenceIdValue? refIdValue,
    PoiReferenceSlugValue? refSlugValue,
    PoiReferencePathValue? refPathValue,
    PoiStackKeyValue? stackKeyValue,
    PoiStackCountValue? stackCountValue,
    List<CityPoiModel>? stackItems,
    PoiBooleanValue? isHappeningNowValue,
    PoiUpdatedAtValue? updatedAtValue,
    DistanceInMetersValue? distanceMetersValue,
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
      isDynamicValue: isDynamicValue ?? this.isDynamicValue,
      movementRadiusValue: movementRadiusValue ?? this.movementRadiusValue,
      tagValues: tagValues ?? this.tagValues,
      refTypeValue: refTypeValue ?? this.refTypeValue,
      refIdValue: refIdValue ?? this.refIdValue,
      refSlugValue: refSlugValue ?? this.refSlugValue,
      refPathValue: refPathValue ?? this.refPathValue,
      stackKeyValue: stackKeyValue ?? this.stackKeyValue,
      stackCountValue: stackCountValue ?? this.stackCountValue,
      stackItems: stackItems ?? this.stackItems,
      isHappeningNowValue: isHappeningNowValue ?? this.isHappeningNowValue,
      updatedAtValue: updatedAtValue ?? this.updatedAtValue,
      distanceMetersValue: distanceMetersValue ?? this.distanceMetersValue,
      visual: visual ?? this.visual,
    );
  }

  static PoiBooleanValue _defaultFalseBooleanValue() {
    final value = PoiBooleanValue()..parse('false');
    return value;
  }

  static PoiReferenceTypeValue _defaultRefTypeValue() {
    final value = PoiReferenceTypeValue()..parse('static');
    return value;
  }

  static PoiReferenceIdValue _defaultRefIdValue() {
    final value = PoiReferenceIdValue()..parse('');
    return value;
  }

  static PoiStackKeyValue _defaultStackKeyValue() {
    final value = PoiStackKeyValue()..parse('');
    return value;
  }

  static PoiStackCountValue _defaultStackCountValue() {
    final value = PoiStackCountValue()..parse('1');
    return value;
  }
}
