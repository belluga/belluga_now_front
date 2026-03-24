import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

typedef TenantAdminMapDefaultOriginPrimString = String;
typedef TenantAdminMapDefaultOriginPrimInt = int;
typedef TenantAdminMapDefaultOriginPrimBool = bool;
typedef TenantAdminMapDefaultOriginPrimDouble = double;
typedef TenantAdminMapDefaultOriginPrimDateTime = DateTime;
typedef TenantAdminMapDefaultOriginPrimDynamic = dynamic;

class TenantAdminMapDefaultOrigin {
  TenantAdminMapDefaultOrigin({
    required TenantAdminMapDefaultOriginPrimDouble lat,
    required TenantAdminMapDefaultOriginPrimDouble lng,
    TenantAdminMapDefaultOriginPrimString? label,
  })  : latitudeValue = _buildLatitudeValue(lat),
        longitudeValue = _buildLongitudeValue(lng),
        labelValue = _buildLabelValue(label);

  final LatitudeValue latitudeValue;
  final LongitudeValue longitudeValue;
  final TenantAdminOptionalTextValue? labelValue;

  TenantAdminMapDefaultOriginPrimDouble get lat => latitudeValue.value;
  TenantAdminMapDefaultOriginPrimDouble get lng => longitudeValue.value;
  TenantAdminMapDefaultOriginPrimString? get label => labelValue?.nullableValue;

  Map<TenantAdminMapDefaultOriginPrimString,
      TenantAdminMapDefaultOriginPrimDynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (label != null) 'label': label,
    };
  }

  static LatitudeValue _buildLatitudeValue(
      TenantAdminMapDefaultOriginPrimDouble raw) {
    final value = LatitudeValue()..parse(raw.toString());
    return value;
  }

  static LongitudeValue _buildLongitudeValue(
      TenantAdminMapDefaultOriginPrimDouble raw) {
    final value = LongitudeValue()..parse(raw.toString());
    return value;
  }

  static TenantAdminOptionalTextValue? _buildLabelValue(
      TenantAdminMapDefaultOriginPrimString? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalTextValue()..parse(normalized);
    return value;
  }
}
