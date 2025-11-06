import 'dart:async';

import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/fab_menu_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class EventsPanelController implements Disposable {
  EventsPanelController({
    CityMapController? mapController,
    FabMenuController? fabMenuController,
  })  : _mapController = mapController ?? GetIt.I.get<CityMapController>(),
        _fabMenuController =
            fabMenuController ?? GetIt.I.get<FabMenuController>(),
        events = StreamValue<List<EventModel>>(defaultValue: const []) {
    _subscription = _mapController.eventsStreamValue.stream.listen(_syncEvents);
    _syncEvents(_mapController.eventsStreamValue.value);
  }

  final CityMapController _mapController;
  final FabMenuController _fabMenuController;

  final StreamValue<List<EventModel>> events;
  StreamSubscription<List<EventModel>>? _subscription;

  void selectEvent(EventModel event) {
    _mapController.selectEvent(event);
    _fabMenuController.closePanel();
  }

  SharePayload buildSharePayload(EventModel event) {
    return _mapController.buildEventSharePayload(event);
  }

  Future<DirectionsInfo?> prepareDirections(EventModel event) {
    final directions = _mapController.prepareEventDirections(event);
    _fabMenuController.closePanel();
    return directions;
  }

  Future<bool> launchRideShareOption(RideShareOption option) {
    return _mapController.launchRideShareOption(option);
  }

  @override
  void onDispose() {
    events.dispose();
    _subscription?.cancel();
  }

  void _syncEvents(List<EventModel> source) {
    events.addValue(filterEvents(source));
  }

  List<EventModel> filterEvents(List<EventModel> items) => items;
}
