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

  factory CityPoiDTO.fromJson(Map<String, dynamic> json) {
    CityPoiCategory parseCategory(Object? raw) {
      final value = raw?.toString();
      if (value == null || value.isEmpty) {
        return CityPoiCategory.attraction;
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

    final latitudeRaw = json['latitude'] ?? json['lat'];
    final longitudeRaw = json['longitude'] ?? json['lng'] ?? json['lon'];

    return CityPoiDTO(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      category: parseCategory(json['category'] ?? json['category_slug']),
      latitude: parseDouble(latitudeRaw),
      longitude: parseDouble(longitudeRaw),
      assetPath: json['asset_path'] as String?,
      isDynamic: json['is_dynamic'] as bool? ?? false,
      movementRadiusMeters: (json['movement_radius_meters'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      priority: (json['priority'] as num?)?.toInt() ?? 10,
    );
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
    };
  }
}
