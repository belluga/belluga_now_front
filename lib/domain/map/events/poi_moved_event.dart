part of 'poi_update_event.dart';

class PoiMovedEvent extends PoiUpdateEvent {
  const PoiMovedEvent({
    required CityPoiIdValue poiIdValue,
    required this.coordinate,
  }) : super(poiIdValue);

  final CityCoordinate coordinate;
}
