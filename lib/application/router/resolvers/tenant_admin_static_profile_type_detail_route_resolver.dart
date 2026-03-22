import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class TenantAdminStaticProfileTypeDetailRouteResolver
    implements RouteModelResolver<TenantAdminStaticProfileTypeDefinition> {
  TenantAdminStaticProfileTypeDetailRouteResolver({
    @visibleForTesting
    TenantAdminStaticAssetsRepositoryContract? staticAssetsRepository,
  }) : _staticAssetsRepository = staticAssetsRepository ??
            GetIt.I.get<TenantAdminStaticAssetsRepositoryContract>();

  final TenantAdminStaticAssetsRepositoryContract _staticAssetsRepository;

  @override
  Future<TenantAdminStaticProfileTypeDefinition> resolve(
    RouteResolverParams params,
  ) async {
    final profileType = params['profileType'] as String?;
    if (profileType == null || profileType.trim().isEmpty) {
      throw ArgumentError.value(
        profileType,
        'profileType',
        'Static profile type must be provided',
      );
    }

    return _staticAssetsRepository.fetchStaticProfileType(profileType.trim());
  }
}
