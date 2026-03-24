import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminPagedAccountsResult {
  TenantAdminPagedAccountsResult({
    required this.accounts,
    required Object hasMore,
  }) : hasMoreValue = tenantAdminFlag(hasMore);

  final List<TenantAdminAccount> accounts;
  final TenantAdminFlagValue hasMoreValue;

  bool get hasMore => hasMoreValue.value;
}
