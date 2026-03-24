import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_branding_brightness.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

typedef TenantAdminBrandingSettingsPrimString = String;
typedef TenantAdminBrandingSettingsPrimInt = int;
typedef TenantAdminBrandingSettingsPrimBool = bool;
typedef TenantAdminBrandingSettingsPrimDouble = double;
typedef TenantAdminBrandingSettingsPrimDateTime = DateTime;
typedef TenantAdminBrandingSettingsPrimDynamic = dynamic;

class TenantAdminBrandingSettings {
  TenantAdminBrandingSettings({
    required TenantAdminBrandingSettingsPrimString tenantName,
    required this.brightnessDefault,
    required TenantAdminBrandingSettingsPrimString primarySeedColor,
    required TenantAdminBrandingSettingsPrimString secondarySeedColor,
    TenantAdminBrandingSettingsPrimString? lightLogoUrl,
    TenantAdminBrandingSettingsPrimString? darkLogoUrl,
    TenantAdminBrandingSettingsPrimString? lightIconUrl,
    TenantAdminBrandingSettingsPrimString? darkIconUrl,
    TenantAdminBrandingSettingsPrimString? faviconUrl,
    TenantAdminBrandingSettingsPrimString? pwaIconUrl,
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

  TenantAdminBrandingSettingsPrimString get tenantName => tenantNameValue.value;
  TenantAdminBrandingSettingsPrimString get primarySeedColor =>
      primarySeedColorValue.value;
  TenantAdminBrandingSettingsPrimString get secondarySeedColor =>
      secondarySeedColorValue.value;
  TenantAdminBrandingSettingsPrimString? get lightLogoUrl =>
      lightLogoUrlValue?.nullableValue;
  TenantAdminBrandingSettingsPrimString? get darkLogoUrl =>
      darkLogoUrlValue?.nullableValue;
  TenantAdminBrandingSettingsPrimString? get lightIconUrl =>
      lightIconUrlValue?.nullableValue;
  TenantAdminBrandingSettingsPrimString? get darkIconUrl =>
      darkIconUrlValue?.nullableValue;
  TenantAdminBrandingSettingsPrimString? get faviconUrl =>
      faviconUrlValue?.nullableValue;
  TenantAdminBrandingSettingsPrimString? get pwaIconUrl =>
      pwaIconUrlValue?.nullableValue;

  static TenantAdminRequiredTextValue _buildRequiredTextValue(
      TenantAdminBrandingSettingsPrimString raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }

  static TenantAdminHexColorValue _buildHexColorValue(
      TenantAdminBrandingSettingsPrimString raw) {
    final value = TenantAdminHexColorValue()..parse(raw);
    return value;
  }

  static TenantAdminOptionalUrlValue? _buildOptionalUrlValue(
      TenantAdminBrandingSettingsPrimString? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalUrlValue()..parse(normalized);
    return value;
  }
}
