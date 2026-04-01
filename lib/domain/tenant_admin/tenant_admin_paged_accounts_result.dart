import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';

export 'value_objects/tenant_admin_paged_result_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminPagedAccountsResult {
  TenantAdminPagedAccountsResult({
    required this.accounts,
    required this.hasMoreValue,
  });

  final List<TenantAdminAccount> accounts;
  final TenantAdminFlagValue hasMoreValue;

  bool get hasMore => hasMoreValue.value;
}
