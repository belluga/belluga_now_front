import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

class PoiQuery {
  const PoiQuery({
    this.northEast,
    this.southWest,
    this.categories,
    this.tags,
    this.searchTerm,
  });

  final CityCoordinate? northEast;
  final CityCoordinate? southWest;
  final Set<CityPoiCategory>? categories;
  final Set<String>? tags;
  final String? searchTerm;

  bool get hasBounds => northEast != null && southWest != null;

  bool matchesCategory(CityPoiCategory category) {
    final set = categories;
    if (set == null || set.isEmpty) {
      return true;
    }
    return set.contains(category);
  }

  bool matchesTags(Iterable<String> poiTags) {
    final set = tags;
    if (set == null || set.isEmpty) {
      return true;
    }
    if (poiTags.isEmpty) {
      return false;
    }
    return set.every(
      (tag) => poiTags.any(
        (poiTag) => poiTag.toLowerCase() == tag.toLowerCase(),
      ),
    );
  }

  bool containsCoordinate(CityCoordinate coordinate) {
    if (!hasBounds) {
      return true;
    }
    final north = northEast!.latitude;
    final east = northEast!.longitude;
    final south = southWest!.latitude;
    final west = southWest!.longitude;

    final lat = coordinate.latitude;
    final lon = coordinate.longitude;

    final withinLat = lat <= north && lat >= south;
    final withinLon = west <= east
        ? lon >= west && lon <= east
        : lon >= west || lon <= east;

    return withinLat && withinLon;
  }
}
