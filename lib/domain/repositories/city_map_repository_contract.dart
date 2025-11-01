import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

abstract class CityMapRepositoryContract {
  Future<List<CityPoiModel>> fetchPointsOfInterest(CityCoordinate origin);

  CityCoordinate defaultCenter();
}
