// ignore_for_file: must_be_immutable

import 'dart:collection';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/venue_event/venue_event_preview_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
      'app init retries until telemetry logging succeeds', (tester) async {
    GetIt.I.registerSingleton<AppDataRepository>(
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
    GetIt.I.registerSingleton<AppDataRepository>(
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
    expect(
      telemetry.lifecycleEvents.single,
      {
        'state': 'resumed',
        'sequence': ['paused', 'resumed'],
      },
    );
  });
}

class _TestApplication extends ApplicationContract {
  _TestApplication();

  @override
  Future<void> initialSettingsPlatform() async {}
}

class _TestModule extends ModuleContract {
  @override
  Future<void> registerDependencies() async {}

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: PageInfo.builder(
            'TestRoute',
            builder: (_, __) => const SizedBox.shrink(),
          ),
          path: '/',
        ),
      ];
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  _FakeTelemetryRepository({required Queue<bool> appInitResults})
      : _appInitResults = appInitResults;

  final Queue<bool> _appInitResults;
  int appInitCalls = 0;
  final List<Map<String, Object?>> lifecycleEvents =
      <Map<String, Object?>>[];

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    if (eventName == 'app_init') {
      appInitCalls += 1;
      if (_appInitResults.isNotEmpty) {
        return _appInitResults.removeFirst();
      }
    } else if (eventName == 'app_lifecycle') {
      final state = properties?['state'];
      final sequence = properties?['sequence'];
      if (state is String && sequence is List) {
        lifecycleEvents.add({
          'state': state,
          'sequence': sequence,
        });
      }
    }
    return true;
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    return null;
  }

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async {
    return true;
  }

  @override
  Future<bool> flushTimedEvents() async {
    return true;
  }

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async {
    return true;
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  @override
  BackendContract get backend => _NoopBackend();

  @override
  String get userToken => '';

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    String newPassword,
    String confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUser(Map<String, Object?> data) async {}
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
  Future<Map<String, dynamic>> getInfo() async => {};
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
  AccountProfilesBackendContract get accountProfiles => _NoopAccountProfilesBackend();

  @override
  FavoriteBackendContract get favorites => _NoopFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _NoopVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _NoopScheduleBackend();
}

class _NoopAccountProfilesBackend implements AccountProfilesBackendContract {
  @override
  Future<List<AccountProfileModel>> fetchAccountProfiles() => throw UnimplementedError();

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) =>
      throw UnimplementedError();

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) =>
      throw UnimplementedError();
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
  }) =>
      throw UnimplementedError();
}

class _NoopTenantBackend extends TenantBackendContract {
  @override
  Future<Tenant> getTenant() => throw UnimplementedError();
}

class _NoopFavoriteBackend extends FavoriteBackendContract {
  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() =>
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
  Future<EventSummaryDTO> fetchSummary() => throw UnimplementedError();

  @override
  Future<List<EventDTO>> fetchEvents() => throw UnimplementedError();

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) =>
      throw UnimplementedError();

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) =>
      throw UnimplementedError();

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) =>
      const Stream.empty();
}

AppData _buildAppData() {
  final platformType = PlatformTypeValue()..parse(AppType.mobile.name);
  return AppData.fromInitialization(
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
