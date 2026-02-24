import 'dart:async';

import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/account_workspace_module.dart';
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
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_organizations_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/push/push_presentation_gate_contract.dart';
import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/admin_mode_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/city_map_repository.dart';
import 'package:belluga_now/infrastructure/repositories/contacts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/favorite_repository.dart';
import 'package:belluga_now/infrastructure/repositories/friends_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:belluga_now/infrastructure/repositories/account_profiles_repository.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_repository.dart';
import 'package:belluga_now/infrastructure/repositories/telemetry_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_account_profiles_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_accounts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_organizations_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_settings_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_static_assets_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_taxonomies_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_location_repository.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_poi_database.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/production_backend.dart';
import 'package:belluga_now/infrastructure/services/http/laravel_map_poi_http_service.dart';
import 'package:belluga_now/infrastructure/services/http/mock_http_service.dart';
import 'package:belluga_now/infrastructure/services/networking/mock_web_socket_service.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/shared/push/controllers/push_options_controller.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_handler.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_relay.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_resolver.dart';
import 'package:belluga_now/infrastructure/services/push/push_presentation_gate.dart';
import 'package:belluga_now/infrastructure/services/user/profile_avatar_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:push_handler/push_handler.dart';

class ModuleSettings extends ModuleSettingsContract {
  ModuleSettings({
    @visibleForTesting BackendContract Function()? backendBuilderForTest,
  })  : _backendBuilder = backendBuilderForTest ?? (() => ProductionBackend()),
        _appDataLocalInfoSource = AppDataLocalInfoSource();

  final BackendContract Function() _backendBuilder;
  final AppDataLocalInfoSource _appDataLocalInfoSource;

  @override
  FutureOr<void> registerGlobalDependencies() async {
    _registerBackend();
    await _registerRepositories();
    _registerGlobalControllerDependencies();
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
    await registerSubModule(AccountWorkspaceModule());
    await registerSubModule(MenuModule());
  }

  void _registerBackend() {
    // Composite backend for repositories still depending on BackendContract.
    _registerLazySingletonIfAbsent<BackendContract>(_backendBuilder);
  }

  // Only app-lifecycle controllers stay in global scope.
  // Feature controllers must be registered by their owning module.
  void _registerGlobalControllerDependencies() {
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
    _registerLazySingletonIfAbsent<PushPresentationGateContract>(
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
        debugPrint(
            '[Push] Unmapped route request: ${request.routeKey ?? request.route}');
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
      final queryParameters = Map<String, String>.from(baseUri.queryParameters);
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
    _registerIfAbsent<TenantAdminAccountsRepositoryContract>(
      () => TenantAdminAccountsRepository(),
    );
    _registerIfAbsent<TenantAdminAccountProfilesRepositoryContract>(
      () => TenantAdminAccountProfilesRepository(),
    );
    _registerIfAbsent<TenantAdminOrganizationsRepositoryContract>(
      () => TenantAdminOrganizationsRepository(),
    );
    _registerIfAbsent<TenantAdminSettingsRepositoryContract>(
      () => TenantAdminSettingsRepository(),
    );
    _registerIfAbsent<TenantAdminStaticAssetsRepositoryContract>(
      () => TenantAdminStaticAssetsRepository(),
    );
    _registerIfAbsent<TenantAdminTaxonomiesRepositoryContract>(
      () => TenantAdminTaxonomiesRepository(),
    );
    _registerIfAbsent<LandlordTenantsRepositoryContract>(
      () => LandlordTenantsRepository(),
    );
    _registerIfAbsent<ContactsRepositoryContract>(
      () => ContactsRepository(),
    );
    _registerIfAbsent<FavoriteRepositoryContract>(
      () => FavoriteRepository(),
    );
    _registerIfAbsent<ScheduleRepositoryContract>(() => ScheduleRepository());
    _registerIfAbsent<FriendsRepositoryContract>(
      () => FriendsRepository(),
    );
    _registerIfAbsent<InvitesRepositoryContract>(
      () => InvitesRepository(),
    );
    await _registerAppDataRepository();
    final mockPoiDatabase =
        _registerIfAbsent<MockPoiDatabase>(() => MockPoiDatabase());
    _registerIfAbsent<MockHttpService>(
      () => MockHttpService(database: mockPoiDatabase),
    );
    _registerIfAbsent<LaravelMapPoiHttpService>(
      () => LaravelMapPoiHttpService(),
    );
    _registerIfAbsent<MockWebSocketService>(
      () => MockWebSocketService(),
    );
    _registerIfAbsent<CityMapRepositoryContract>(
      () => CityMapRepository(
        database: mockPoiDatabase,
        httpService: GetIt.I.get<MockHttpService>(),
        laravelHttpService: GetIt.I.get<LaravelMapPoiHttpService>(),
        webSocketService: GetIt.I.get<MockWebSocketService>(),
      ),
    );
    _registerIfAbsent<PoiRepositoryContract>(() => PoiRepository());
    _registerIfAbsent<ProfileAvatarStorageContract>(
      () => ProfileAvatarStorage(),
    );
    _registerIfAbsent<TelemetryRepositoryContract>(
      () => TelemetryRepository(),
    );
    _registerIfAbsent<AccountProfilesRepositoryContract>(
      () => AccountProfilesRepository(),
    );
    _registerIfAbsent<UserEventsRepositoryContract>(
      () => UserEventsRepository(),
    );
    await _registerTenantRepository();
    await _registerAuthRepository();
    await _registerLandlordAuthRepository();
    final adminModeRepository = GetIt.I.get<AdminModeRepositoryContract>();
    await adminModeRepository.init();
  }

  Future<void> _registerAppDataRepository() async {
    final appDataRepository = _registerIfAbsent<AppDataRepositoryContract>(
      () => AppDataRepository(
        backendContract: GetIt.I.get<BackendContract>(),
        localInfoSource: _appDataLocalInfoSource,
      ),
    );
    await appDataRepository.init();
    GetIt.I
        .get<BackendContract>()
        .setContext(BackendContext.fromAppData(appDataRepository.appData));
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
