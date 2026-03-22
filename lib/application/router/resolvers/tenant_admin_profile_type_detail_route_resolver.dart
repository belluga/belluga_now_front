import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class TenantAdminProfileTypeDetailRouteResolver
    implements RouteModelResolver<TenantAdminProfileTypeDefinition> {
  TenantAdminProfileTypeDetailRouteResolver({
    @visibleForTesting
    TenantAdminAccountProfilesRepositoryContract? accountProfilesRepository,
  }) : _accountProfilesRepository = accountProfilesRepository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>();

  final TenantAdminAccountProfilesRepositoryContract _accountProfilesRepository;

  @override
  Future<TenantAdminProfileTypeDefinition> resolve(
    RouteResolverParams params,
  ) async {
    final profileType = params['profileType'] as String?;
    if (profileType == null || profileType.trim().isEmpty) {
      throw ArgumentError.value(
        profileType,
        'profileType',
        'Profile type must be provided',
      );
    }

    return _accountProfilesRepository.fetchProfileType(profileType.trim());
  }
}
