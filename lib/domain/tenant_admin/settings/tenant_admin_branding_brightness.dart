enum TenantAdminBrandingBrightness {
  light,
  dark;

  String get rawValue => switch (this) {
        TenantAdminBrandingBrightness.light => 'light',
        TenantAdminBrandingBrightness.dark => 'dark',
      };

  static TenantAdminBrandingBrightness fromRaw(String? raw) {
    if (raw?.trim().toLowerCase() == 'dark') {
      return TenantAdminBrandingBrightness.dark;
    }
    return TenantAdminBrandingBrightness.light;
  }
}
