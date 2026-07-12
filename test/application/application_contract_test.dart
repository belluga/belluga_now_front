// ignore_for_file: must_be_immutable

import 'dart:collection';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/modular_app/module_settings.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/application/startup/app_startup_plan_resolver.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:belluga_now/domain/user/value_objects/user_identity_state_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_dto.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/venue_event/venue_event_preview_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:intl/intl.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('app init retries until telemetry logging succeeds', (
    tester,
  ) async {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(appData: _buildAppData()),
    );
    final telemetry = _FakeTelemetryRepository(
      appInitResults: Queue<bool>.from([false, true]),
    );
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetry);
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );

    final app = _TestApplication();
    app.appRouter.setChildModules([_TestModule()]);
    await tester.pumpWidget(app);
    await tester.pump();
    expect(telemetry.appInitCalls, 1);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(telemetry.appInitCalls, 2);

    await tester.pump(const Duration(seconds: 2));
    expect(telemetry.appInitCalls, 2);
  });

  testWidgets('app init fires again after resume', (tester) async {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(appData: _buildAppData()),
    );
    final telemetry = _FakeTelemetryRepository(
      appInitResults: Queue<bool>.from([true, true]),
    );
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetry);
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );

    final app = _TestApplication();
    app.appRouter.setChildModules([_TestModule()]);
    await tester.pumpWidget(app);
    await tester.pump();
    expect(telemetry.appInitCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(telemetry.appInitCalls, 2);
    await tester.pump(const Duration(milliseconds: 450));
    expect(telemetry.lifecycleEvents.length, 1);
    expect(telemetry.lifecycleEvents.single, {
      'state': 'resumed',
      'sequence': ['paused', 'resumed'],
    });
  });

  testWidgets('app router consumes runtime pushRouteInformation for /mapa', (
    tester,
  ) async {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(appData: _buildAppData()),
    );
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(
      _FakeTelemetryRepository(appInitResults: Queue<bool>.from([true])),
    );
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );

    final app = _TestApplication();
    app.appRouter.setChildModules([_DeepLinkTestModule()]);
    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.text('home'), findsOneWidget);
    expect(app.appRouter.currentPath, '/');

    const testRouteInformation = <String, dynamic>{
      'location': 'https://guarappari.belluga.space/mapa',
      'state': null,
    };
    final message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );

    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(app.appRouter.currentPath, '/mapa');
    expect(find.text('mapa'), findsOneWidget);
  });

  test('initialSettings locks intl default locale to pt_BR', () async {
    Intl.defaultLocale = 'en_US';
    final app = _TestApplication();

    await app.initialSettings();

    expect(Intl.defaultLocale, 'pt_BR');
  });

  testWidgets('app shell locks MaterialApp locale to pt_BR', (tester) async {
    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      _FakeAppDataRepository(appData: _buildAppData()),
    );
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(
      _FakeTelemetryRepository(appInitResults: Queue<bool>.from([true])),
    );
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );

    final app = _TestApplication();
    app.appRouter.setChildModules([_TestModule()]);
    await tester.pumpWidget(app);
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('pt', 'BR'));
    expect(materialApp.supportedLocales, const <Locale>[Locale('pt', 'BR')]);
  });

  testWidgets(
    'app retries post-auth hydration when auth repository appears after init',
    (tester) async {
      GetIt.I.registerSingleton<AppDataRepositoryContract>(
        _FakeAppDataRepository(appData: _buildAppData()),
      );
      GetIt.I.registerSingleton<TelemetryRepositoryContract>(
        _FakeTelemetryRepository(appInitResults: Queue<bool>.from([true])),
      );
      final favoriteRepository = _FakeFavoriteRepository();
      GetIt.I.registerSingleton<FavoriteRepositoryContract>(favoriteRepository);

      final app = _TestApplication();
      app.appRouter.setChildModules([_TestModule()]);
      await tester.pumpWidget(app);
      await tester.pump();

      final authRepository = _FakeAuthRepository();
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
      authRepository.emit(_registeredUser());
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        favoriteRepository.refreshFavoriteResumesCalls,
        1,
        reason:
            'Application bootstrap must still bind post-auth hydration when '
            'auth registration completes after initState.',
      );
    },
  );

  test(
    'bootstrap retry on the same application instance does not re-register initialization module',
    () async {
      GetIt.I.registerSingleton<AppDataRepositoryContract>(
        _FakeAppDataRepository(appData: _buildAppData()),
      );
      GetIt.I.registerSingleton<TelemetryRepositoryContract>(
        _FakeTelemetryRepository(appInitResults: Queue<bool>.from([true])),
      );
      GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
        _FakeAuthRepository(),
      );
      final moduleSettings = _BootstrapRetryTestModuleSettings();
      final app = _BootstrapRetryTestApplication(moduleSettings);

      await expectLater(
        app.init(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'post-bootstrap failure',
          ),
        ),
      );

      await app.init();

      expect(moduleSettings.initializeSubmodulesCalls, 2);
      expect(GetIt.I.isRegistered<InitializationModule>(), isTrue);
      expect(
        moduleSettings.childModules.whereType<InitializationModule>().length,
        1,
      );
    },
  );

  test(
    'module settings init leaves startup resolver unavailable when it remains module-scoped only',
    () async {
      final moduleSettings = _StartupPlanTestModuleSettings(
        registerStartupResolverGlobally: false,
      );

      await moduleSettings.init();

      expect(GetIt.I.isRegistered<InitializationModule>(), isTrue);
      expect(GetIt.I.isRegistered<AppStartupPlanResolver>(), isFalse);
    },
  );

  test(
    'module settings init exposes startup resolver when startup dependencies are registered globally',
    () async {
      final moduleSettings = _StartupPlanTestModuleSettings(
        registerStartupResolverGlobally: true,
      );

      await moduleSettings.init();

      expect(GetIt.I.isRegistered<InitializationModule>(), isTrue);
      expect(GetIt.I.isRegistered<AppStartupPlanResolver>(), isTrue);
    },
  );
}

class _TestApplication extends ApplicationContract {
  _TestApplication();

  @override
  Future<void> initialSettingsPlatform() async {}
}

class _BootstrapRetryTestApplication extends ApplicationContract {
  _BootstrapRetryTestApplication(this._testModuleSettings);

  final _BootstrapRetryTestModuleSettings _testModuleSettings;
  bool _shouldFailAfterFirstBootstrap = true;

  @override
  ModuleSettings get moduleSettings => _testModuleSettings;

  @override
  Future<void> initialSettingsPlatform() async {}

  @override
  Future<void> init() async {
    await super.init();
    if (_shouldFailAfterFirstBootstrap) {
      _shouldFailAfterFirstBootstrap = false;
      throw StateError('post-bootstrap failure');
    }
  }
}

class _TestModule extends ModuleContract {
  @override
  Future<void> registerDependencies() async {}

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PageInfo.builder(
        'TestRoute',
        builder: (_, _) => const SizedBox.shrink(),
      ),
      path: '/',
    ),
  ];
}

class _BootstrapRetryTestModuleSettings extends ModuleSettings {
  int initializeSubmodulesCalls = 0;

  @override
  Future<void> registerGlobalDependencies() async {}

  @override
  Future<void> initializeSubmodules() async {
    initializeSubmodulesCalls += 1;
    await registerSubModuleIfAbsent(InitializationModule());
  }
}

class _StartupPlanTestModuleSettings extends ModuleSettings {
  _StartupPlanTestModuleSettings({
    required this.registerStartupResolverGlobally,
  });

  final bool registerStartupResolverGlobally;

  @override
  Future<void> registerGlobalDependencies() async {
    if (registerStartupResolverGlobally) {
      registerStartupDependencies();
    }
  }

  @override
  Future<void> initializeSubmodules() async {
    await registerSubModuleIfAbsent(InitializationModule());
  }
}

class _DeepLinkTestModule extends ModuleContract {
  @override
  Future<void> registerDependencies() async {}

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PageInfo.builder(
        'HomeRoute',
        builder: (_, _) => const Text('home'),
      ),
      path: '/',
    ),
    AutoRoute(
      page: PageInfo.builder('MapRoute', builder: (_, _) => const Text('mapa')),
      path: '/mapa',
    ),
  ];
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  _FakeTelemetryRepository({required this.appInitResults});

  final Queue<bool> appInitResults;
  int appInitCalls = 0;
  final List<Map<String, Object?>> lifecycleEvents = <Map<String, Object?>>[];

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    if (eventName?.value == 'app_init') {
      appInitCalls += 1;
      if (appInitResults.isNotEmpty) {
        return telemetryRepoBool(appInitResults.removeFirst());
      }
    } else if (eventName?.value == 'app_lifecycle') {
      final payload = TelemetryPropertiesCodec.toRawMap(properties);
      final state = payload['state'];
      final sequence = payload['sequence'];
      if (state is String && sequence is List) {
        lifecycleEvents.add({'state': state, 'sequence': sequence});
      }
    }
    return telemetryRepoBool(true);
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    return null;
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async {
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async {
    return telemetryRepoBool(true);
  }

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async {
    return telemetryRepoBool(true);
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  @override
  BackendContract get backend => _NoopBackend();

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => false;

  void emit(UserContract? user) {
    userStreamValue.addValue(user);
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

class _FakeFavoriteRepository implements FavoriteRepositoryContract {
  @override
  final favoriteResumesStreamValue = StreamValue<List<FavoriteResume>?>(
    defaultValue: null,
  );

  @override
  final hasMoreFavoriteResumesStreamValue = StreamValue<bool>(
    defaultValue: false,
  );

  @override
  final isFavoriteResumesPageLoadingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );

  int refreshFavoriteResumesCalls = 0;

  @override
  Future<List<Favorite>> fetchFavorites() async => const <Favorite>[];

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async =>
      const <FavoriteResume>[];

  @override
  Future<void> initializeFavoriteResumes() async {}

  @override
  Future<void> loadNextFavoriteResumesPage() async {}

  @override
  Future<void> refreshFavoriteResumes() async {
    refreshFavoriteResumesCalls += 1;
  }
}

UserBelluga _registeredUser() {
  const userId = '507f1f77bcf86cd799439012';
  return UserBelluga(
    uuidValue: MongoIDValue(defaultValue: userId)..parse(userId),
    profile: UserProfileContract(),
    customData: UserCustomData(
      identityStateValue: UserIdentityStateValue.fromRaw('registered'),
    ),
  );
}

class _FakeAppDataRepository extends AppDataRepository {
  _FakeAppDataRepository({required AppData appData})
    : super(
        backend: _NoopAppDataBackend(),
        localInfoSource: _NoopLocalInfoSource(),
      ) {
    this.appData = appData;
  }
}

class _NoopAppDataBackend extends AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() {
    throw UnimplementedError();
  }
}

class _NoopLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<AppDataLocalInfoDTO> getInfo() async => AppDataLocalInfoDTO(
    platformTypeValue: PlatformTypeValue(defaultValue: AppType.mobile),
    port: null,
    hostname: '',
    href: '',
    device: '',
  );
}

class _NoopBackend extends BackendContract {
  BackendContext? _context;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  AppDataBackendContract get appData => _NoopAppDataBackend();

  @override
  AuthBackendContract get auth => _NoopAuthBackend();

  @override
  TenantBackendContract get tenant => _NoopTenantBackend();

  @override
  AccountProfilesBackendContract get accountProfiles =>
      _NoopAccountProfilesBackend();

  @override
  FavoriteBackendContract get favorites => _NoopFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _NoopVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _NoopScheduleBackend();
}

class _NoopAccountProfilesBackend implements AccountProfilesBackendContract {
  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
    List<String>? typeFilters,
    List<dynamic>? taxonomyFilters,
    List<String>? allowedTypes,
  }) => throw UnimplementedError();

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) =>
      throw UnimplementedError();

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
    List<String>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) => throw UnimplementedError();
}

class _NoopAuthBackend extends AuthBackendContract {
  @override
  Future<AnonymousIdentityResponse> issueAnonymousIdentity({
    required String deviceName,
    required String fingerprintHash,
    String? userAgent,
    String? locale,
    Map<String, dynamic>? metadata,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> loginCheck() => throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<AuthRegistrationResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    List<String>? anonymousUserIds,
  }) => throw UnimplementedError();
}

class _NoopTenantBackend extends TenantBackendContract {
  @override
  Future<Tenant> getTenant() => throw UnimplementedError();
}

class _NoopFavoriteBackend extends FavoriteBackendContract {
  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() =>
      throw UnimplementedError();

  @override
  Future<void> favoriteAccountProfile(String accountProfileId) =>
      throw UnimplementedError();

  @override
  Future<void> unfavoriteAccountProfile(String accountProfileId) =>
      throw UnimplementedError();
}

class _NoopVenueEventBackend extends VenueEventBackendContract {
  @override
  Future<List<VenueEventPreviewDTO>> fetchFeaturedEvents() =>
      throw UnimplementedError();

  @override
  Future<List<VenueEventPreviewDTO>> fetchUpcomingEvents() =>
      throw UnimplementedError();
}

class _NoopScheduleBackend extends ScheduleBackendContract {
  @override
  Future<EventDTO?> fetchEventDetail({
    required String eventIdOrSlug,
    String? occurrenceId,
  }) => throw UnimplementedError();

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    int? pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    List<String>? occurrenceIds,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) => throw UnimplementedError();

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    List<String>? occurrenceIds,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) => const Stream.empty();
}

AppData _buildAppData() {
  final platformType = PlatformTypeValue()..parse(AppType.mobile.name);
  return buildAppDataFromInitialization(
    remoteData: {
      'name': 'Guarappari',
      'type': 'tenant',
      'main_domain': 'https://guarappari.com.br',
      'domains': ['https://guarappari.com.br'],
      'app_domains': [],
      'theme_data_settings': {
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#E80D5D',
        'brightness_default': 'light',
      },
      'main_color': '#4FA0E3',
      'tenant_id': 'tenant-1',
      'telemetry': {'trackers': []},
    },
    localInfo: {
      'platformType': platformType,
      'hostname': 'guarappari.com.br',
      'href': 'https://guarappari.com.br',
      'port': null,
      'device': 'test-device',
    },
  );
}
