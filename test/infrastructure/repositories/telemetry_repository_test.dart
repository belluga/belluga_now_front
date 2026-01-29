import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dao/partners_backend_contract.dart';
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
import 'package:event_tracker_handler/domain/trackers/event_tracker_contract.dart';
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
  final List<_LoggedEvent> events = <_LoggedEvent>[];

  @override
  final List<EventTrackerContract> trackers = <EventTrackerContract>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> timeEvent(EventTrackerEvents type, {String? eventName}) async {}

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
        status: EventTrackerDeliveryStatus.delivered,
      ),
    ];
  }

  @override
  Future<void> mergeIdentity({
    required String previousUserId,
    required EventTrackerUserData userData,
  }) async {}
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
  _FakeAuthRepository() {
    userStreamValue.addValue(null);
  }

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
  PartnersBackendContract get partners => _NoopPartnersBackend();

  @override
  FavoriteBackendContract get favorites => _NoopFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _NoopVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _NoopScheduleBackend();
}

class _NoopPartnersBackend implements PartnersBackendContract {
  @override
  Future<List<PartnerModel>> fetchPartners() => throw UnimplementedError();

  @override
  Future<List<PartnerModel>> searchPartners({
    String? query,
    PartnerType? typeFilter,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerModel?> fetchPartnerBySlug(String slug) =>
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

void main() {
  setUp(() async {
    await GetIt.I.reset();
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
}
