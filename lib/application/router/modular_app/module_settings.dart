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
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/friends_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/repositories/partners_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_repository.dart';
import 'package:belluga_now/infrastructure/repositories/telemetry_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_location_repository.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_tenant_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/presentation/common/location_permission/controllers/location_permission_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:push_handler/push_handler.dart';

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
            appDataBackendBuilderForTest ?? (() => AppDataBackend()),
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
    _registerControllerFactories();
    _registerBackend();
    await _registerRepositories();
    _registerPushDependencies();
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
    _registerIfAbsent<FriendsRepositoryContract>(
      () => FriendsRepository(),
    );
    _registerIfAbsent<InvitesRepositoryContract>(
      () => InvitesRepository(),
    );
  }

  void _registerControllerFactories() {
    if (!GetIt.I.isRegistered<LocationPermissionController>()) {
      GetIt.I.registerFactory<LocationPermissionController>(
        () => LocationPermissionController(),
      );
    }
  }

  void _registerPushDependencies() {}

  PushNavigationResolver buildPushNavigationResolver() {
    return _buildNavigationResolver();
  }

  PushNavigationResolver _buildNavigationResolver() {
    return (request) async {
      final resolvedPath = _resolvePushRoutePath(request);
      if (resolvedPath == null || resolvedPath.isEmpty) {
        debugPrint('[Push] Unmapped route request: ${request.routeKey ?? request.route}');
        return;
      }
      final appRouter = GetIt.I.get<ApplicationContract>().appRouter;
      final baseUri = Uri.parse(resolvedPath);
      final queryParameters =
          Map<String, String>.from(baseUri.queryParameters);
      if (request.itemKey != null && request.itemKey!.isNotEmpty) {
        queryParameters['itemIDString'] = request.itemKey!;
      }
      final resolvedUri = baseUri.replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      await appRouter.pushPath(resolvedUri.toString());
    };
  }

  String? _resolvePushRoutePath(PushRouteRequest request) {
    final routeKey = request.routeKey;
    if (routeKey != null && routeKey.isNotEmpty) {
      switch (routeKey) {
        case 'event_detail':
          return _applyPathParameters(
            '/agenda/evento/:slug',
            request.pathParameters,
          );
        case 'event_immersive':
          return _applyPathParameters(
            '/agenda/evento-imersivo/:slug',
            request.pathParameters,
          );
        case 'map':
          return '/mapa';
        default:
          return null;
      }
    }
    if (request.route.isEmpty) return null;
    return _applyPathParameters(request.route, request.pathParameters) ??
        request.route;
  }

  String? _applyPathParameters(
    String path,
    Map<String, String> parameters,
  ) {
    final pattern = RegExp(r':([A-Za-z0-9_]+)');
    final matches = pattern.allMatches(path).toList();
    if (matches.isEmpty) {
      return path;
    }
    var resolved = path;
    for (final match in matches) {
      final key = match.group(1);
      if (key == null || key.isEmpty) {
        return null;
      }
      final value = _resolveRouteParameter(parameters, key);
      if (value == null || value.isEmpty) {
        return null;
      }
      resolved = resolved.replaceFirst(':$key', value);
    }
    return resolved;
  }

  String? _resolveRouteParameter(
    Map<String, String> parameters,
    String key,
  ) {
    final direct = parameters[key];
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    if (key == 'slug') {
      final eventId = parameters['event_id'];
      if (eventId != null && eventId.isNotEmpty) {
        return eventId;
      }
    }
    return null;
  }

  Future<void> _registerRepositories() async {
    _registerIfAbsent<UserLocationRepositoryContract>(
      () => UserLocationRepository(),
    );
    await _registerAppDataRepository();
    _registerIfAbsent<TelemetryRepositoryContract>(
      () => TelemetryRepository(),
    );
    _registerIfAbsent<PartnersRepositoryContract>(
      () => PartnersRepository(),
    );
    _registerIfAbsent<UserEventsRepositoryContract>(
      () => UserEventsRepository(),
    );
    await _registerTenantRepository();
    await _registerAuthRepository();
  }

  Future<void> _registerAppDataRepository() async {
    final appDataRepository = _registerIfAbsent<AppDataRepository>(
      () => AppDataRepository(
        backend: _appDataBackendBuilder(),
        localInfoSource: AppDataLocalInfoSource(),
      ),
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
