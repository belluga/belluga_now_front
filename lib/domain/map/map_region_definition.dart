import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

class MapRegionDefinition {
  const MapRegionDefinition({
    required this.id,
    required this.label,
    required this.center,
    required this.zoom,
    this.boundsDelta = 0.08,
  });

  final String id;
  final String label;
  final CityCoordinate center;
  final double zoom;
  final double boundsDelta;
}
