import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:latlong2/latlong.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class CityCoordinate extends ValueObject<LatLng> {
  CityCoordinate({
    required this.latitudeValue,
    required this.longitudeValue,
    super.isRequired = true,
  }) : super(
          defaultValue: LatLng(
            latitudeValue.value,
            longitudeValue.value,
          ),
        );

  final LatitudeValue latitudeValue;
  final LongitudeValue longitudeValue;

  double get latitude => latitudeValue.value;
  double get longitude => longitudeValue.value;

  LatLng get latLng => value;

  factory CityCoordinate.fromLatLng(
    LatLng latLng, {
    bool isRequired = true,
  }) {
    final latitude = LatitudeValue()..parse(latLng.latitude.toString());
    final longitude = LongitudeValue()..parse(latLng.longitude.toString());
    return CityCoordinate(
      latitudeValue: latitude,
      longitudeValue: longitude,
      isRequired: isRequired,
    );
  }

  @override
  LatLng doParse(String? parseValue) {
    if (parseValue == null || parseValue.isEmpty) {
      throw InvalidValueException();
    }
    final parts = parseValue.split(',');
    if (parts.length != 2) {
      throw InvalidValueException();
    }
    final latitude = LatitudeValue()..parse(parts[0].trim());
    final longitude = LongitudeValue()..parse(parts[1].trim());
    return LatLng(latitude.value, longitude.value);
  }
}
