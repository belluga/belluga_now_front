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
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_organizations_repository_contract.dart';
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
import 'package:belluga_now/infrastructure/repositories/account_profiles_repository.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_repository.dart';
import 'package:belluga_now/infrastructure/repositories/telemetry_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_account_profiles_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_accounts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_organizations_repository.dart';
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
import 'package:belluga_now/presentation/common/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/common/push/controllers/push_options_controller.dart';
import 'package:belluga_now/presentation/common/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/controllers/auth_login_controller.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_create_new_password_screen/controllers/create_password_controller.dart';
import 'package:belluga_now/presentation/common/auth/screens/recovery_password_bug/controllers/recovery_password_token_controller.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/create_password_controller_contract.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/recovery_password_token_controller_contract.dart';
import 'package:belluga_now/presentation/landlord/auth/controllers/landlord_login_controller.dart';
import 'package:belluga_now/presentation/landlord/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/partners/controllers/partner_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/controllers/profile_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_location_picker_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/controllers/tenant_admin_organizations_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_handler.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_relay.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_resolver.dart';
import 'package:belluga_now/infrastructure/services/push/push_presentation_gate.dart';
import 'package:belluga_now/infrastructure/services/user/profile_avatar_storage.dart';
import 'package:belluga_now/application/router/guards/auth_redirect_store.dart';
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
    _registerControllerFactories();
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
  }


  void _registerControllerFactories() {
    if (!GetIt.I.isRegistered<AuthRedirectStore>()) {
      GetIt.I.registerLazySingleton<AuthRedirectStore>(
        () => AuthRedirectStore(),
      );
    }
    if (!GetIt.I.isRegistered<InitScreenController>()) {
      GetIt.I.registerLazySingleton<InitScreenController>(
        () => InitScreenController(),
      );
    }
    if (!GetIt.I.isRegistered<AuthLoginControllerContract>()) {
      GetIt.I.registerSingleton<AuthLoginControllerContract>(
        AuthLoginController(),
      );
    }
    if (!GetIt.I.isRegistered<CreatePasswordControllerContract>()) {
      GetIt.I.registerFactory<CreatePasswordControllerContract>(
        () => CreatePasswordController(),
      );
    }
    if (!GetIt.I.isRegistered<AuthRecoveryPasswordControllerContract>()) {
      GetIt.I.registerLazySingleton<AuthRecoveryPasswordControllerContract>(
        () => AuthRecoveryPasswordController(),
      );
    }
    if (!GetIt.I.isRegistered<LandlordLoginController>()) {
      GetIt.I.registerLazySingleton<LandlordLoginController>(
        () => LandlordLoginController(),
      );
    }
    if (!GetIt.I.isRegistered<LandlordHomeScreenController>()) {
      GetIt.I.registerLazySingleton<LandlordHomeScreenController>(
        () => LandlordHomeScreenController(),
      );
    }
    if (!GetIt.I.isRegistered<TenantHomeController>()) {
      GetIt.I.registerLazySingleton<TenantHomeController>(
        () => TenantHomeController(),
      );
    }
    if (!GetIt.I.isRegistered<TenantHomeAgendaController>()) {
      GetIt.I.registerLazySingleton<TenantHomeAgendaController>(
        () => TenantHomeAgendaController(),
      );
    }
    if (!GetIt.I.isRegistered<FavoritesSectionController>()) {
      GetIt.I.registerLazySingleton<FavoritesSectionController>(
        () => FavoritesSectionController(),
      );
    }
    if (!GetIt.I.isRegistered<InvitesBannerBuilderController>()) {
      GetIt.I.registerLazySingleton<InvitesBannerBuilderController>(
        () => InvitesBannerBuilderController(),
      );
    }
    if (!GetIt.I.isRegistered<InviteFlowScreenController>()) {
      GetIt.I.registerLazySingleton<InviteFlowScreenController>(
        () => InviteFlowScreenController(),
      );
    }
    if (!GetIt.I.isRegistered<InviteShareScreenController>()) {
      GetIt.I.registerLazySingleton<InviteShareScreenController>(
        () => InviteShareScreenController(),
      );
    }
    if (!GetIt.I.isRegistered<MapScreenController>()) {
      GetIt.I.registerLazySingleton<MapScreenController>(
        () => MapScreenController(),
      );
    }
    if (!GetIt.I.isRegistered<FabMenuController>()) {
      GetIt.I.registerLazySingleton<FabMenuController>(
        () => FabMenuController(),
      );
    }
    if (!GetIt.I.isRegistered<DiscoveryScreenController>()) {
      GetIt.I.registerLazySingleton<DiscoveryScreenController>(
        () => DiscoveryScreenController(),
      );
    }
    if (!GetIt.I.isRegistered<PartnerDetailController>()) {
      GetIt.I.registerFactory<PartnerDetailController>(
        () => PartnerDetailController(),
      );
    }
    if (!GetIt.I.isRegistered<ProfileScreenController>()) {
      GetIt.I.registerLazySingleton<ProfileScreenController>(
        () => ProfileScreenController(),
      );
    }
    if (!GetIt.I.isRegistered<EventSearchScreenController>()) {
      GetIt.I.registerFactory<EventSearchScreenController>(
        () => EventSearchScreenController(),
      );
    }
    if (!GetIt.I.isRegistered<EventDetailController>()) {
      GetIt.I.registerFactory<EventDetailController>(
        () => EventDetailController(),
      );
    }
    if (!GetIt.I.isRegistered<ImmersiveEventDetailController>()) {
      GetIt.I.registerFactory<ImmersiveEventDetailController>(
        () => ImmersiveEventDetailController(),
      );
    }
    if (!GetIt.I.isRegistered<TenantAdminShellController>()) {
      GetIt.I.registerLazySingleton<TenantAdminShellController>(
        () => TenantAdminShellController(),
      );
    }
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
    if (!GetIt.I.isRegistered<TenantAdminAccountsController>()) {
      GetIt.I.registerFactory<TenantAdminAccountsController>(
        () => TenantAdminAccountsController(),
      );
    }
    if (!GetIt.I.isRegistered<TenantAdminLocationPickerController>()) {
      GetIt.I.registerFactory<TenantAdminLocationPickerController>(
        () => TenantAdminLocationPickerController(),
      );
    }
    if (!GetIt.I.isRegistered<TenantAdminAccountProfilesController>()) {
      GetIt.I.registerFactory<TenantAdminAccountProfilesController>(
        () => TenantAdminAccountProfilesController(),
      );
    }
    if (!GetIt.I.isRegistered<TenantAdminOrganizationsController>()) {
      GetIt.I.registerFactory<TenantAdminOrganizationsController>(
        () => TenantAdminOrganizationsController(),
      );
    }
    if (!GetIt.I.isRegistered<TenantAdminProfileTypesController>()) {
      GetIt.I.registerFactory<TenantAdminProfileTypesController>(
        () => TenantAdminProfileTypesController(),
      );
    }
    if (!GetIt.I.isRegistered<TenantAdminTaxonomiesController>()) {
      GetIt.I.registerFactory<TenantAdminTaxonomiesController>(
        () => TenantAdminTaxonomiesController(),
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
    _registerIfAbsent<TenantAdminAccountsRepositoryContract>(
      () => TenantAdminAccountsRepository(),
    );
    _registerIfAbsent<TenantAdminAccountProfilesRepositoryContract>(
      () => TenantAdminAccountProfilesRepository(),
    );
    _registerIfAbsent<TenantAdminOrganizationsRepositoryContract>(
      () => TenantAdminOrganizationsRepository(),
    );
    _registerIfAbsent<TenantAdminTaxonomiesRepositoryContract>(
      () => TenantAdminTaxonomiesRepository(),
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
    final adminModeRepository =
        GetIt.I.get<AdminModeRepositoryContract>();
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
