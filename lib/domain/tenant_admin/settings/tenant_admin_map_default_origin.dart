import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminMapDefaultOrigin {
  TenantAdminMapDefaultOrigin({
    required LatitudeValue lat,
    required LongitudeValue lng,
    TenantAdminOptionalTextValue? label,
  })  : latitudeValue = lat,
        longitudeValue = lng,
        labelValue = label;

  final LatitudeValue latitudeValue;
  final LongitudeValue longitudeValue;
  final TenantAdminOptionalTextValue? labelValue;

  double get lat => latitudeValue.value;
  double get lng => longitudeValue.value;
  String? get label => labelValue?.nullableValue;

  Map<String, Object?> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (label != null) 'label': label,
    };
  }
}
