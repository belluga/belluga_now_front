import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_poi_database.dart';

class CityMapRepository extends CityMapRepositoryContract {
  CityMapRepository({
    MockPoiDatabase? database,
  }) : _database = database ?? const MockPoiDatabase();

  final MockPoiDatabase _database;

  @override
  Future<List<CityPoiModel>> fetchPointsOfInterest(CityCoordinate origin) async {
    final dtos = _database.findPois();
    return dtos.map(CityPoiModel.fromDTO).toList(growable: false);
  }

  @override
  CityCoordinate defaultCenter() => const CityCoordinate(
        latitude: -20.673067,
        longitude: -40.498383,
      );
}
