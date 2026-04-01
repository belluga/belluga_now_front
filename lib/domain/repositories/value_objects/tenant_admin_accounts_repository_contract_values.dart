export 'tenant_admin_accounts_repository_contract_bool_value.dart';
export 'tenant_admin_accounts_repository_contract_int_value.dart';
export 'tenant_admin_accounts_repository_contract_text_value.dart';

import 'tenant_admin_accounts_repository_contract_bool_value.dart';
import 'tenant_admin_accounts_repository_contract_int_value.dart';
import 'tenant_admin_accounts_repository_contract_text_value.dart';

TenantAdminAccountsRepositoryContractTextValue tenantAdminAccountsRepoString(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = false,
}) {
  if (raw is TenantAdminAccountsRepositoryContractTextValue) {
    return raw;
  }
  return TenantAdminAccountsRepositoryContractTextValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TenantAdminAccountsRepositoryContractIntValue tenantAdminAccountsRepoInt(
  Object? raw, {
  int defaultValue = 0,
  bool isRequired = true,
}) {
  if (raw is TenantAdminAccountsRepositoryContractIntValue) {
    return raw;
  }
  return TenantAdminAccountsRepositoryContractIntValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TenantAdminAccountsRepositoryContractBoolValue tenantAdminAccountsRepoBool(
  Object? raw, {
  bool defaultValue = false,
  bool isRequired = true,
}) {
  if (raw is TenantAdminAccountsRepositoryContractBoolValue) {
    return raw;
  }
  return TenantAdminAccountsRepositoryContractBoolValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}
