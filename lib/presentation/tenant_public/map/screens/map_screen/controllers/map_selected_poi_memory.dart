import 'package:belluga_now/domain/map/city_poi_model.dart';

class MapSelectedPoiMemory {
  const MapSelectedPoiMemory({
    required this.poiId,
    required this.stackKey,
  });

  factory MapSelectedPoiMemory.fromPoi(CityPoiModel poi) {
    return MapSelectedPoiMemory(
      poiId: poi.id,
      stackKey: poi.stackKey,
    );
  }

  final String poiId;
  final String stackKey;
}
