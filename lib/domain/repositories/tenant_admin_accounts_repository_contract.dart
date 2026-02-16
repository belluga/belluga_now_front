import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';

abstract class TenantAdminAccountsRepositoryContract {
  Future<List<TenantAdminAccount>> fetchAccounts();
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required int page,
    required int pageSize,
  }) async {
    final accounts = await fetchAccounts();
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedAccountsResult(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= accounts.length) {
      return const TenantAdminPagedAccountsResult(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, accounts.length);
    return TenantAdminPagedAccountsResult(
      accounts: accounts.sublist(startIndex, endIndex),
      hasMore: endIndex < accounts.length,
    );
  }

  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug);
  Future<TenantAdminAccount> createAccount({
    required String name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  });
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminDocument? document,
  });
  Future<void> deleteAccount(String accountSlug);
  Future<TenantAdminAccount> restoreAccount(String accountSlug);
  Future<void> forceDeleteAccount(String accountSlug);
}
