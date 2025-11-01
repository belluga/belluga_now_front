import 'dart:async';
import 'dart:math' as math;

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CityMapController implements Disposable {
  CityMapController({
    CityMapRepositoryContract? repository,
    ScheduleRepositoryContract? scheduleRepository,
  })  : _repository =
            repository ?? GetIt.I.get<CityMapRepositoryContract>(),
        _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>();

  final CityMapRepositoryContract _repository;
  final ScheduleRepositoryContract _scheduleRepository;

  final poisStreamValue = StreamValue<List<CityPoiModel>?>(defaultValue: const []);
  final eventsStreamValue = StreamValue<List<EventModel>?>(defaultValue: const []);

  final selectedPoiStreamValue = StreamValue<CityPoiModel?>();
  final selectedEventStreamValue = StreamValue<EventModel?>();

  CityCoordinate get defaultCenter => _repository.defaultCenter();

  Timer? _movingPoiTimer;

  Future<bool> loadPoints(CityCoordinate origin) async {
    poisStreamValue.addValue(null);
    try {
      final points = await _repository.fetchPointsOfInterest(origin);
      poisStreamValue.addValue(points);
      _startDynamicPoiUpdates(points);
      return true;
    } catch (_) {
      poisStreamValue.addValue(const []);
      return false;
    }
  }

  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  void selectEvent(EventModel? event) {
    selectedEventStreamValue.addValue(event);
  }

  Future<void> loadEventsForDate(DateTime date) async {
    try {
      selectedEventStreamValue.addValue(null);
      final events = await _scheduleRepository.getEventsByDate(date);
      eventsStreamValue.addValue(events);
    } catch (_) {
      eventsStreamValue.addValue(const []);
    }
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
    eventsStreamValue.dispose();
    selectedEventStreamValue.dispose();
    _movingPoiTimer?.cancel();
  }
}
