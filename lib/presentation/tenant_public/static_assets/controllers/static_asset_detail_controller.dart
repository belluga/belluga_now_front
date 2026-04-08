import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:get_it/get_it.dart';

class StaticAssetDetailController implements Disposable {
  StaticAssetDetailController({
    AppData? appData,
    AuthRepositoryContract? authRepository,
  })  : _appData = appData ?? GetIt.I.get<AppData>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null);

  final AppData _appData;
  final AuthRepositoryContract? _authRepository;

  String? get authenticatedUserDisplayName {
    final raw =
        _authRepository?.userStreamValue.value?.profile.nameValue?.value.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  String publicPathForAsset(PublicStaticAssetModel asset) {
    final slug = asset.slug.trim();
    if (slug.isNotEmpty) {
      return '/static/$slug';
    }
    return '/static/${asset.id}';
  }

  Uri buildTenantPublicUriForAsset(PublicStaticAssetModel asset) {
    return _appData.mainDomainValue.value.resolve(publicPathForAsset(asset));
  }

  @override
  void onDispose() {}
}
