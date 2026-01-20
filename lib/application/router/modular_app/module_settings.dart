import 'dart:async';

import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/home_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/landlord_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/menu_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/profile_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';

import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/admin_mode_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/contacts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/friends_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/partners_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_repository.dart';
import 'package:belluga_now/infrastructure/repositories/telemetry_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_location_repository.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_tenant_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/production_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/presentation/common/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/common/push/controllers/push_options_controller.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_handler.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_relay.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_resolver.dart';
import 'package:belluga_now/infrastructure/services/push/push_presentation_gate.dart';
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
  })  : _backendBuilder = backendBuilderForTest ?? (() => ProductionBackend()),
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
    await registerSubModule(TenantAdminModule());
    await registerSubModule(ProfileModule());
    await registerSubModule(InvitesModule());
    await registerSubModule(ScheduleModule());
    await registerSubModule(MapModule());
    await registerSubModule(DiscoveryModule());
    await registerSubModule(MenuModule());
  }

  void _registerBackend() {
    // Composite backend for repositories still depending on BackendContract.
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
    if (!GetIt.I.isRegistered<PushOptionsController>()) {
      GetIt.I.registerLazySingleton<PushOptionsController>(
        () => PushOptionsController(),
      );
    }
  }

  void _registerPushDependencies() {
    _registerLazySingletonIfAbsent<PushPresentationGate>(
      () => PushPresentationGate(),
    );
    final relay = _registerIfAbsent<PushAnswerRelay>(() => PushAnswerRelay());
    _registerLazySingletonIfAbsent<PushAnswerHandler>(() => relay);
    _registerLazySingletonIfAbsent<PushAnswerResolver>(() => relay);
  }

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
      final currentPath = appRouter.currentPath;
      if (_shouldSkipDuplicateNavigation(
        request: request,
        currentPath: currentPath,
        resolvedPath: resolvedPath,
      )) {
        return;
      }
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
        case 'invite_flow':
          final inviteId = _resolveInviteId(request);
          if (inviteId == null || inviteId.isEmpty) {
            return '/convites';
          }
          return '/convites?invite=$inviteId';
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

  bool _shouldSkipDuplicateNavigation({
    required PushRouteRequest request,
    required String currentPath,
    required String resolvedPath,
  }) {
    if (!_isEventRouteRequest(request)) {
      return false;
    }
    return currentPath == resolvedPath;
  }

  bool _isEventRouteRequest(PushRouteRequest request) {
    final routeKey = request.routeKey;
    return routeKey == 'event_detail' || routeKey == 'event_immersive';
  }

  String? _resolveInviteId(PushRouteRequest request) {
    final itemKey = request.itemKey;
    if (itemKey != null && itemKey.isNotEmpty) {
      return itemKey;
    }
    final param =
        request.pathParameters['invite'] ?? request.pathParameters['invite_id'];
    if (param != null && param.isNotEmpty) {
      return param;
    }
    return null;
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
    _registerIfAbsent<AdminModeRepositoryContract>(
      () => AdminModeRepository(),
    );
    _registerIfAbsent<ContactsRepositoryContract>(
      () => ContactsRepository(),
    );
    await _registerAppDataRepository();
    _registerBackendContext();
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
    await _registerLandlordAuthRepository();
    final adminModeRepository =
        GetIt.I.get<AdminModeRepositoryContract>();
    await adminModeRepository.init();
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

  void _registerBackendContext() {
    if (GetIt.I.isRegistered<BackendContext>()) {
      return;
    }
    final appData = GetIt.I.get<AppDataRepository>().appData;
    GetIt.I.registerSingleton<BackendContext>(
      BackendContext.fromAppData(appData),
    );
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

  Future<void> _registerLandlordAuthRepository() async {
    final landlordAuth = _registerIfAbsent<LandlordAuthRepositoryContract>(
      () => LandlordAuthRepository(),
    );
    await landlordAuth.init();
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
