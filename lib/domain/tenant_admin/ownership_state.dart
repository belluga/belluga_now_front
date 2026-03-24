import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_token_value.dart';

typedef OwnershipStatePrimString = String;
typedef OwnershipStatePrimInt = int;
typedef OwnershipStatePrimBool = bool;
typedef OwnershipStatePrimDouble = double;
typedef OwnershipStatePrimDateTime = DateTime;
typedef OwnershipStatePrimDynamic = dynamic;

enum TenantAdminOwnershipState {
  tenantOwned(
    TenantAdminTokenValue('Do tenant'),
    TenantAdminTokenValue('tenant_owned'),
  ),
  unmanaged(
    TenantAdminTokenValue('Nao gerenciadas'),
    TenantAdminTokenValue('unmanaged'),
  ),
  userOwned(
    TenantAdminTokenValue('Do usuario'),
    TenantAdminTokenValue('user_owned'),
  );

  const TenantAdminOwnershipState(this.labelValue, this.apiValueValue);

  final TenantAdminTokenValue labelValue;
  final TenantAdminTokenValue apiValueValue;

  OwnershipStatePrimString get label => labelValue.value;
  OwnershipStatePrimString get apiValue => apiValueValue.value;

  OwnershipStatePrimString get subtitle => apiValue;

  static TenantAdminOwnershipState fromApiValue(
      OwnershipStatePrimString? value) {
    final parsed = tryFromApiValue(value);
    if (parsed != null) {
      return parsed;
    }
    throw FormatException('Invalid ownership_state value: $value');
  }

  static TenantAdminOwnershipState? tryFromApiValue(
      OwnershipStatePrimString? value) {
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
