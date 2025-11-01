import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';

abstract class CityMapRepositoryContract {
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query);

  Stream<PoiUpdateEvent?> get poiEvents;

  CityCoordinate defaultCenter();

  void dispose();
}
