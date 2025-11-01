import 'dart:async';
import 'dart:math' as math;

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

  Timer? _movingPoiTimer;

  Future<void> loadPoints(CityCoordinate origin) async {
    poisStreamValue.addValue(null);
    try {
      final points = await _repository.fetchPointsOfInterest(origin);
      poisStreamValue.addValue(points);
      _startDynamicPoiUpdates(points);
    } catch (_) {
      poisStreamValue.addValue(const []);
    }
  }

  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  void _startDynamicPoiUpdates(List<CityPoiModel> points) {
    _movingPoiTimer?.cancel();
    var currentPoints = List<CityPoiModel>.from(points);
    final dynamicPois = currentPoints.where((poi) => poi.isDynamic).toList();
    if (dynamicPois.isEmpty) {
      return;
    }

    _movingPoiTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      currentPoints = currentPoints.map((poi) {
        if (!poi.isDynamic || poi.movementRadiusMeters == null) {
          return poi;
        }

        final radius = poi.movementRadiusMeters!;
        final deltaLat = (radius / 111320) * (0.5 - _random.nextDouble());
        final denominator =
            111320 * math.cos(poi.coordinate.latitude * math.pi / 180);
        final deltaLng = denominator == 0
            ? 0
            : (radius / denominator) * (0.5 - _random.nextDouble());

        return CityPoiModel(
          id: poi.id,
          name: poi.name,
          description: poi.description,
          address: poi.address,
          category: poi.category,
          coordinate: CityCoordinate(
            latitude: poi.coordinate.latitude + deltaLat,
            longitude: poi.coordinate.longitude + deltaLng,
          ),
          assetPath: poi.assetPath,
          isDynamic: poi.isDynamic,
          movementRadiusMeters: poi.movementRadiusMeters,
        );
      }).toList(growable: false);

      poisStreamValue.addValue(currentPoints);
    });
  }

  final _random = math.Random();

  @override
  void onDispose() {
    poisStreamValue.dispose();
    selectedPoiStreamValue.dispose();
    _movingPoiTimer?.cancel();
  }
}
