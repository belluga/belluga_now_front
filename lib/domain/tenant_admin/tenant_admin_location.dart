export 'value_objects/tenant_admin_location_values.dart';

import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';

class TenantAdminLocation {
  TenantAdminLocation({
    required this.latitudeValue,
    required this.longitudeValue,
  });

  final LatitudeValue latitudeValue;
  final LongitudeValue longitudeValue;

  double get latitude => latitudeValue.value;
  double get longitude => longitudeValue.value;
}
