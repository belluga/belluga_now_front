export 'value_objects/tenant_admin_ownership_state_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_token_value.dart';

typedef OwnershipStatePrimString = String;
typedef OwnershipStatePrimInt = int;
typedef OwnershipStatePrimBool = bool;
typedef OwnershipStatePrimDouble = double;
typedef OwnershipStatePrimDateTime = DateTime;
typedef OwnershipStatePrimDynamic = dynamic;

enum TenantAdminOwnershipState {
  tenantOwned,
  unmanaged,
  userOwned;

  TenantAdminTokenValue get labelValue => switch (this) {
        TenantAdminOwnershipState.tenantOwned =>
          TenantAdminTokenValue('Do tenant'),
        TenantAdminOwnershipState.unmanaged =>
          TenantAdminTokenValue('Nao gerenciadas'),
        TenantAdminOwnershipState.userOwned =>
          TenantAdminTokenValue('Do usuario'),
      };

  TenantAdminTokenValue get apiValueValue => switch (this) {
        TenantAdminOwnershipState.tenantOwned =>
          TenantAdminTokenValue('tenant_owned'),
        TenantAdminOwnershipState.unmanaged =>
          TenantAdminTokenValue('unmanaged'),
        TenantAdminOwnershipState.userOwned =>
          TenantAdminTokenValue('user_owned'),
      };

  OwnershipStatePrimString get label => labelValue.value;
  OwnershipStatePrimString get apiValue => apiValueValue.value;

  OwnershipStatePrimString get subtitle => apiValue;

  static TenantAdminOwnershipState fromApiToken(
    TenantAdminTokenValue? value,
  ) {
    final parsed = tryFromApiToken(value);
    if (parsed != null) {
      return parsed;
    }
    throw FormatException(
      'Invalid ownership_state value: ${value?.value ?? ''}',
    );
  }

  static TenantAdminOwnershipState? tryFromApiToken(
    TenantAdminTokenValue? value,
  ) {
    final token = _normalizeApiValue(value);
    switch (token) {
      case 'tenant_owned':
        return TenantAdminOwnershipState.tenantOwned;
      case 'unmanaged':
        return TenantAdminOwnershipState.unmanaged;
      case 'user_owned':
        return TenantAdminOwnershipState.userOwned;
    }
    return null;
  }

  static String? _normalizeApiValue(TenantAdminTokenValue? raw) {
    if (raw == null) {
      return null;
    }
    return raw.value.trim().toLowerCase();
  }
}
