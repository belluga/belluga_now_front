import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/city_poi_data_source.dart';

class CityMapRepository extends CityMapRepositoryContract {
  CityMapRepository({
    CityPoiDataSource? dataSource,
  }) : _dataSource = dataSource ?? const CityPoiDataSource();

  final CityPoiDataSource _dataSource;

  @override
  Future<List<CityPoiModel>> fetchPointsOfInterest() async {
    final dtos = _dataSource.fetchPoints();
    return dtos.map(CityPoiModel.fromDTO).toList(growable: false);
  }

  @override
  CityCoordinate defaultCenter() => const CityCoordinate(
        latitude: -20.673067,
        longitude: -40.498383,
      );
}
