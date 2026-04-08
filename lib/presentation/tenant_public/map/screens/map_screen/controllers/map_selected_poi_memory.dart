import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';

class MapSelectedPoiMemory {
  const MapSelectedPoiMemory({
    required this.poiId,
    required this.stackKey,
    this.visual,
  });

  factory MapSelectedPoiMemory.fromPoi(CityPoiModel poi) {
    return MapSelectedPoiMemory(
      poiId: poi.id,
      stackKey: poi.stackKey,
      visual: poi.visual,
    );
  }

  final String poiId;
  final String stackKey;
  final CityPoiVisual? visual;
}
