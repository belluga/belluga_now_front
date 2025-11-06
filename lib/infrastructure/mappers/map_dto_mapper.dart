import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/map/city_poi_dto.dart';

mixin MapDtoMapper {
  CityPoiModel mapCityPoi(CityPoiDTO dto) {
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
      priority: dto.priority,
      assetPath: dto.assetPath,
      isDynamic: dto.isDynamic,
      movementRadiusMeters: dto.movementRadiusMeters,
      tags: dto.tags,
    );
  }
}
