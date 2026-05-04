import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/landlord_public_instances_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/landlord_known_public_instances_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/landlord_public_instances_backend_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:get_it/get_it.dart';

class LandlordKnownPublicInstancesRepository
    implements LandlordPublicInstancesRepositoryContract {
  LandlordKnownPublicInstancesRepository({
    LandlordPublicInstancesBackendContract? backend,
    AppDataLocalInfoSource? localInfoSource,
    AppDataRepositoryContract? appDataRepository,
  })  : _backend = backend ?? LandlordKnownPublicInstancesBackend(),
        _localInfoSource = localInfoSource ?? AppDataLocalInfoSource(),
        _appDataRepository = appDataRepository;

  final LandlordPublicInstancesBackendContract _backend;
  final AppDataLocalInfoSource _localInfoSource;
  AppDataRepositoryContract? _appDataRepository;

  AppDataRepositoryContract? get _resolvedAppDataRepository {
    if (_appDataRepository != null) {
      return _appDataRepository;
    }
    if (!GetIt.I.isRegistered<AppDataRepositoryContract>()) {
      return null;
    }
    _appDataRepository = GetIt.I.get<AppDataRepositoryContract>();
    return _appDataRepository;
  }

  @override
  Future<List<AppData>> fetchFeaturedInstances() async {
    final localInfo = await _localInfoSource.getInfo();
    final landlordOrigin =
        _resolvedAppDataRepository?.appData.mainDomainValue.value.origin;
    if (landlordOrigin == null || landlordOrigin.trim().isEmpty) {
      throw StateError(
        'AppDataRepositoryContract must be registered before fetching landlord public instances.',
      );
    }
    final environments = await _backend.fetchFeaturedInstanceEnvironments(
      landlordOrigin: landlordOrigin,
    );
    return environments
        .map((dto) => dto.toDomain(localInfo: localInfo))
        .toList(growable: false);
  }
}
