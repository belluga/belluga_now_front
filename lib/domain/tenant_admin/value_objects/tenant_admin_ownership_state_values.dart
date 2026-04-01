import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_token_value.dart';

TenantAdminTokenValue? tenantAdminOwnershipStateTokenFromRaw(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is TenantAdminTokenValue) {
    return TenantAdminTokenValue(raw.value);
  }
  return TenantAdminTokenValue(raw.toString().trim().toLowerCase());
}

TenantAdminOwnershipState tenantAdminOwnershipStateFromRaw(Object? raw) {
  return TenantAdminOwnershipState.fromApiToken(
    tenantAdminOwnershipStateTokenFromRaw(raw),
  );
}

TenantAdminOwnershipState? tenantAdminOwnershipStateTryFromRaw(Object? raw) {
  return TenantAdminOwnershipState.tryFromApiToken(
    tenantAdminOwnershipStateTokenFromRaw(raw),
  );
}
