import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

class CityPoiModel {
  CityPoiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.coordinate,
    required this.priority,
    this.assetPath,
    this.isDynamic = false,
    this.movementRadiusMeters,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String description;
  final String address;
  final CityPoiCategory category;
  final CityCoordinate coordinate;
  final int priority;
  final String? assetPath;
  final bool isDynamic;
  final double? movementRadiusMeters;
  final List<String> tags;
}
