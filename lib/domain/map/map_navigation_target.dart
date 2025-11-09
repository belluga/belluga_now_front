import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

class MapNavigationTarget {
  const MapNavigationTarget({
    required this.center,
    required this.zoom,
  });

  final CityCoordinate center;
  final double zoom;
}
