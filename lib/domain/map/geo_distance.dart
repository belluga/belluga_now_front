import 'dart:math' as math;

double haversineDistanceMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadiusMeters = 6371000.0;
  final lat1Rad = _degToRad(lat1);
  final lat2Rad = _degToRad(lat2);
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);

  final sinDLat = math.sin(dLat / 2);
  final sinDLon = math.sin(dLon / 2);

  final h = sinDLat * sinDLat +
      math.cos(lat1Rad) * math.cos(lat2Rad) * sinDLon * sinDLon;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadiusMeters * c;
}

double _degToRad(double deg) => deg * (math.pi / 180.0);

