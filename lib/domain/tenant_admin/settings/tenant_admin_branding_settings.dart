import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_branding_brightness.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminBrandingSettings {
  TenantAdminBrandingSettings({
    required String tenantName,
    required this.brightnessDefault,
    required String primarySeedColor,
    required String secondarySeedColor,
    String? lightLogoUrl,
    String? darkLogoUrl,
    String? lightIconUrl,
    String? darkIconUrl,
    String? faviconUrl,
    String? pwaIconUrl,
  })  : tenantNameValue = _buildRequiredTextValue(tenantName),
        primarySeedColorValue = _buildHexColorValue(primarySeedColor),
        secondarySeedColorValue = _buildHexColorValue(secondarySeedColor),
        lightLogoUrlValue = _buildOptionalUrlValue(lightLogoUrl),
        darkLogoUrlValue = _buildOptionalUrlValue(darkLogoUrl),
        lightIconUrlValue = _buildOptionalUrlValue(lightIconUrl),
        darkIconUrlValue = _buildOptionalUrlValue(darkIconUrl),
        faviconUrlValue = _buildOptionalUrlValue(faviconUrl),
        pwaIconUrlValue = _buildOptionalUrlValue(pwaIconUrl);

  final TenantAdminRequiredTextValue tenantNameValue;
  final TenantAdminBrandingBrightness brightnessDefault;
  final TenantAdminHexColorValue primarySeedColorValue;
  final TenantAdminHexColorValue secondarySeedColorValue;
  final TenantAdminOptionalUrlValue? lightLogoUrlValue;
  final TenantAdminOptionalUrlValue? darkLogoUrlValue;
  final TenantAdminOptionalUrlValue? lightIconUrlValue;
  final TenantAdminOptionalUrlValue? darkIconUrlValue;
  final TenantAdminOptionalUrlValue? faviconUrlValue;
  final TenantAdminOptionalUrlValue? pwaIconUrlValue;

  String get tenantName => tenantNameValue.value;
  String get primarySeedColor => primarySeedColorValue.value;
  String get secondarySeedColor => secondarySeedColorValue.value;
  String? get lightLogoUrl => lightLogoUrlValue?.nullableValue;
  String? get darkLogoUrl => darkLogoUrlValue?.nullableValue;
  String? get lightIconUrl => lightIconUrlValue?.nullableValue;
  String? get darkIconUrl => darkIconUrlValue?.nullableValue;
  String? get faviconUrl => faviconUrlValue?.nullableValue;
  String? get pwaIconUrl => pwaIconUrlValue?.nullableValue;

  static TenantAdminRequiredTextValue _buildRequiredTextValue(String raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }

  static TenantAdminHexColorValue _buildHexColorValue(String raw) {
    final value = TenantAdminHexColorValue()..parse(raw);
    return value;
  }

  static TenantAdminOptionalUrlValue? _buildOptionalUrlValue(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalUrlValue()..parse(normalized);
    return value;
  }
}
