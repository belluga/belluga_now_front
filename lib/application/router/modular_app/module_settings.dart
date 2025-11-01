import 'dart:async';

import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/profile_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/home_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/home_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_repository.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/mock_schedule_backend.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class ModuleSettings extends ModuleSettingsContract {
  ModuleSettings({
    required BackendContract Function() backendBuilder,
    required AuthRepositoryContract Function() authRepositoryBuilder,
  })  : _backendBuilder = backendBuilder,
        _authRepositoryBuilder = authRepositoryBuilder;

  final BackendContract Function() _backendBuilder;
  final AuthRepositoryContract Function() _authRepositoryBuilder;

  @override
  FutureOr<void> registerGlobalDependencies() async {
    _registerBackend();
    await _registerAppData();
    _registerScheduleBackend();
    await _registerTenantRepository();
    await _registerAuthRepository();
    _registerHomeRepository();
  }

  @override
  Future<void> initializeSubmodules() async {
    await registerSubModule(InitializationModule());
    await registerSubModule(AuthModule());
    await registerSubModule(ProfileModule());
    await registerSubModule(ScheduleModule());
    await registerSubModule(MapModule());
  }

  void _registerBackend() {
    if (GetIt.I.isRegistered<BackendContract>()) {
      return;
    }

    final backend = _backendBuilder();
    GetIt.I.registerSingleton<BackendContract>(backend);
  }

  Future<void> _registerAppData() async {
    if (GetIt.I.isRegistered<AppData>()) {
      return;
    }

    final appData = AppData();
    await appData.initialize();
    GetIt.I.registerSingleton<AppData>(appData);
  }

  Future<void> _registerTenantRepository() async {
    if (GetIt.I.isRegistered<TenantRepositoryContract>()) {
      return;
    }

    final tenantRepository = TenantRepository();
    await tenantRepository.init();
    GetIt.I.registerSingleton<TenantRepositoryContract>(tenantRepository);
  }

  Future<void> _registerAuthRepository() async {
    if (GetIt.I.isRegistered<AuthRepositoryContract>()) {
      return;
    }

    final authRepository = _authRepositoryBuilder();
    await authRepository.init();
    GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
  }

  void _registerHomeRepository() {
    if (GetIt.I.isRegistered<HomeRepositoryContract>()) {
      return;
    }

    GetIt.I.registerLazySingleton<HomeRepositoryContract>(
      () => HomeRepository(),
    );
  }

  void _registerScheduleBackend() {
    if (GetIt.I.isRegistered<ScheduleBackendContract>()) {
      return;
    }

    GetIt.I.registerLazySingleton<ScheduleBackendContract>(
      () => MockScheduleBackend(),
    );
  }
}
