import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

sealed class PoiUpdateEvent {
  const PoiUpdateEvent(this.poiId);

  final String poiId;
}

class PoiMovedEvent extends PoiUpdateEvent {
  const PoiMovedEvent({required String poiId, required this.coordinate})
      : super(poiId);

  final CityCoordinate coordinate;
}

class PoiOfferActivatedEvent extends PoiUpdateEvent {
  const PoiOfferActivatedEvent({
    required String poiId,
    required this.details,
    required this.icon,
  }) : super(poiId);

  final String details;
  final String icon;
}
