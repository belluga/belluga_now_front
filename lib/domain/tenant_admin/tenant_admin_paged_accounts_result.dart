import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';

class TenantAdminPagedAccountsResult {
  const TenantAdminPagedAccountsResult({
    required this.accounts,
    required this.hasMore,
  });

  final List<TenantAdminAccount> accounts;
  final bool hasMore;
}
