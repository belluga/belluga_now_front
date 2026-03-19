import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminMapDefaultOrigin {
  TenantAdminMapDefaultOrigin({
    required double lat,
    required double lng,
    String? label,
  })  : latitudeValue = _buildLatitudeValue(lat),
        longitudeValue = _buildLongitudeValue(lng),
        labelValue = _buildLabelValue(label);

  final LatitudeValue latitudeValue;
  final LongitudeValue longitudeValue;
  final TenantAdminOptionalTextValue? labelValue;

  double get lat => latitudeValue.value;
  double get lng => longitudeValue.value;
  String? get label => labelValue?.nullableValue;

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (label != null) 'label': label,
    };
  }

  static LatitudeValue _buildLatitudeValue(double raw) {
    final value = LatitudeValue()..parse(raw.toString());
    return value;
  }

  static LongitudeValue _buildLongitudeValue(double raw) {
    final value = LongitudeValue()..parse(raw.toString());
    return value;
  }

  static TenantAdminOptionalTextValue? _buildLabelValue(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalTextValue()..parse(normalized);
    return value;
  }
}
