import 'package:belluga_now/domain/repositories/static_assets_repository_contract.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class StaticAssetDetailRouteResolver
    implements RouteModelResolver<PublicStaticAssetModel> {
  StaticAssetDetailRouteResolver({
    @visibleForTesting
    StaticAssetsRepositoryContract? staticAssetsRepository,
  }) : _staticAssetsRepository = staticAssetsRepository ??
            GetIt.I.get<StaticAssetsRepositoryContract>();

  final StaticAssetsRepositoryContract _staticAssetsRepository;

  @override
  Future<PublicStaticAssetModel> resolve(RouteResolverParams params) async {
    final assetRef = params['assetRef'] as String?;
    if (assetRef == null || assetRef.trim().isEmpty) {
      throw ArgumentError.value(
        assetRef,
        'assetRef',
        'Static asset ref must be provided',
      );
    }

    final asset = await _staticAssetsRepository.getStaticAssetByRef(
      StaticAssetRepoText.fromRaw(
        assetRef,
        defaultValue: assetRef,
        isRequired: true,
      ),
    );
    if (asset == null) {
      throw Exception('Static asset not found for ref: $assetRef');
    }

    return asset;
  }
}
