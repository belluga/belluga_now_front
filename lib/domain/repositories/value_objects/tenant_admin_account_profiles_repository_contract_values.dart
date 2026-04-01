export 'tenant_admin_account_profiles_repository_contract_bool_value.dart';
export 'tenant_admin_account_profiles_repository_contract_int_value.dart';
export 'tenant_admin_account_profiles_repository_contract_text_value.dart';

import 'tenant_admin_account_profiles_repository_contract_bool_value.dart';
import 'tenant_admin_account_profiles_repository_contract_int_value.dart';
import 'tenant_admin_account_profiles_repository_contract_text_value.dart';

TenantAdminAccountProfilesRepositoryContractTextValue
    tenantAdminAccountProfilesRepoString(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = false,
}) {
  if (raw is TenantAdminAccountProfilesRepositoryContractTextValue) {
    return raw;
  }
  return TenantAdminAccountProfilesRepositoryContractTextValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TenantAdminAccountProfilesRepositoryContractIntValue
    tenantAdminAccountProfilesRepoInt(
  Object? raw, {
  int defaultValue = 0,
  bool isRequired = true,
}) {
  if (raw is TenantAdminAccountProfilesRepositoryContractIntValue) {
    return raw;
  }
  return TenantAdminAccountProfilesRepositoryContractIntValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TenantAdminAccountProfilesRepositoryContractBoolValue
    tenantAdminAccountProfilesRepoBool(
  Object? raw, {
  bool defaultValue = false,
  bool isRequired = true,
}) {
  if (raw is TenantAdminAccountProfilesRepositoryContractBoolValue) {
    return raw;
  }
  return TenantAdminAccountProfilesRepositoryContractBoolValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}
