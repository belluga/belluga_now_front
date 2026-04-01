import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';

TenantAdminLocation tenantAdminLocationFromRaw({
  required Object? latitude,
  required Object? longitude,
}) {
  final latitudeValue = LatitudeValue()..parse(latitude.toString());
  final longitudeValue = LongitudeValue()..parse(longitude.toString());
  return TenantAdminLocation(
    latitudeValue: latitudeValue,
    longitudeValue: longitudeValue,
  );
}
