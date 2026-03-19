enum TenantAdminMapFilterSource {
  accountProfile('account_profile', 'Conta'),
  staticAsset('static_asset', 'Asset'),
  event('event', 'Evento');

  const TenantAdminMapFilterSource(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TenantAdminMapFilterSource? fromRaw(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    for (final candidate in TenantAdminMapFilterSource.values) {
      if (candidate.apiValue == normalized) {
        return candidate;
      }
    }
    return null;
  }
}
