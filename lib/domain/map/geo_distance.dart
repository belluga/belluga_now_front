import 'dart:math' as math;

import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';

DistanceInMetersValue haversineDistanceMeters({
  required CityCoordinate coordinateA,
  required CityCoordinate coordinateB,
}) {
  const earthRadiusMeters = 6371000.0;
  final lat1 = coordinateA.latitude;
  final lon1 = coordinateA.longitude;
  final lat2 = coordinateB.latitude;
  final lon2 = coordinateB.longitude;

  final lat1Rad = lat1 * (math.pi / 180.0);
  final lat2Rad = lat2 * (math.pi / 180.0);
  final dLat = (lat2 - lat1) * (math.pi / 180.0);
  final dLon = (lon2 - lon1) * (math.pi / 180.0);

  final sinDLat = math.sin(dLat / 2);
  final sinDLon = math.sin(dLon / 2);

  final h = sinDLat * sinDLat +
      math.cos(lat1Rad) * math.cos(lat2Rad) * sinDLon * sinDLon;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));

  final value = DistanceInMetersValue();
  value.parse((earthRadiusMeters * c).toString());
  return value;
}
