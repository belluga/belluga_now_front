import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

TenantAdminPagedResult<T> tenantAdminPagedResultFromRaw<T>({
  required List<T> items,
  required Object? hasMore,
}) {
  return TenantAdminPagedResult<T>(
    items: items,
    hasMoreValue: tenantAdminFlag(hasMore),
  );
}

TenantAdminPagedAccountsResult tenantAdminPagedAccountsResultFromRaw({
  required List<TenantAdminAccount> accounts,
  required Object? hasMore,
}) {
  return TenantAdminPagedAccountsResult(
    accounts: accounts,
    hasMoreValue: tenantAdminFlag(hasMore),
  );
}
