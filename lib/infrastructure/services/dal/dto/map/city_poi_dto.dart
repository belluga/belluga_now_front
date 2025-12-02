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
}
