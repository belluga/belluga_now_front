import 'dart:async';

import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class EventsPanelController implements Disposable {
  EventsPanelController({
    CityMapController? mapController,
  })  : _mapController = mapController ?? GetIt.I.get<CityMapController>(),
        events = StreamValue<List<EventModel>>(defaultValue: const []) {
    _subscription = _mapController.eventsStreamValue.stream.listen(_syncEvents);
    _syncEvents(_mapController.eventsStreamValue.value);
  }

  final CityMapController _mapController;

  final StreamValue<List<EventModel>> events;
  StreamSubscription<List<EventModel>?>? _subscription;

  void selectEvent(EventModel event) {
    _mapController.selectEvent(event);
  }

  SharePayload buildSharePayload(EventModel event) {
    return _mapController.buildEventSharePayload(event);
  }

  Future<DirectionsInfo?> prepareDirections(EventModel event) =>
      _mapController.prepareEventDirections(event);

  Future<bool> launchRideShareOption(RideShareOption option) {
    return _mapController.launchRideShareOption(option);
  }

  @override
  void onDispose() {
    events.dispose();
    _subscription?.cancel();
  }

  void _syncEvents(List<EventModel>? source) {
    events.addValue(filterEvents(source ?? const []));
  }

  List<EventModel> filterEvents(List<EventModel> items) => items;
}
