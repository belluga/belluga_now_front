import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/landlord_public_instances_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/landlord_known_public_instances_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/landlord_public_instances_backend_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';

class LandlordKnownPublicInstancesRepository
    implements LandlordPublicInstancesRepositoryContract {
  LandlordKnownPublicInstancesRepository({
    LandlordPublicInstancesBackendContract? backend,
    AppDataLocalInfoSource? localInfoSource,
  })  : _backend = backend ?? LandlordKnownPublicInstancesBackend(),
        _localInfoSource = localInfoSource ?? AppDataLocalInfoSource();

  final LandlordPublicInstancesBackendContract _backend;
  final AppDataLocalInfoSource _localInfoSource;

  @override
  Future<List<AppData>> fetchFeaturedInstances() async {
    final localInfo = await _localInfoSource.getInfo();
    final environments = await _backend.fetchFeaturedInstanceEnvironments();
    return environments
        .map((dto) => dto.toDomain(localInfo: localInfo))
        .toList(growable: false);
  }
}
