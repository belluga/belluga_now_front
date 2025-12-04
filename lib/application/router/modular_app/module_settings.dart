import 'dart:async';

import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/home_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/landlord_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_prototype_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/menu_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/profile_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';

import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/repositories/partners_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_tenant_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:meta/meta.dart';

class ModuleSettings extends ModuleSettingsContract {
  ModuleSettings({
    @visibleForTesting BackendContract Function()? backendBuilderForTest,
    @visibleForTesting
    AppDataBackendContract Function()? appDataBackendBuilderForTest,
    @visibleForTesting
    TenantBackendContract Function()? tenantBackendBuilderForTest,
    @visibleForTesting
    ScheduleBackendContract Function()? scheduleBackendBuilderForTest,
  })  : _backendBuilder = backendBuilderForTest ?? (() => MockBackend()),
        _appDataBackendBuilder =
            appDataBackendBuilderForTest ?? (() => MockAppDataBackend()),
        _tenantBackendBuilder =
            tenantBackendBuilderForTest ?? (() => MockTenantBackend()),
        _scheduleBackendBuilder =
            scheduleBackendBuilderForTest ?? (() => MockScheduleBackend());

  final BackendContract Function() _backendBuilder;
  final AppDataBackendContract Function() _appDataBackendBuilder;
  final TenantBackendContract Function() _tenantBackendBuilder;
  final ScheduleBackendContract Function() _scheduleBackendBuilder;

  @override
  FutureOr<void> registerGlobalDependencies() async {
    _registerBackend();
    await _registerRepositories();
  }

  @override
  Future<void> initializeSubmodules() async {
    await registerSubModule(InitializationModule());
    await registerSubModule(HomeModule());
    await registerSubModule(AuthModule());
    await registerSubModule(LandlordModule());
    await registerSubModule(ProfileModule());
    await registerSubModule(InvitesModule());
    await registerSubModule(ScheduleModule());
    await registerSubModule(MapModule());
    await registerSubModule(DiscoveryModule());
    await registerSubModule(MenuModule());
    await registerSubModule(MapPrototypeModule());
  }

  void _registerBackend() {
    // Composite backend (mock) for repositories still depending on BackendContract
    _registerLazySingletonIfAbsent<BackendContract>(_backendBuilder);
    _registerLazySingletonIfAbsent<AppDataBackendContract>(
      _appDataBackendBuilder,
    );
    _registerLazySingletonIfAbsent<TenantBackendContract>(
      _tenantBackendBuilder,
    );
    _registerLazySingletonIfAbsent<ScheduleBackendContract>(
      _scheduleBackendBuilder,
    );
    _registerIfAbsent<ScheduleRepositoryContract>(() => ScheduleRepository());
    _registerIfAbsent<UserEventsRepositoryContract>(
      () => UserEventsRepository(),
    );
    _registerIfAbsent<InvitesRepositoryContract>(
      () => InvitesRepository(),
    );
    _registerIfAbsent<PartnersRepositoryContract>(
      () => PartnersRepository(),
    );
  }

  Future<void> _registerRepositories() async {
    await _registerAppDataRepository();
    await _registerTenantRepository();
    await _registerAuthRepository();
  }

  Future<void> _registerAppDataRepository() async {
    final appDataRepository = _registerIfAbsent<AppDataRepository>(
      () => AppDataRepository(),
    );
    await appDataRepository.init();
  }

  Future<void> _registerTenantRepository() async {
    final _tenantRepository = _registerIfAbsent<TenantRepositoryContract>(
      () => TenantRepository(),
    );
    await _tenantRepository.init();
  }

  Future<void> _registerAuthRepository() async {
    final _authRepository = _registerIfAbsent<AuthRepositoryContract>(
      () => AuthRepository(),
    );
    await _authRepository.init();
  }

  T _registerIfAbsent<T extends Object>(T Function() builder) {
    if (GetIt.I.isRegistered<T>()) {
      return GetIt.I.get<T>();
    }
    return GetIt.I.registerSingleton<T>(builder());
  }

  void _registerLazySingletonIfAbsent<T extends Object>(
    T Function() builder,
  ) {
    if (!GetIt.I.isRegistered<T>()) {
      GetIt.I.registerLazySingleton<T>(builder);
    }
  }
}
