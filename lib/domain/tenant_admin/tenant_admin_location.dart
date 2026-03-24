import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';

class TenantAdminLocation {
  TenantAdminLocation({
    required Object latitude,
    required Object longitude,
  })  : latitudeValue = LatitudeValue()..parse(latitude.toString()),
        longitudeValue = LongitudeValue()..parse(longitude.toString());

  final LatitudeValue latitudeValue;
  final LongitudeValue longitudeValue;

  double get latitude => latitudeValue.value;
  double get longitude => longitudeValue.value;
}
