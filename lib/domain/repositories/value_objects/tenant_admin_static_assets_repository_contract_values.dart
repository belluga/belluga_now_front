export 'tenant_admin_static_assets_repository_contract_bool_value.dart';
export 'tenant_admin_static_assets_repository_contract_int_value.dart';
export 'tenant_admin_static_assets_repository_contract_text_value.dart';

import 'tenant_admin_static_assets_repository_contract_text_value.dart';

List<TenantAdminStaticAssetsRepositoryContractTextValue>
    tenantAdminStaticAssetsRepoTextListFromRaw(
  Iterable<String> rawValues,
) {
  return rawValues
      .map(TenantAdminStaticAssetsRepositoryContractTextValue.fromRaw)
      .toList(growable: false);
}

List<String> tenantAdminStaticAssetsRepoRawTextList(
  Iterable<TenantAdminStaticAssetsRepositoryContractTextValue> values,
) {
  return values.map((value) => value.value).toList(growable: false);
}
