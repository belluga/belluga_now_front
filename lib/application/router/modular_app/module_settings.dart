import 'dart:async';
import 'dart:io';

import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/experiences_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/landlord_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_prototype_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/menu_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/mercado_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/profile_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';

import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/contacts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/favorite_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/repositories/mock_contacts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/partners_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
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
    _registerScheduleBackend();
    await _registerTenantRepository();
    await _registerAuthRepository();
    _registerFavoriteRepository();
    _registerContactsRepository();
  }

  @override
  Future<void> initializeSubmodules() async {
    await registerSubModule(InitializationModule());
    await registerSubModule(AuthModule());
    await registerSubModule(LandlordModule());
    await registerSubModule(ProfileModule());
    await registerSubModule(InvitesModule()); // Moved before ScheduleModule
    await registerSubModule(ScheduleModule());
    await registerSubModule(MapModule());
    await registerSubModule(DiscoveryModule());
    await registerSubModule(MercadoModule());
    await registerSubModule(ExperiencesModule());
    await registerSubModule(MenuModule());
    await registerSubModule(MapPrototypeModule());
  }

  void _registerBackend() {
    if (GetIt.I.isRegistered<BackendContract>()) {
      return;
    }
    final backend = _backendBuilder();
    GetIt.I.registerSingleton<BackendContract>(backend);
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

  void _registerFavoriteRepository() {
    if (GetIt.I.isRegistered<FavoriteRepositoryContract>()) {
      return;
    }
    GetIt.I.registerLazySingleton<FavoriteRepositoryContract>(
      () => FavoriteRepository(),
    );
  }

  void _registerScheduleBackend() {
    if (GetIt.I.isRegistered<ScheduleBackendContract>()) {
      return;
    }
    final backend = GetIt.I.get<BackendContract>();
    GetIt.I.registerLazySingleton<ScheduleBackendContract>(
      () => backend.schedule,
    );
    GetIt.I.registerLazySingleton<ScheduleRepositoryContract>(
        () => ScheduleRepository());
    GetIt.I.registerLazySingleton<UserEventsRepositoryContract>(
      () => UserEventsRepository(),
    );
    GetIt.I.registerLazySingleton<InvitesRepositoryContract>(
      () => InvitesRepository(),
    );
    GetIt.I.registerLazySingleton<PartnersRepositoryContract>(
      () => PartnersRepository(),
    );
  }

  void _registerContactsRepository() {
    if (GetIt.I.isRegistered<ContactsRepositoryContract>()) {
      return;
    }

    // Use mock on Linux/MacOS/Windows for development
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      GetIt.I.registerLazySingleton<ContactsRepositoryContract>(
        () => MockContactsRepository(),
      );
    } else {
      GetIt.I.registerLazySingleton<ContactsRepositoryContract>(
        () => ContactsRepository(),
      );
    }
  }
}
