import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_branding_brightness.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminBrandingSettings {
  TenantAdminBrandingSettings({
    required TenantAdminRequiredTextValue tenantName,
    required this.brightnessDefault,
    required TenantAdminHexColorValue primarySeedColor,
    required TenantAdminHexColorValue secondarySeedColor,
    TenantAdminOptionalUrlValue? lightLogoUrl,
    TenantAdminOptionalUrlValue? darkLogoUrl,
    TenantAdminOptionalUrlValue? lightIconUrl,
    TenantAdminOptionalUrlValue? darkIconUrl,
    TenantAdminOptionalUrlValue? faviconUrl,
    TenantAdminOptionalUrlValue? pwaIconUrl,
  })  : tenantNameValue = tenantName,
        primarySeedColorValue = primarySeedColor,
        secondarySeedColorValue = secondarySeedColor,
        lightLogoUrlValue = lightLogoUrl,
        darkLogoUrlValue = darkLogoUrl,
        lightIconUrlValue = lightIconUrl,
        darkIconUrlValue = darkIconUrl,
        faviconUrlValue = faviconUrl,
        pwaIconUrlValue = pwaIconUrl;

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
}
