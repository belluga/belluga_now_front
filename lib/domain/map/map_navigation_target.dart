import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/map_zoom_value.dart';

class MapNavigationTarget {
  const MapNavigationTarget({
    required this.center,
    required this.zoomValue,
  });

  final CityCoordinate center;
  final MapZoomValue zoomValue;

  double get zoom => zoomValue.value;
}
