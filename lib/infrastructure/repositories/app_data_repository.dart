import 'package:belluga_now/application/configurations/app_environment_fallback.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class AppDataRepository {
  late AppData appData;

  final AppDataBackendContract _backend;
  final AppDataLocalInfoSource _localInfoSource;

  AppDataRepository({
    required AppDataLocalInfoSource localInfoSource,
    required AppDataBackendContract backend,
  })  : _backend = backend,
        _localInfoSource = localInfoSource;

  Future<void> init() async {
    Map<String, dynamic>? _remoteData = await _fetchRemoteOrFallback();

    final localInfo = await _localInfoSource.getInfo();

    appData = AppData.fromInitialization(
      remoteData: _remoteData,
      localInfo: localInfo,
    );

    if (GetIt.I.isRegistered<AppData>()) {
      GetIt.I.unregister<AppData>();
    }
    GetIt.I.registerSingleton<AppData>(appData);
  }

  Future<Map<String, dynamic>> _fetchRemoteOrFallback() async {
    try {
      return await _backend.fetch();
    } catch (error, stackTrace) {
      debugPrint(
          'AppDataRepository: remote fetch failed, using fallback. $error');
      debugPrintStack(stackTrace: stackTrace);
      return kLocalEnvironmentFallback;
    }
  }
}
