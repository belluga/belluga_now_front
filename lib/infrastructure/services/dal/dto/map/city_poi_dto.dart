import 'package:belluga_now/domain/map/city_poi_category.dart';

class CityPoiDTO {
  const CityPoiDTO({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String description;
  final String address;
  final CityPoiCategory category;
  final double latitude;
  final double longitude;
}
