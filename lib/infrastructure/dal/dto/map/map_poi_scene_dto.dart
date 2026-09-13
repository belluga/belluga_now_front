import 'package:belluga_now/infrastructure/dal/dto/map/city_poi_dto.dart';

class MapPoiSceneDTO {
  MapPoiSceneDTO({required List<CityPoiDTO> points, required this.isPartial})
    : points = List<CityPoiDTO>.unmodifiable(points);

  final List<CityPoiDTO> points;
  final bool isPartial;
}
