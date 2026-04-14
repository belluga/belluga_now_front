import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_branding_brightness.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
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
    TenantAdminBooleanValue? hasDedicatedFaviconValue,
    TenantAdminBooleanValue? usesPwaFaviconFallbackValue,
  })  : tenantNameValue = tenantName,
        primarySeedColorValue = primarySeedColor,
        secondarySeedColorValue = secondarySeedColor,
        lightLogoUrlValue = lightLogoUrl,
        darkLogoUrlValue = darkLogoUrl,
        lightIconUrlValue = lightIconUrl,
        darkIconUrlValue = darkIconUrl,
        faviconUrlValue = faviconUrl,
        pwaIconUrlValue = pwaIconUrl,
        hasDedicatedFaviconValue =
            hasDedicatedFaviconValue ?? _defaultFalseBooleanValue(),
        usesPwaFaviconFallbackValue =
            usesPwaFaviconFallbackValue ?? _defaultFalseBooleanValue();

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
  final TenantAdminBooleanValue hasDedicatedFaviconValue;
  final TenantAdminBooleanValue usesPwaFaviconFallbackValue;

  String get tenantName => tenantNameValue.value;
  String get primarySeedColor => primarySeedColorValue.value;
  String get secondarySeedColor => secondarySeedColorValue.value;
  String? get lightLogoUrl => lightLogoUrlValue?.nullableValue;
  String? get darkLogoUrl => darkLogoUrlValue?.nullableValue;
  String? get lightIconUrl => lightIconUrlValue?.nullableValue;
  String? get darkIconUrl => darkIconUrlValue?.nullableValue;
  String? get faviconUrl => faviconUrlValue?.nullableValue;
  String? get pwaIconUrl => pwaIconUrlValue?.nullableValue;
  bool get hasDedicatedFavicon => hasDedicatedFaviconValue.value;
  bool get usesPwaFaviconFallback => usesPwaFaviconFallbackValue.value;

  static TenantAdminBooleanValue _defaultFalseBooleanValue() {
    final value = TenantAdminBooleanValue();
    value.parse('false');
    return value;
  }
}
