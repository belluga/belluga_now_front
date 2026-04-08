import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';

abstract class StaticAssetsBackendContract {
  Future<PublicStaticAssetModel?> fetchStaticAssetByRef(String assetRef);
}
