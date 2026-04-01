import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';

enum TenantAdminBrandingBrightness {
  light,
  dark;

  String get rawValue => switch (this) {
        TenantAdminBrandingBrightness.light => 'light',
        TenantAdminBrandingBrightness.dark => 'dark',
      };

  static TenantAdminBrandingBrightness fromRaw(
      TenantAdminLowercaseTokenValue? raw) {
    if (raw?.value == 'dark') {
      return TenantAdminBrandingBrightness.dark;
    }
    return TenantAdminBrandingBrightness.light;
  }
}
