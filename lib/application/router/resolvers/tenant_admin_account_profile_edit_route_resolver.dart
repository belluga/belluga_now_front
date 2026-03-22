import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class TenantAdminAccountProfileEditRouteResolver
    implements RouteModelResolver<TenantAdminAccountProfile> {
  TenantAdminAccountProfileEditRouteResolver({
    @visibleForTesting
    TenantAdminAccountProfilesRepositoryContract? accountProfilesRepository,
  }) : _accountProfilesRepository = accountProfilesRepository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>();

  final TenantAdminAccountProfilesRepositoryContract _accountProfilesRepository;

  @override
  Future<TenantAdminAccountProfile> resolve(RouteResolverParams params) async {
    final accountSlug = params['accountSlug'] as String?;
    final accountProfileId = params['accountProfileId'] as String?;
    if (accountSlug == null || accountSlug.trim().isEmpty) {
      throw ArgumentError.value(
        accountSlug,
        'accountSlug',
        'Account slug must be provided',
      );
    }
    if (accountProfileId == null || accountProfileId.trim().isEmpty) {
      throw ArgumentError.value(
        accountProfileId,
        'accountProfileId',
        'Account profile id must be provided',
      );
    }

    return _accountProfilesRepository.fetchAccountProfile(
      accountProfileId.trim(),
    );
  }
}
