import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class TenantAdminStaticAssetDetailRouteResolver
    implements RouteModelResolver<TenantAdminStaticAsset> {
  TenantAdminStaticAssetDetailRouteResolver({
    @visibleForTesting
    TenantAdminStaticAssetsRepositoryContract? staticAssetsRepository,
  }) : _staticAssetsRepository = staticAssetsRepository ??
            GetIt.I.get<TenantAdminStaticAssetsRepositoryContract>();

  final TenantAdminStaticAssetsRepositoryContract _staticAssetsRepository;

  @override
  Future<TenantAdminStaticAsset> resolve(RouteResolverParams params) async {
    final assetId = params['assetId'] as String?;
    if (assetId == null || assetId.trim().isEmpty) {
      throw ArgumentError.value(
        assetId,
        'assetId',
        'Static asset id must be provided',
      );
    }

    return _staticAssetsRepository.fetchStaticAsset(assetId.trim());
  }
}
