export 'tenant_admin_taxonomies_repository_contract_bool_value.dart';
export 'tenant_admin_taxonomies_repository_contract_int_value.dart';
export 'tenant_admin_taxonomies_repository_contract_text_value.dart';

import 'tenant_admin_taxonomies_repository_contract_bool_value.dart';
import 'tenant_admin_taxonomies_repository_contract_int_value.dart';
import 'tenant_admin_taxonomies_repository_contract_text_value.dart';

TenantAdminTaxonomiesRepositoryContractTextValue tenantAdminTaxRepoString(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = false,
}) {
  if (raw is TenantAdminTaxonomiesRepositoryContractTextValue) {
    return raw;
  }
  return TenantAdminTaxonomiesRepositoryContractTextValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TenantAdminTaxonomiesRepositoryContractIntValue tenantAdminTaxRepoInt(
  Object? raw, {
  int defaultValue = 0,
  bool isRequired = true,
}) {
  if (raw is TenantAdminTaxonomiesRepositoryContractIntValue) {
    return raw;
  }
  return TenantAdminTaxonomiesRepositoryContractIntValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TenantAdminTaxonomiesRepositoryContractBoolValue tenantAdminTaxRepoBool(
  Object? raw, {
  bool defaultValue = false,
  bool isRequired = true,
}) {
  if (raw is TenantAdminTaxonomiesRepositoryContractBoolValue) {
    return raw;
  }
  return TenantAdminTaxonomiesRepositoryContractBoolValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

List<TenantAdminTaxonomiesRepositoryContractTextValue>
    tenantAdminTaxRepoTextListFromRaw(
  Iterable<String> rawValues,
) {
  return rawValues
      .map(TenantAdminTaxonomiesRepositoryContractTextValue.fromRaw)
      .toList(growable: false);
}

List<String> tenantAdminTaxRepoRawTextList(
  Iterable<TenantAdminTaxonomiesRepositoryContractTextValue> values,
) {
  return values.map((value) => value.value).toList(growable: false);
}
