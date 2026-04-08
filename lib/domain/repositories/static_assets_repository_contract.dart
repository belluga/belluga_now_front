import 'package:belluga_now/domain/repositories/value_objects/static_assets_repository_contract_values.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';

typedef StaticAssetRepoText = StaticAssetsRepositoryContractTextValue;

abstract class StaticAssetsRepositoryContract {
  Future<PublicStaticAssetModel?> getStaticAssetByRef(StaticAssetRepoText assetRef);
}
