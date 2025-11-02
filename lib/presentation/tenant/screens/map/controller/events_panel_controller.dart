import 'dart:async';

import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/fab_menu_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class EventsPanelController implements Disposable {
  EventsPanelController({
    CityMapController? mapController,
    FabMenuController? fabMenuController,
  })  : _mapController = mapController ?? GetIt.I.get<CityMapController>(),
        _fabMenuController = fabMenuController ?? GetIt.I.get<FabMenuController>(),
        events = StreamValue<List<EventModel>>(defaultValue: const []) {
    _subscription = _mapController.eventsStreamValue.stream.listen(_syncEvents);
    _syncEvents(_mapController.eventsStreamValue.value);
  }

  final CityMapController _mapController;
  final FabMenuController _fabMenuController;

  final StreamValue<List<EventModel>> events;
  StreamSubscription<List<EventModel>?>? _subscription;

  void selectEvent(EventModel event) {
    _mapController.selectEvent(event);
    _fabMenuController.closePanel();
  }

  void shareEvent(EventModel event) {
    _mapController.shareEvent(event);
  }

  void routeToEvent(EventModel event, BuildContext context) {
    _mapController.getDirectionsToEvent(event, context);
    _fabMenuController.closePanel();
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
