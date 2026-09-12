import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

class BellugaMapViewport {
  const BellugaMapViewport({required this.northEast, required this.southWest});

  final CityCoordinate northEast;
  final CityCoordinate southWest;
}
