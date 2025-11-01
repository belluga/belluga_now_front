import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CityMapController implements Disposable {
  CityMapController({
    CityMapRepositoryContract? repository,
    ScheduleRepositoryContract? scheduleRepository,
  })  : _repository = repository ?? GetIt.I.get<CityMapRepositoryContract>(),
        _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        eventsStreamValue = StreamValue<List<EventModel>?>() {
    _poiEventsSubscription = _repository.poiEvents.listen(_handlePoiEvent);
  }

  final CityMapRepositoryContract _repository;
  final ScheduleRepositoryContract _scheduleRepository;

  final StreamValue<List<EventModel>?> eventsStreamValue;

  final isLoading = StreamValue<bool>(defaultValue: false);
  final pois = StreamValue<List<CityPoiModel>>(defaultValue: const []);
  final errorMessage = StreamValue<String?>();
  final latestOffer = StreamValue<PoiOfferActivatedEvent?>();

  final selectedPoiStreamValue = StreamValue<CityPoiModel?>();
  final selectedEventStreamValue = StreamValue<EventModel?>();

  CityCoordinate get defaultCenter => _repository.defaultCenter();

  PoiQuery _currentQuery = const PoiQuery();
  StreamSubscription<PoiUpdateEvent?>? _poiEventsSubscription;

  Future<void> initialize() async {
    await _loadEventsForDate(_today);
  }

  Future<void> loadPois(PoiQuery query) async {
    _currentQuery = query;
    _setLoadingState();

    try {
      final pois = await _repository.fetchPoints(query);
      _setSuccessState(pois);
    } catch (_) {
      _setErrorState('Não foi possível carregar os pontos de interesse.');
    }
  }

  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  void selectEvent(EventModel? event) {
    selectedEventStreamValue.addValue(event);
  }

  Future<void> _loadEventsForDate(DateTime date) async {
    try {
      selectedEventStreamValue.addValue(null);
      final events = await _scheduleRepository.getEventsByDate(date);
      eventsStreamValue.addValue(events);
    } catch (_) {
      eventsStreamValue.addValue(const []);
    }
  }

  void _handlePoiEvent(PoiUpdateEvent? event) {

    if(event == null){
      return;
    }

    switch (event) {
      case PoiMovedEvent(:final coordinate):
        _updatePoiCoordinate(event.poiId, coordinate);
        break;
      case PoiOfferActivatedEvent():
        final offerEvent = event;
        isLoading.addValue(false);
        errorMessage.addValue(null);
        latestOffer.addValue(offerEvent);
        break;
    }
  }

  void _updatePoiCoordinate(String poiId, CityCoordinate coordinate) {
    final currentPois = List<CityPoiModel>.from(pois.value);
    final index = currentPois.indexWhere((poi) => poi.id == poiId);
    if (index == -1) {
      return;
    }
    final poi = currentPois[index];
    currentPois[index] = CityPoiModel(
      id: poi.id,
      name: poi.name,
      description: poi.description,
      address: poi.address,
      category: poi.category,
      coordinate: coordinate,
      priority: poi.priority,
      assetPath: poi.assetPath,
      isDynamic: poi.isDynamic,
      movementRadiusMeters: poi.movementRadiusMeters,
      tags: poi.tags,
    );

    pois.addValue(List<CityPoiModel>.unmodifiable(currentPois));
    errorMessage.addValue(null);
    latestOffer.addValue(null);

    if (selectedPoiStreamValue.value?.id == poiId) {
      selectedPoiStreamValue.addValue(currentPois[index]);
    }
  }

  bool get hasError => (errorMessage.value?.isNotEmpty ?? false);
  String? get currentErrorMessage => errorMessage.value;
  List<CityPoiModel> get currentPois =>
      List<CityPoiModel>.unmodifiable(pois.value);

  PoiQuery get currentQuery => _currentQuery;

  Future<void> reload() => loadPois(_currentQuery);

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void onDispose() {
    eventsStreamValue.dispose();
    isLoading.dispose();
    pois.dispose();
    errorMessage.dispose();
    latestOffer.dispose();
    selectedPoiStreamValue.dispose();
    selectedEventStreamValue.dispose();
    _poiEventsSubscription?.cancel();
  }

  void _setLoadingState() {
    isLoading.addValue(true);
    errorMessage.addValue(null);
    latestOffer.addValue(null);
  }

  void _setSuccessState(List<CityPoiModel> newPois) {
    isLoading.addValue(false);
    errorMessage.addValue(null);
    latestOffer.addValue(null);
    pois.addValue(List<CityPoiModel>.unmodifiable(newPois));
  }

  void _setErrorState(String message) {
    isLoading.addValue(false);
    errorMessage.addValue(message);
    latestOffer.addValue(null);
  }
}
