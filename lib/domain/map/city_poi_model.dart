import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/map/city_poi_dto.dart';

class CityPoiModel {
  CityPoiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.coordinate,
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
  final String? assetPath;
  final bool isDynamic;
  final double? movementRadiusMeters;
  final List<String> tags;

  factory CityPoiModel.fromDTO(CityPoiDTO dto) {
    return CityPoiModel(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      address: dto.address,
      category: dto.category,
      coordinate: CityCoordinate(
        latitude: dto.latitude,
        longitude: dto.longitude,
      ),
      assetPath: dto.assetPath,
      isDynamic: dto.isDynamic,
      movementRadiusMeters: dto.movementRadiusMeters,
      tags: dto.tags,
    );
  }
}
