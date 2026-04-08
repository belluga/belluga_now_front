import 'package:belluga_now/domain/repositories/static_assets_repository_contract.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/static_assets_backend_contract.dart';
import 'package:get_it/get_it.dart';

class StaticAssetsRepository implements StaticAssetsRepositoryContract {
  StaticAssetsRepository({
    StaticAssetsBackendContract? backend,
    BackendContract? backendContract,
  }) : _backend = backend ??
            (backendContract ?? GetIt.I.get<BackendContract>()).staticAssets;

  final StaticAssetsBackendContract _backend;

  @override
  Future<PublicStaticAssetModel?> getStaticAssetByRef(StaticAssetRepoText assetRef) {
    return _backend.fetchStaticAssetByRef(assetRef.value);
  }
}
