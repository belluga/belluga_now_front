import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';

class CityCoordinate {
  const CityCoordinate({
    required this.latitudeValue,
    required this.longitudeValue,
  });

  final LatitudeValue latitudeValue;
  final LongitudeValue longitudeValue;

  double get latitude => latitudeValue.value;

  double get longitude => longitudeValue.value;
}
