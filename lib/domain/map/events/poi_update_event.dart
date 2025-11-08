import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';

part 'poi_moved_event.dart';
part 'poi_offer_activated_event.dart';

sealed class PoiUpdateEvent {
  const PoiUpdateEvent(this.poiIdValue);

  final CityPoiIdValue poiIdValue;

  String get poiId => poiIdValue.value;
}
