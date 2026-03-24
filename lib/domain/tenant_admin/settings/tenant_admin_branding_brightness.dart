typedef TenantAdminBrandingBrightnessPrimString = String;
typedef TenantAdminBrandingBrightnessPrimInt = int;
typedef TenantAdminBrandingBrightnessPrimBool = bool;
typedef TenantAdminBrandingBrightnessPrimDouble = double;
typedef TenantAdminBrandingBrightnessPrimDateTime = DateTime;
typedef TenantAdminBrandingBrightnessPrimDynamic = dynamic;

enum TenantAdminBrandingBrightness {
  light,
  dark;

  TenantAdminBrandingBrightnessPrimString get rawValue => switch (this) {
        TenantAdminBrandingBrightness.light => 'light',
        TenantAdminBrandingBrightness.dark => 'dark',
      };

  static TenantAdminBrandingBrightness fromRaw(
      TenantAdminBrandingBrightnessPrimString? raw) {
    if (raw?.trim().toLowerCase() == 'dark') {
      return TenantAdminBrandingBrightness.dark;
    }
    return TenantAdminBrandingBrightness.light;
  }
}
