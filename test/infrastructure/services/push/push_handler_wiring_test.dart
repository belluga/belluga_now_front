// ignore_for_file: must_be_immutable

import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/platform_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
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
import 'package:belluga_now/presentation/common/push/controllers/push_options_controller.dart';
import 'package:belluga_now/infrastructure/services/push/push_transport_configurator.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';
import 'package:push_handler/push_handler.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    final appData = _buildTestAppData();
    GetIt.I.registerSingleton<AppData>(appData);
    final backend = _NoopBackend();
    backend.setContext(BackendContext.fromAppData(appData));
    GetIt.I.registerSingleton<BackendContract>(backend);
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(
      _FakeTelemetryRepository(),
    );
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    GetIt.I.registerSingleton<ContactsRepositoryContract>(
      _FakeContactsRepository(),
    );
    GetIt.I.registerSingleton<PushOptionsController>(PushOptionsController());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('PushTransportConfigurator builds expected config', () async {
    final authRepository =
        _FakeAuthRepository(userTokenValue: 'token-123', deviceId: 'device-1');

    final config =
        PushTransportConfigurator.build(authRepository: authRepository);

    final baseUrl = BellugaConstants.api.baseUrl;
    final expectedBaseUrl =
        baseUrl.endsWith('/') ? '${baseUrl}v1/' : '$baseUrl/v1/';
    expect(config.resolvedBaseUrl, expectedBaseUrl);
    expect(await config.tokenProvider?.call(), 'token-123');
    expect(await config.deviceIdProvider?.call(), 'device-1');
    expect(config.enableDebugLogs, kDebugMode);
  });

  test('PushTransportConfigurator returns null token when empty', () async {
    final authRepository =
        _FakeAuthRepository(userTokenValue: '', deviceId: 'device-1');

    final config =
        PushTransportConfigurator.build(authRepository: authRepository);

    expect(await config.tokenProvider?.call(), isNull);
  });

  test('ApplicationContract initializes push repository on non-web path',
      () async {
    final authRepository =
        _FakeAuthRepository(userTokenValue: 'token-123', deviceId: 'device-1');
    GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

    final app = _TestApplication();
    GetIt.I.registerSingleton<ApplicationContract>(app);

    final capture = _RepositoryCapture();
    await app.initializePushHandlerForTesting(
      isWebOverride: false,
      repositoryFactory: capture.factory,
    );

    expect(capture.factoryCalled, isTrue);
    expect(capture.initCalled, isTrue);
    expect(await capture.transportConfig?.tokenProvider?.call(), 'token-123');
    expect(capture.platformResolver?.call(),
        BellugaConstants.settings.platform);
  });

  test('ApplicationContract skips push init on web override', () async {
    final authRepository =
        _FakeAuthRepository(userTokenValue: 'token-123', deviceId: 'device-1');
    GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

    final app = _TestApplication();
    GetIt.I.registerSingleton<ApplicationContract>(app);

    final capture = _RepositoryCapture();
    await app.initializePushHandlerForTesting(
      isWebOverride: true,
      repositoryFactory: capture.factory,
    );

    expect(capture.factoryCalled, isFalse);
    expect(capture.initCalled, isFalse);
  });
}

class _TestApplication extends ApplicationContract {
  _TestApplication();

  @override
  Future<void> initialSettingsPlatform() async {}
}

class _RepositoryCapture {
  bool factoryCalled = false;
  bool initCalled = false;
  PushTransportConfig? transportConfig;
  String Function()? platformResolver;

  PushHandlerRepositoryContract factory({
    required PushTransportConfig transportConfig,
    required BuildContext? Function() contextProvider,
    required PushNavigationResolver navigationResolver,
    required Future<void> Function(RemoteMessage) onBackgroundMessage,
    Future<void> Function()? presentationGate,
    required Stream<dynamic>? authChangeStream,
    required String Function() platformResolver,
    Future<bool> Function(StepData step)? gatekeeper,
    Future<List<OptionItem>> Function(OptionSource source)? optionsBuilder,
    Future<void> Function(AnswerPayload answer, StepData step)? onStepSubmit,
    String? Function(StepData step, String? value)? stepValidator,
    Future<void> Function(ButtonData button, StepData step)? onCustomAction,
    void Function(PushEvent event)? onPushEvent,
  }) {
    factoryCalled = true;
    this.transportConfig = transportConfig;
    this.platformResolver = platformResolver;
    return _FakePushHandlerRepository(
      transportConfig: transportConfig,
      contextProvider: contextProvider,
      navigationResolver: navigationResolver,
      onBackgroundMessage: onBackgroundMessage,
      presentationGate: presentationGate,
      authChangeStream: authChangeStream,
      platformResolver: platformResolver,
      gatekeeper: gatekeeper,
      optionsBuilder: optionsBuilder,
      onStepSubmit: onStepSubmit,
      stepValidator: stepValidator,
      onCustomAction: onCustomAction,
      onPushEvent: onPushEvent,
      onInit: () => initCalled = true,
    );
  }
}

class _FakePushHandlerRepository extends PushHandlerRepositoryContract {
  _FakePushHandlerRepository({
    required super.transportConfig,
    required super.contextProvider,
    required super.navigationResolver,
    required super.onBackgroundMessage,
    super.presentationGate,
    super.gatekeeper,
    super.optionsBuilder,
    super.onStepSubmit,
    super.stepValidator,
    super.onCustomAction,
    super.onPushEvent,
    required super.authChangeStream,
    required super.platformResolver,
    required this.onInit,
  });

  final VoidCallback onInit;

  @override
  Future<void> init() async {
    onInit();
  }
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>(defaultValue: null);

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>(defaultValue: null);

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(String? address) async {
    lastKnownAddressStreamValue.addValue(address);
  }

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({Duration minInterval = const Duration(seconds: 30)}) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> startTracking({LocationTrackingMode mode = LocationTrackingMode.mapForeground}) async =>
      false;

  @override
  Future<void> stopTracking() async {}
}

class _FakeContactsRepository implements ContactsRepositoryContract {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<List<ContactModel>> getContacts() async => const [];
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    required this.userTokenValue,
    required this.deviceId,
  });

  final String userTokenValue;
  final String deviceId;
  final _backend = _NoopBackend();

  @override
  BackendContract get backend => _backend;

  @override
  String get userToken => userTokenValue;

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => deviceId;

  @override
  Future<String?> getUserId() async => null;

  @override
  bool get isUserLoggedIn => userTokenValue.isNotEmpty;

  @override
  bool get isAuthorized => userTokenValue.isNotEmpty;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() => throw UnimplementedError();

  @override
  Future<void> loginWithEmailPassword(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> signUpWithEmailPassword(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> sendTokenRecoveryPassword(String email, String codigoEnviado) =>
      throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<void> createNewPassword(String newPassword, String confirmPassword) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<void> updateUser(Map<String, Object?> data) =>
      throw UnimplementedError();
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
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
  PartnersBackendContract get partners => _NoopPartnersBackend();

  @override
  FavoriteBackendContract get favorites => _NoopFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _NoopVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _NoopScheduleBackend();
}

class _NoopAppDataBackend extends AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() => throw UnimplementedError();
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

AppData _buildTestAppData() {
  final platformType = PlatformTypeValue()..parse(PlatformType.mobile.name);
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
