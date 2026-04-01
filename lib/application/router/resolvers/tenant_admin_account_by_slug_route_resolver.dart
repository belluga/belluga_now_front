import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class TenantAdminAccountBySlugRouteResolver
    implements RouteModelResolver<TenantAdminAccount> {
  TenantAdminAccountBySlugRouteResolver({
    @visibleForTesting
    TenantAdminAccountsRepositoryContract? accountsRepository,
  }) : _accountsRepository = accountsRepository ??
            GetIt.I.get<TenantAdminAccountsRepositoryContract>();

  final TenantAdminAccountsRepositoryContract _accountsRepository;

  @override
  Future<TenantAdminAccount> resolve(RouteResolverParams params) async {
    final accountSlug = params['accountSlug'] as String?;
    if (accountSlug == null || accountSlug.trim().isEmpty) {
      throw ArgumentError.value(
        accountSlug,
        'accountSlug',
        'Account slug must be provided',
      );
    }

    return _accountsRepository.fetchAccountBySlug(
      TenantAdminAccountsRepositoryContractPrimString.fromRaw(
        accountSlug.trim(),
      ),
    );
  }
}
