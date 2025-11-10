import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

/// Base contract for any point-of-interest rendered on the map layers.
/// Concrete POI types (city curated points, events, partner spots, etc.)
/// must expose the same spatial + descriptive information so controllers
/// can treat them uniformly for selection and navigation.
abstract class MapPoi {
  String get id;
  String get name;
  String get description;
  String get address;
  CityCoordinate get coordinate;
  CityPoiCategory get category;
  bool get isDynamic;
  int get priority;
  double? get movementRadiusMeters;
  String? get assetPath;
  List<String> get tags;
}
