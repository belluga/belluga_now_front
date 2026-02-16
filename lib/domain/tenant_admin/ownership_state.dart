enum TenantAdminOwnershipState {
  tenantOwned('Do tenant', 'tenant_owned'),
  unmanaged('Nao gerenciadas', 'unmanaged'),
  userOwned('Do usuario', 'user_owned');

  const TenantAdminOwnershipState(this.label, this.apiValue);

  final String label;
  final String apiValue;

  String get subtitle => apiValue;

  static TenantAdminOwnershipState fromApiValue(String? value) {
    final parsed = tryFromApiValue(value);
    if (parsed != null) {
      return parsed;
    }
    throw FormatException('Invalid ownership_state value: $value');
  }

  static TenantAdminOwnershipState? tryFromApiValue(String? value) {
    switch (value) {
      case 'tenant_owned':
        return TenantAdminOwnershipState.tenantOwned;
      case 'unmanaged':
        return TenantAdminOwnershipState.unmanaged;
      case 'user_owned':
        return TenantAdminOwnershipState.userOwned;
    }
    return null;
  }
}
