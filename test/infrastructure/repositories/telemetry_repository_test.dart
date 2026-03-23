import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_profile.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
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
import 'package:belluga_now/infrastructure/repositories/telemetry_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_queue.dart';
import 'package:event_tracker_handler/domain/core/event_tracker_handler_contract.dart';
import 'package:event_tracker_handler/domain/event_data/event_tracker_data.dart';
import 'package:event_tracker_handler/domain/event_data/event_tracker_delivery_outcome.dart';
import 'package:event_tracker_handler/domain/event_data/event_tracker_user_data.dart';
import 'package:event_tracker_handler/domain/enum/event_tracker_delivery_status.dart';
import 'package:event_tracker_handler/domain/enum/event_tracker_events.dart';
import 'package:event_tracker_handler/domain/enum/event_tracker_type.dart';
import 'package:event_tracker_handler/domain/timed_events/event_tracker_timed_event_handle.dart';
import 'package:event_tracker_handler/domain/trackers/event_tracker_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class _LoggedEvent {
  _LoggedEvent({
    required this.type,
    required this.userData,
    required this.data,
  });

  final EventTrackerEvents type;
  final EventTrackerUserData userData;
  final EventTrackerData? data;
}

class _FakeEventTrackerHandler implements EventTrackerHandlerContract {
  _FakeEventTrackerHandler();

  final List<_LoggedEvent> events = <_LoggedEvent>[];
  final List<(EventTrackerEvents, String?)> timedEvents =
      <(EventTrackerEvents, String?)>[];
  final List<(String, EventTrackerUserData)> mergedIdentities =
      <(String, EventTrackerUserData)>[];
  EventTrackerDeliveryStatus logEventStatus =
      EventTrackerDeliveryStatus.delivered;

  @override
  final List<EventTrackerContract> trackers = <EventTrackerContract>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> timeEvent(EventTrackerEvents type, {String? eventName}) async {
    timedEvents.add((type, eventName));
  }

  @override
  Future<List<EventTrackerDeliveryOutcome>> logEvent({
    required EventTrackerEvents type,
    required EventTrackerUserData userData,
    EventTrackerData? data,
  }) async {
    events.add(
      _LoggedEvent(
        type: type,
        userData: userData,
        data: data,
      ),
    );
    return [
      EventTrackerDeliveryOutcome(
        trackerType: EventTrackerType.webhook,
        status: logEventStatus,
      ),
    ];
  }

  @override
  Future<void> mergeIdentity({
    required String previousUserId,
    required EventTrackerUserData userData,
  }) async {
    mergedIdentities.add((previousUserId, userData));
  }
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  _FakeUserLocationRepository({
    CityCoordinate? coordinate,
    DateTime? capturedAt,
    double? accuracy,
  }) {
    lastKnownLocationStreamValue.addValue(coordinate);
    lastKnownCapturedAtStreamValue.addValue(capturedAt);
    lastKnownAccuracyStreamValue.addValue(accuracy);
  }

  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>();

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>();

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>();

  @override
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(String? address) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({
    Duration minInterval = const Duration(seconds: 30),
  }) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      false;

  @override
  Future<void> stopTracking() async {}
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    String deviceId = 'device-1',
    String? storedUserId = 'user-1',
    UserContract? user,
  })  : _deviceId = deviceId,
        _storedUserId = storedUserId {
    userStreamValue.addValue(user);
  }

  final String _deviceId;
  String? _storedUserId;

  void setAuthenticatedUser(UserContract? user) {
    userStreamValue.addValue(user);
  }

  void setStoredUserId(String? userId) {
    _storedUserId = userId;
  }

  @override
  BackendContract get backend => _NoopBackend();

  @override
  String get userToken => '';

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => _deviceId;

  @override
  Future<String?> getUserId() async => _storedUserId;

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

class _NoopBackend extends BackendContract {
  BackendContext? _context;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  AppDataBackendContract get appData => _FakeAppDataBackend();

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
  Future<List<AccountProfileModel>> fetchAccountProfiles() =>
      throw UnimplementedError();

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  }) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) =>
      throw UnimplementedError();

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

class _FakeAppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() => throw UnimplementedError();
}

class _FakeAppDataLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<Map<String, dynamic>> getInfo() async => {};
}

class _FakeAppDataRepository extends AppDataRepository {
  _FakeAppDataRepository({required AppData appData})
      : super(
          backend: _FakeAppDataBackend(),
          localInfoSource: _FakeAppDataLocalInfoSource(),
        ) {
    this.appData = appData;
  }
}

CityCoordinate _buildCoordinate(double lat, double lng) {
  final latitude = LatitudeValue()..parse(lat.toString());
  final longitude = LongitudeValue()..parse(lng.toString());
  return CityCoordinate(latitudeValue: latitude, longitudeValue: longitude);
}

AppData _buildAppData({int locationFreshnessMinutes = 5}) {
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
      'telemetry': {
        'trackers': [
          {
            'type': 'mixpanel',
            'token': 'token',
            'track_all': true,
            'events': [],
          }
        ],
        'location_freshness_minutes': locationFreshnessMinutes,
      },
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

AppData _buildTelemetryDisabledAppData() {
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
      'telemetry': {
        'trackers': const [],
      },
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

UserBelluga _buildAuthenticatedUser({
  String id = '507f1f77bcf86cd799439011',
  String name = 'User Name',
  String email = 'user@example.com',
}) {
  return UserBelluga.fromPrimitives(
    id: id,
    profile: UserProfile.fromPrimitives(
      name: name,
      email: email,
    ),
  );
}

Future<void> _drainMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    GetIt.I.registerSingleton<AuthRepositoryContract>(_FakeAuthRepository());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('logEvent attaches screen_context and location_context when fresh',
      () async {
    final handler = _FakeEventTrackerHandler();
    final repository = TelemetryRepository(
      appDataRepository: _FakeAppDataRepository(appData: _buildAppData()),
      queue: TelemetryQueue(retryDelays: const [Duration.zero]),
      handler: handler,
    );
    repository.setScreenContext({
      'route_name': '/home',
      'route_type': 'TestRoute',
      'is_overlay': false,
    });

    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(
        coordinate: _buildCoordinate(-20.0, -40.0),
        capturedAt: DateTime.now(),
        accuracy: 12.5,
      ),
    );

    final ok = await repository.logEvent(
      EventTrackerEvents.viewContent,
      eventName: 'screen_view',
    );
    expect(ok, isTrue);
    expect(handler.events, hasLength(1));

    final customData = handler.events.single.data?.customData;
    expect(customData, isNotNull);
    expect(customData?['screen_context'], isA<Map>());
    expect(customData?['location_context'], isA<Map>());

    final locationContext =
        customData?['location_context'] as Map<String, dynamic>;
    expect(locationContext['lat'], closeTo(-20.0, 0.0001));
    expect(locationContext['lng'], closeTo(-40.0, 0.0001));
    expect(locationContext['accuracy_m'], closeTo(12.5, 0.0001));
    expect(locationContext['timestamp'], isNotEmpty);
  });

  test('logEvent omits location_context when stale', () async {
    final handler = _FakeEventTrackerHandler();
    final repository = TelemetryRepository(
      appDataRepository: _FakeAppDataRepository(
        appData: _buildAppData(locationFreshnessMinutes: 5),
      ),
      queue: TelemetryQueue(retryDelays: const [Duration.zero]),
      handler: handler,
    );

    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(
        coordinate: _buildCoordinate(-20.0, -40.0),
        capturedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        accuracy: 8.0,
      ),
    );

    final ok = await repository.logEvent(
      EventTrackerEvents.viewContent,
      eventName: 'screen_view',
    );
    expect(ok, isTrue);
    final customData = handler.events.single.data?.customData;
    expect(customData?['location_context'], isNull);
  });

  test('logEvent returns false when telemetry is disabled', () async {
    final handler = _FakeEventTrackerHandler();
    final repository = TelemetryRepository(
      appDataRepository: _FakeAppDataRepository(
        appData: _buildTelemetryDisabledAppData(),
      ),
      queue: TelemetryQueue(retryDelays: const [Duration.zero]),
      handler: handler,
    );

    final ok = await repository.logEvent(
      EventTrackerEvents.viewContent,
      eventName: 'screen_view',
    );

    expect(ok, isFalse);
    expect(handler.events, isEmpty);
  });

  test('startTimedEvent and finishTimedEvent emit telemetry payload', () async {
    final handler = _FakeEventTrackerHandler();
    final repository = TelemetryRepository(
      appDataRepository: _FakeAppDataRepository(appData: _buildAppData()),
      queue: TelemetryQueue(retryDelays: const [Duration.zero]),
      handler: handler,
    );

    final auth = GetIt.I.get<AuthRepositoryContract>() as _FakeAuthRepository;
    auth.setAuthenticatedUser(_buildAuthenticatedUser());

    final handle = await repository.startTimedEvent(
      EventTrackerEvents.poiOpened,
      eventName: 'poi_opened',
      properties: const {
        'poi_id': 'poi-123',
      },
    );

    expect(handle, isNotNull);
    expect(handler.timedEvents, hasLength(1));
    expect(handler.timedEvents.first.$1, EventTrackerEvents.poiOpened);
    expect(handler.timedEvents.first.$2, 'poi_opened');

    final finishOk = await repository.finishTimedEvent(handle!);
    expect(finishOk, isTrue);
    await _drainMicrotasks();

    expect(handler.events, hasLength(1));
    final emitted = handler.events.single;
    expect(emitted.type, EventTrackerEvents.poiOpened);
    expect(emitted.data?.eventName, 'poi_opened');
    expect(emitted.data?.customData?['poi_id'], 'poi-123');
    expect(emitted.data?.customData?['tenant_id'], 'tenant-1');
    expect(emitted.data?.customData?['user_id'], '507f1f77bcf86cd799439011');
  });

  test('flushTimedEvents emits all active timed events', () async {
    final handler = _FakeEventTrackerHandler();
    final repository = TelemetryRepository(
      appDataRepository: _FakeAppDataRepository(appData: _buildAppData()),
      queue: TelemetryQueue(retryDelays: const [Duration.zero]),
      handler: handler,
    );

    final auth = GetIt.I.get<AuthRepositoryContract>() as _FakeAuthRepository;
    auth.setAuthenticatedUser(_buildAuthenticatedUser());

    await repository.startTimedEvent(
      EventTrackerEvents.viewContent,
      eventName: 'first',
    );
    await repository.startTimedEvent(
      EventTrackerEvents.viewContent,
      eventName: 'second',
    );

    final flushed = await repository.flushTimedEvents();
    expect(flushed, isTrue);
    await _drainMicrotasks();

    expect(handler.events, hasLength(2));
    final names = handler.events.map((event) => event.data?.eventName).toSet();
    expect(names, containsAll(<String>{'first', 'second'}));
  });

  test('buildLifecycleObserver returns cached instance when enabled', () async {
    final repository = TelemetryRepository(
      appDataRepository: _FakeAppDataRepository(appData: _buildAppData()),
      queue: TelemetryQueue(retryDelays: const [Duration.zero]),
      handler: _FakeEventTrackerHandler(),
    );

    final first = repository.buildLifecycleObserver();
    final second = repository.buildLifecycleObserver();

    expect(first, isNotNull);
    expect(second, same(first));
  });

  test('timed APIs return disabled defaults when telemetry is disabled',
      () async {
    final repository = TelemetryRepository(
      appDataRepository: _FakeAppDataRepository(
        appData: _buildTelemetryDisabledAppData(),
      ),
      queue: TelemetryQueue(retryDelays: const [Duration.zero]),
      handler: _FakeEventTrackerHandler(),
    );

    final handle = await repository.startTimedEvent(
      EventTrackerEvents.viewContent,
      eventName: 'disabled',
    );
    final finish = await repository.finishTimedEvent(
      const EventTrackerTimedEventHandle('handle'),
    );
    final flush = await repository.flushTimedEvents();
    final observer = repository.buildLifecycleObserver();

    expect(handle, isNull);
    expect(finish, isFalse);
    expect(flush, isFalse);
    expect(observer, isNull);
  });

  test('mergeIdentity returns false for invalid prerequisites', () async {
    final repository = TelemetryRepository(
      appDataRepository: _FakeAppDataRepository(appData: _buildAppData()),
      queue: TelemetryQueue(retryDelays: const [Duration.zero]),
      handler: _FakeEventTrackerHandler(),
    );

    final emptyPrevious = await repository.mergeIdentity(previousUserId: '');
    expect(emptyPrevious, isFalse);

    final noUser = await repository.mergeIdentity(previousUserId: 'anon-1');
    expect(noUser, isFalse);
  });

  test('mergeIdentity sends once and deduplicates by source user id', () async {
    final handler = _FakeEventTrackerHandler();
    final repository = TelemetryRepository(
      appDataRepository: _FakeAppDataRepository(appData: _buildAppData()),
      queue: TelemetryQueue(retryDelays: const [Duration.zero]),
      handler: handler,
    );

    final auth = GetIt.I.get<AuthRepositoryContract>() as _FakeAuthRepository;
    auth.setAuthenticatedUser(_buildAuthenticatedUser());

    final first = await repository.mergeIdentity(previousUserId: 'anon-123');
    final second = await repository.mergeIdentity(previousUserId: 'anon-123');

    expect(first, isTrue);
    expect(second, isTrue);
    expect(handler.mergedIdentities, hasLength(1));
    expect(handler.mergedIdentities.single.$1, 'anon-123');
    expect(
      handler.mergedIdentities.single.$2.uuid,
      '507f1f77bcf86cd799439011',
    );
  });
}
