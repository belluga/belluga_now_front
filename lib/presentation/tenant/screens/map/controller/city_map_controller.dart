import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CityMapController implements Disposable {
  CityMapController({
    CityMapRepositoryContract? repository,
  }) : _repository =
            repository ?? GetIt.I.get<CityMapRepositoryContract>();

  final CityMapRepositoryContract _repository;

  final poisStreamValue = StreamValue<List<CityPoiModel>?>(defaultValue: null);

  final selectedPoiStreamValue = StreamValue<CityPoiModel?>();

  CityCoordinate get defaultCenter => _repository.defaultCenter();

  Future<void> init() async {
    await loadPoints();
  }

  Future<void> loadPoints() async {
    poisStreamValue.addValue(null);
    try {
      final points = await _repository.fetchPointsOfInterest();
      poisStreamValue.addValue(points);
    } catch (_) {
      poisStreamValue.addValue(const []);
    }
  }

  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  @override
  void onDispose() {
    poisStreamValue.dispose();
    selectedPoiStreamValue.dispose();
  }
}
