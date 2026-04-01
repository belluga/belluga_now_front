import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_branding_brightness.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminBrandingUpdateInput {
  TenantAdminBrandingUpdateInput({
    required TenantAdminRequiredTextValue tenantName,
    required this.brightnessDefault,
    required TenantAdminHexColorValue primarySeedColor,
    required TenantAdminHexColorValue secondarySeedColor,
    this.lightLogoUpload,
    this.darkLogoUpload,
    this.lightIconUpload,
    this.darkIconUpload,
    this.faviconUpload,
    this.pwaIconUpload,
  })  : tenantNameValue = tenantName,
        primarySeedColorValue = primarySeedColor,
        secondarySeedColorValue = secondarySeedColor;

  final TenantAdminRequiredTextValue tenantNameValue;
  final TenantAdminBrandingBrightness brightnessDefault;
  final TenantAdminHexColorValue primarySeedColorValue;
  final TenantAdminHexColorValue secondarySeedColorValue;
  final TenantAdminMediaUpload? lightLogoUpload;
  final TenantAdminMediaUpload? darkLogoUpload;
  final TenantAdminMediaUpload? lightIconUpload;
  final TenantAdminMediaUpload? darkIconUpload;
  final TenantAdminMediaUpload? faviconUpload;
  final TenantAdminMediaUpload? pwaIconUpload;

  String get tenantName => tenantNameValue.value;
  String get primarySeedColor => primarySeedColorValue.value;
  String get secondarySeedColor => secondarySeedColorValue.value;
}
