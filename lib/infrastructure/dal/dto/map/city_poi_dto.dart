import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_path_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_slug_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_updated_at_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/city_poi_visual_dto.dart';

class CityPoiDTO {
  const CityPoiDTO({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.assetPath,
    this.isDynamic = false,
    this.movementRadiusMeters,
    this.tags = const <String>[],
    this.priority = 10,
    this.refType = 'static',
    this.refId = '',
    this.refSlug,
    this.refPath,
    this.stackKey = '',
    this.stackCount = 1,
    this.items = const <CityPoiDTO>[],
    this.isHappeningNow = false,
    this.updatedAt,
    this.distanceMeters,
    this.visual,
  });

  final String id;
  final String name;
  final String description;
  final String address;
  final CityPoiCategory category;
  final double latitude;
  final double longitude;
  final String? assetPath;
  final bool isDynamic;
  final double? movementRadiusMeters;
  final List<String> tags;
  final int priority;
  final String refType;
  final String refId;
  final String? refSlug;
  final String? refPath;
  final String stackKey;
  final int stackCount;
  final List<CityPoiDTO> items;
  final bool isHappeningNow;
  final DateTime? updatedAt;
  final double? distanceMeters;
  final CityPoiVisualDTO? visual;

  factory CityPoiDTO.fromJson(Map<String, dynamic> json) {
    CityPoiCategory parseCategory(Object? raw) {
      final value = raw?.toString();
      if (value == null || value.isEmpty) {
        return CityPoiCategory.attraction;
      }
      if (value.toLowerCase() == 'event') {
        return CityPoiCategory.culture;
      }
      if (value.toLowerCase() == 'historic') {
        return CityPoiCategory.monument;
      }
      return CityPoiCategory.values.firstWhere(
        (candidate) => candidate.name.toLowerCase() == value.toLowerCase(),
        orElse: () => CityPoiCategory.attraction,
      );
    }

    double parseDouble(Object? raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    final locationRaw = _normalizeMap(json['location']);
    final latitudeRaw = json['latitude'] ?? json['lat'] ?? locationRaw?['lat'];
    final longitudeRaw =
        json['longitude'] ?? json['lng'] ?? json['lon'] ?? locationRaw?['lng'];
    final refType = (json['ref_type'] ?? '').toString().trim();
    final refId = (json['ref_id'] ?? json['id'] ?? '').toString().trim();
    final poiId = (json['id'] ?? '').toString().trim().isNotEmpty
        ? (json['id'] ?? '').toString().trim()
        : '${refType.isEmpty ? 'poi' : refType}_${refId.isEmpty ? 'unknown' : refId}';
    final title = (json['name'] ?? json['title'] ?? '').toString().trim();
    final subtitle =
        (json['subtitle'] ?? json['description'] ?? json['address'] ?? '')
            .toString()
            .trim();
    final fallbackName = refId.isNotEmpty ? 'POI $refId' : 'POI no mapa';
    final fallbackDescription = 'Ponto de interesse no mapa';
    final fallbackAddress = 'Mapa';
    final updatedAtRaw = json['updated_at']?.toString();
    final updatedAt =
        updatedAtRaw == null ? null : DateTime.tryParse(updatedAtRaw);
    final visual =
        CityPoiVisualDTO.tryFromJson(json['visual'] ?? json['poi_visual']);

    return CityPoiDTO(
      id: poiId,
      name: (title.isNotEmpty ? title : fallbackName).trim(),
      description: (json['description']?.toString().trim().isNotEmpty ?? false)
          ? json['description'].toString().trim()
          : (subtitle.isNotEmpty ? subtitle : fallbackDescription).trim(),
      address: (json['address']?.toString().trim().isNotEmpty ?? false)
          ? json['address'].toString().trim()
          : (subtitle.isNotEmpty ? subtitle : fallbackAddress).trim(),
      category: parseCategory(json['category'] ?? json['category_slug']),
      latitude: parseDouble(latitudeRaw),
      longitude: parseDouble(longitudeRaw),
      assetPath: json['asset_path'] as String?,
      isDynamic:
          json['is_dynamic'] as bool? ?? refType.toLowerCase() == 'event',
      movementRadiusMeters:
          (json['movement_radius_meters'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      priority: (json['priority'] as num?)?.toInt() ?? 10,
      refType: refType.isEmpty ? 'static' : refType,
      refId: refId,
      refSlug: json['ref_slug']?.toString(),
      refPath: json['ref_path']?.toString(),
      stackKey: json['stack_key']?.toString() ?? '',
      stackCount: (json['stack_count'] as num?)?.toInt() ?? 1,
      items: _normalizeMapList(json['items'])
          .map(CityPoiDTO.fromJson)
          .toList(growable: false),
      isHappeningNow: json['is_happening_now'] as bool? ?? false,
      updatedAt: updatedAt,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      visual: visual,
    );
  }

  factory CityPoiDTO.fromStackedApiJson(
    Map<String, dynamic> stackJson, {
    bool includeItems = false,
  }) {
    final topPoiRaw = _normalizeMap(stackJson['top_poi']);
    if (topPoiRaw == null) {
      throw FormatException('Missing top_poi payload in stack response');
    }

    final stackKey = (stackJson['stack_key'] ?? '').toString();
    final stackCount = (stackJson['stack_count'] as num?)?.toInt() ?? 1;
    final topPayload = <String, dynamic>{
      ...topPoiRaw,
      'stack_key': stackKey,
      'stack_count': stackCount,
    };

    if (includeItems) {
      topPayload['items'] = _normalizeMapList(stackJson['items'])
          .map((item) => <String, dynamic>{
                ...item,
                'stack_key': stackKey,
                'stack_count': stackCount,
              })
          .toList(growable: false);
    }

    return CityPoiDTO.fromJson(topPayload);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'category': category.name,
      'latitude': latitude,
      'longitude': longitude,
      'asset_path': assetPath,
      'is_dynamic': isDynamic,
      'movement_radius_meters': movementRadiusMeters,
      'tags': tags,
      'priority': priority,
      'ref_type': refType,
      'ref_id': refId,
      'ref_slug': refSlug,
      'ref_path': refPath,
      'stack_key': stackKey,
      'stack_count': stackCount,
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'is_happening_now': isHappeningNow,
      'updated_at': updatedAt == null
          ? null
          : TimezoneConverter.localToUtc(updatedAt!).toIso8601String(),
      'distance_meters': distanceMeters,
      if (visual != null) 'visual': visual!.toJson(),
    };
  }

  CityPoiModel toDomain() {
    final idValue = CityPoiIdValue()..parse(id);
    final nameValue = CityPoiNameValue()..parse(name);
    final descriptionValue = CityPoiDescriptionValue()..parse(description);
    final addressValue = CityPoiAddressValue()..parse(address);
    final coordinate = CityCoordinate(
      latitudeValue: LatitudeValue()..parse(latitude.toString()),
      longitudeValue: LongitudeValue()..parse(longitude.toString()),
    );
    final priorityValue = PoiPriorityValue()..parse(priority.toString());

    AssetPathValue? assetPathValue;
    if (assetPath != null && assetPath!.isNotEmpty) {
      assetPathValue = AssetPathValue(
        defaultValue: assetPath!,
        isRequired: true,
      )..parse(assetPath);
    }

    DistanceInMetersValue? movementRadiusValue;
    if (movementRadiusMeters != null) {
      movementRadiusValue = DistanceInMetersValue()
        ..parse(movementRadiusMeters!.toString());
    }

    final tagValues =
        tags.map((tag) => PoiTagValue()..parse(tag)).toList(growable: false);
    final stackItems =
        items.map((item) => item.toDomain()).toList(growable: false);
    final stackItemCollection = CityPoiStackItems();
    for (final item in stackItems) {
      stackItemCollection.add(item);
    }
    final resolvedStackKey =
        stackKey.trim().isNotEmpty ? stackKey.trim() : '$refType:$refId';
    final isDynamicValue = PoiBooleanValue()..parse(isDynamic.toString());
    final refTypeValue = PoiReferenceTypeValue()..parse(refType.trim());
    final refIdValue = PoiReferenceIdValue()..parse(refId.trim());
    PoiReferenceSlugValue? refSlugValue;
    final normalizedRefSlug = refSlug?.trim();
    if (normalizedRefSlug != null && normalizedRefSlug.isNotEmpty) {
      refSlugValue = PoiReferenceSlugValue()..parse(normalizedRefSlug);
    }
    PoiReferencePathValue? refPathValue;
    final normalizedRefPath = refPath?.trim();
    if (normalizedRefPath != null && normalizedRefPath.isNotEmpty) {
      refPathValue = PoiReferencePathValue()..parse(normalizedRefPath);
    }
    final stackKeyValue = PoiStackKeyValue()..parse(resolvedStackKey.trim());
    final stackCountValue = PoiStackCountValue()..parse(stackCount.toString());
    final isHappeningNowValue = PoiBooleanValue()
      ..parse(isHappeningNow.toString());
    PoiUpdatedAtValue? updatedAtValue;
    if (updatedAt != null) {
      updatedAtValue = PoiUpdatedAtValue()..parse(updatedAt!.toIso8601String());
    }
    DistanceInMetersValue? distanceMetersValue;
    if (distanceMeters != null) {
      distanceMetersValue = DistanceInMetersValue()
        ..parse(distanceMeters!.toString());
    }

    return CityPoiModel(
      idValue: idValue,
      nameValue: nameValue,
      descriptionValue: descriptionValue,
      addressValue: addressValue,
      category: category,
      coordinate: coordinate,
      priorityValue: priorityValue,
      assetPathValue: assetPathValue,
      isDynamicValue: isDynamicValue,
      movementRadiusValue: movementRadiusValue,
      tagValues: tagValues,
      refTypeValue: refTypeValue,
      refIdValue: refIdValue,
      refSlugValue: refSlugValue,
      refPathValue: refPathValue,
      stackKeyValue: stackKeyValue,
      stackCountValue: stackCountValue,
      stackItems: stackItemCollection,
      isHappeningNowValue: isHappeningNowValue,
      updatedAtValue: updatedAtValue,
      distanceMetersValue: distanceMetersValue,
      visual: visual?.toDomain(),
    );
  }

  static Map<String, dynamic>? _normalizeMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return raw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  static List<Map<String, dynamic>> _normalizeMapList(Object? raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }

    return raw
        .map(_normalizeMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}
