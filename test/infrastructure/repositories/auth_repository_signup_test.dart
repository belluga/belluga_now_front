import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/venue_event/venue_event_preview_dto.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    FlutterSecureStorage.setMockInitialValues({
      'user_id': '507f1f77bcf86cd799439012',
    });
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('signup merges anonymous identity and persists user id', () async {
    final authBackend = _CaptureAuthBackend();
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );
    final telemetry = _CaptureTelemetryRepository();
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetry);
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      AuthRepository(),
    );

    final repository = GetIt.I.get<AuthRepositoryContract<UserContract>>();
    await repository.signUpWithEmailPassword(
      authRepoString('User Name'),
      authRepoString('user@example.com'),
      authRepoString('Secret!234'),
    );

    expect(authBackend.registerCalls, 1);
    expect(authBackend.lastAnonymousUserIds, ['507f1f77bcf86cd799439012']);
    expect(telemetry.mergeCalls, ['507f1f77bcf86cd799439012']);

    final storedToken = await AuthRepository.storage.read(
      key: 'user_token',
    );
    final storedUserId = await AuthRepository.storage.read(key: 'user_id');
    expect(storedToken, 'token-registered');
    expect(storedUserId, '507f1f77bcf86cd799439011');
  });

  test('login merges anonymous identity and persists user id', () async {
    final authBackend = _CaptureAuthBackend(
      loginResponse: (
        UserDto(
          id: '507f1f77bcf86cd799439011',
          profile: UserProfileDto(
            name: 'User Name',
            email: 'user@example.com',
            birthday: '',
            pictureUrl: null,
          ),
          customData: const {},
        ),
        'token-registered',
      ),
    );
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );
    final telemetry = _CaptureTelemetryRepository();
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetry);
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      AuthRepository(),
    );

    final repository = GetIt.I.get<AuthRepositoryContract<UserContract>>();
    await repository.loginWithEmailPassword(
      authRepoString('user@example.com'),
      authRepoString('Secret!234'),
    );

    expect(telemetry.mergeCalls, ['507f1f77bcf86cd799439012']);
    final storedToken = await AuthRepository.storage.read(
      key: 'user_token',
    );
    final storedUserId = await AuthRepository.storage.read(key: 'user_id');
    expect(storedToken, 'token-registered');
    expect(storedUserId, '507f1f77bcf86cd799439011');
  });

  test('phone otp verification merges anonymous identity and persists user id',
      () async {
    final authBackend = _CaptureAuthBackend();
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );
    final telemetry = _CaptureTelemetryRepository();
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetry);
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      AuthRepository(),
    );

    final repository = GetIt.I.get<AuthRepositoryContract<UserContract>>();
    final challenge = await repository.requestPhoneOtpChallenge(
      authRepoString('+55 27 99999-0000'),
    );
    await repository.verifyPhoneOtpChallenge(
      challengeId: authRepoString(challenge.challengeId),
      phone: authRepoString(challenge.phone),
      code: authRepoString('123456'),
    );

    expect(authBackend.lastOtpPhone, '+55 27 99999-0000');
    expect(authBackend.lastOtpAnonymousUserIds, ['507f1f77bcf86cd799439012']);
    expect(telemetry.mergeCalls, ['507f1f77bcf86cd799439012']);

    final storedToken = await AuthRepository.storage.read(
      key: 'user_token',
    );
    final storedUserId = await AuthRepository.storage.read(key: 'user_id');
    expect(storedToken, 'token-phone-otp');
    expect(storedUserId, '507f1f77bcf86cd799439011');
  });

  test('phone otp challenge forwards requested delivery channel', () async {
    final authBackend = _CaptureAuthBackend();
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      AuthRepository(),
    );

    final repository = GetIt.I.get<AuthRepositoryContract<UserContract>>();
    final challenge = await repository.requestPhoneOtpChallenge(
      authRepoString('+55 27 99999-0000'),
      deliveryChannel: authRepoString('sms'),
    );

    expect(authBackend.lastOtpPhone, '+55 27 99999-0000');
    expect(authBackend.lastOtpDeliveryChannel, 'sms');
    expect(challenge.deliveryChannel, 'sms');
  });
}

class _CaptureTelemetryRepository implements TelemetryRepositoryContract {
  final List<String> mergeCalls = <String>[];

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
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
      EventTrackerTimedEventHandle handle) async {
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
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
      {required TelemetryRepositoryContractPrimString previousUserId}) async {
    mergeCalls.add(previousUserId.value);
    return telemetryRepoBool(true);
  }
}

class _FakeBackend extends BackendContract {
  _FakeBackend({required this.auth, BackendContext? context})
      : _context = context;

  @override
  final AuthBackendContract auth;

  BackendContext? _context;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  AppDataBackendContract get appData => _UnsupportedAppDataBackend();

  @override
  TenantBackendContract get tenant => _UnsupportedTenantBackend();

  @override
  AccountProfilesBackendContract get accountProfiles =>
      _UnsupportedAccountProfilesBackend();

  @override
  FavoriteBackendContract get favorites => _UnsupportedFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _UnsupportedVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _UnsupportedScheduleBackend();
}

class _CaptureAuthBackend extends AuthBackendContract {
  _CaptureAuthBackend({this.loginResponse});

  final (UserDto, String)? loginResponse;
  int registerCalls = 0;
  List<String>? lastAnonymousUserIds;
  String? lastOtpPhone;
  String? lastOtpDeliveryChannel;
  List<String>? lastOtpAnonymousUserIds;

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) {
    if (loginResponse == null) {
      throw UnimplementedError();
    }
    return Future.value(loginResponse!);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserDto> loginCheck() async {
    return UserDto(
      id: '507f1f77bcf86cd799439011',
      profile: UserProfileDto(
        name: 'User Name',
        email: 'user@example.com',
        birthday: '',
        pictureUrl: null,
      ),
      customData: const {},
    );
  }

  @override
  Future<AuthRegistrationResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    List<String>? anonymousUserIds,
  }) async {
    registerCalls += 1;
    lastAnonymousUserIds = anonymousUserIds;
    return const AuthRegistrationResponse(
      token: 'token-registered',
      userId: '507f1f77bcf86cd799439011',
      identityState: 'authenticated',
    );
  }

  @override
  Future<PhoneOtpChallengeResponse> requestPhoneOtpChallenge({
    required String phone,
    String? deliveryChannel,
  }) async {
    lastOtpPhone = phone;
    lastOtpDeliveryChannel = deliveryChannel;
    return PhoneOtpChallengeResponse(
      challengeId: 'otp-challenge-1',
      phone: phone,
      deliveryChannel: deliveryChannel ?? 'whatsapp',
      expiresAt: DateTime.utc(2026).toIso8601String(),
      resendAvailableAt: DateTime.utc(2026).toIso8601String(),
    );
  }

  @override
  Future<PhoneOtpVerificationResponse> verifyPhoneOtpChallenge({
    required String challengeId,
    required String phone,
    required String code,
    List<String>? anonymousUserIds,
  }) async {
    lastOtpAnonymousUserIds = anonymousUserIds;
    return PhoneOtpVerificationResponse(
      user: await loginCheck(),
      token: 'token-phone-otp',
      userId: '507f1f77bcf86cd799439011',
      identityState: 'registered',
    );
  }

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
}

class _UnsupportedTenantBackend extends TenantBackendContract {
  @override
  Future<Tenant> getTenant() => throw UnimplementedError();
}

class _UnsupportedAppDataBackend extends AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() => throw UnimplementedError();
}

class _UnsupportedAccountProfilesBackend
    extends AccountProfilesBackendContract {
  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) =>
      throw UnimplementedError();

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
    List<String>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) =>
      throw UnimplementedError();

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
    List<String>? typeFilters,
    List<dynamic>? taxonomyFilters,
    List<String>? allowedTypes,
  }) =>
      throw UnimplementedError();
}

class _UnsupportedFavoriteBackend extends FavoriteBackendContract {
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

class _UnsupportedVenueEventBackend extends VenueEventBackendContract {
  @override
  Future<List<VenueEventPreviewDTO>> fetchFeaturedEvents() =>
      throw UnimplementedError();

  @override
  Future<List<VenueEventPreviewDTO>> fetchUpcomingEvents() =>
      throw UnimplementedError();
}

class _UnsupportedScheduleBackend extends ScheduleBackendContract {
  @override
  Future<EventDTO?> fetchEventDetail({
    required String eventIdOrSlug,
    String? occurrenceId,
  }) =>
      throw UnimplementedError();

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    int? pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
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
      throw UnimplementedError();
}
