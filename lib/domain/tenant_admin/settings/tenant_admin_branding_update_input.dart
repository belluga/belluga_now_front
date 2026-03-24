import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_branding_brightness.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

typedef TenantAdminBrandingUpdateInputPrimString = String;
typedef TenantAdminBrandingUpdateInputPrimInt = int;
typedef TenantAdminBrandingUpdateInputPrimBool = bool;
typedef TenantAdminBrandingUpdateInputPrimDouble = double;
typedef TenantAdminBrandingUpdateInputPrimDateTime = DateTime;
typedef TenantAdminBrandingUpdateInputPrimDynamic = dynamic;

class TenantAdminBrandingUpdateInput {
  TenantAdminBrandingUpdateInput({
    required TenantAdminBrandingUpdateInputPrimString tenantName,
    required this.brightnessDefault,
    required TenantAdminBrandingUpdateInputPrimString primarySeedColor,
    required TenantAdminBrandingUpdateInputPrimString secondarySeedColor,
    this.lightLogoUpload,
    this.darkLogoUpload,
    this.lightIconUpload,
    this.darkIconUpload,
    this.faviconUpload,
    this.pwaIconUpload,
  })  : tenantNameValue = _buildRequiredTextValue(tenantName),
        primarySeedColorValue = _buildHexColorValue(primarySeedColor),
        secondarySeedColorValue = _buildHexColorValue(secondarySeedColor);

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

  TenantAdminBrandingUpdateInputPrimString get tenantName =>
      tenantNameValue.value;
  TenantAdminBrandingUpdateInputPrimString get primarySeedColor =>
      primarySeedColorValue.value;
  TenantAdminBrandingUpdateInputPrimString get secondarySeedColor =>
      secondarySeedColorValue.value;

  static TenantAdminRequiredTextValue _buildRequiredTextValue(
      TenantAdminBrandingUpdateInputPrimString raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }

  static TenantAdminHexColorValue _buildHexColorValue(
      TenantAdminBrandingUpdateInputPrimString raw) {
    final value = TenantAdminHexColorValue()..parse(raw);
    return value;
  }
}
