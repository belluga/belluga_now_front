part of 'poi_update_event.dart';

class PoiOfferActivatedEvent extends PoiUpdateEvent {
  const PoiOfferActivatedEvent({
    required CityPoiIdValue poiIdValue,
    required this.detailsValue,
    required this.iconSymbolValue,
  }) : super(poiIdValue);

  final DescriptionValue detailsValue;
  final PoiIconSymbolValue iconSymbolValue;

  String get details => detailsValue.value;

  String get iconSymbol => iconSymbolValue.value;
}
