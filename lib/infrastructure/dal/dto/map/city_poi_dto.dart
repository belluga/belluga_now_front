import 'package:belluga_now/domain/map/city_poi_category.dart';

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

    final locationRaw = json['location'];
    final latitudeRaw = json['latitude'] ??
        json['lat'] ??
        (locationRaw is Map<String, dynamic> ? locationRaw['lat'] : null);
    final longitudeRaw = json['longitude'] ??
        json['lng'] ??
        json['lon'] ??
        (locationRaw is Map<String, dynamic> ? locationRaw['lng'] : null);
    final refType = (json['ref_type'] ?? '').toString().trim();
    final refId = (json['ref_id'] ?? json['id'] ?? '').toString().trim();
    final poiId = (json['id'] ?? '').toString().trim().isNotEmpty
        ? (json['id'] ?? '').toString().trim()
        : '${refType.isEmpty ? 'poi' : refType}_${refId.isEmpty ? 'unknown' : refId}';
    final fallbackName = refId.isNotEmpty ? 'POI $refId' : 'POI no mapa';
    final fallbackDescription = 'Ponto de interesse no mapa';
    final fallbackAddress = 'Mapa';
    final updatedAtRaw = json['updated_at']?.toString();
    final updatedAt =
        updatedAtRaw == null ? null : DateTime.tryParse(updatedAtRaw);

    return CityPoiDTO(
      id: poiId,
      name: ((json['name'] ?? '').toString().trim().isNotEmpty
              ? (json['name'] ?? '').toString()
              : fallbackName)
          .trim(),
      description: ((json['description'] ?? '').toString().trim().isNotEmpty
              ? (json['description'] ?? '').toString()
              : fallbackDescription)
          .trim(),
      address: ((json['address'] ?? '').toString().trim().isNotEmpty
              ? (json['address'] ?? '').toString()
              : fallbackAddress)
          .trim(),
      category: parseCategory(json['category'] ?? json['category_slug']),
      latitude: parseDouble(latitudeRaw),
      longitude: parseDouble(longitudeRaw),
      assetPath: json['asset_path'] as String?,
      isDynamic:
          json['is_dynamic'] as bool? ?? refType.toLowerCase() == 'event',
      movementRadiusMeters: (json['movement_radius_meters'] as num?)?.toDouble(),
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
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CityPoiDTO.fromJson)
          .toList(growable: false),
      isHappeningNow: json['is_happening_now'] as bool? ?? false,
      updatedAt: updatedAt,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
    );
  }

  factory CityPoiDTO.fromStackedApiJson(
    Map<String, dynamic> stackJson, {
    bool includeItems = false,
  }) {
    final topPoiRaw = stackJson['top_poi'];
    if (topPoiRaw is! Map<String, dynamic>) {
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
      topPayload['items'] = (stackJson['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
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
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'distance_meters': distanceMeters,
    };
  }
}
