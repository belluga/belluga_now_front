import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';

abstract class TenantAdminAccountsRepositoryContract {
  Future<List<TenantAdminAccount>> fetchAccounts();
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug);
  Future<TenantAdminAccount> createAccount({
    required String name,
    required TenantAdminDocument document,
    String? organizationId,
  });
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    TenantAdminDocument? document,
  });
  Future<void> deleteAccount(String accountSlug);
  Future<TenantAdminAccount> restoreAccount(String accountSlug);
  Future<void> forceDeleteAccount(String accountSlug);
}
