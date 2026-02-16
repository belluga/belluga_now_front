import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/venue_event/venue_event_preview_dto.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('init issues identity token when none exists', () async {
    final authBackend = _FakeAuthBackend(
      tokenToReturn: 'identity-token-1',
      userIdToReturn: 'user-1',
    );
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );

    final repository = AuthRepository();
    await repository.init();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(authBackend.issueCount, 1);
    expect(repository.userToken, 'identity-token-1');

    final stored = await AuthRepository.storage.read(key: 'user_token');
    expect(stored, 'identity-token-1');
    final storedUserId = await AuthRepository.storage.read(key: 'user_id');
    expect(storedUserId, 'user-1');
  });

  test('init skips identity bootstrap in landlord environment', () async {
    final authBackend = _FakeAuthBackend(
      tokenToReturn: 'identity-token-landlord',
      userIdToReturn: 'user-landlord',
    );
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );
    GetIt.I.registerSingleton<AppData>(_buildLandlordAppData());

    final repository = AuthRepository();
    await repository.init();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(authBackend.issueCount, 0);
    expect(repository.userToken, '');
    final stored = await AuthRepository.storage.read(key: 'user_token');
    expect(stored, isNull);
  });

  test('init skips identity token when stored token exists', () async {
    FlutterSecureStorage.setMockInitialValues({'user_token': 'stored-token'});
    final authBackend = _FakeAuthBackend(
      tokenToReturn: 'identity-token-2',
      userIdToReturn: 'user-2',
    );
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );

    final repository = AuthRepository();
    await repository.init();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(repository.userToken, 'stored-token');
    expect(authBackend.issueCount, 0);
  });

  test('init retries issuing identity token on transient failures', () async {
    final authBackend = _FlakyAuthBackend(
      failuresBeforeSuccess: 2,
      tokenToReturn: 'identity-token-3',
      userIdToReturn: 'user-3',
    );
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );

    final repository = AuthRepository();
    await repository.init();

    expect(authBackend.issueCount, 3);
    expect(repository.userToken, 'identity-token-3');
  });

  test('init fails after exhausting identity retries', () async {
    final authBackend = _FlakyAuthBackend(
      failuresBeforeSuccess: 99,
      tokenToReturn: 'identity-token-never',
      userIdToReturn: 'user-never',
    );
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );

    final repository = AuthRepository();
    await expectLater(repository.init(), throwsException);
    expect(
      authBackend.issueCount,
      AuthRepository.anonymousIdentityMaxAttempts,
    );
  });

  test('init reissues identity when stored token fails validation', () async {
    FlutterSecureStorage.setMockInitialValues({
      'user_token': 'stored-token',
      'user_id': 'legacy-user',
    });
    final authBackend = _FailingLoginCheckBackend(
      tokenToReturn: 'identity-token-refresh',
      userIdToReturn: 'user-refresh',
    );
    GetIt.I.registerSingleton<BackendContract>(
      _FakeBackend(auth: authBackend),
    );

    final repository = AuthRepository();
    await repository.init();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(authBackend.issueCount, 1);
    expect(repository.userToken, 'identity-token-refresh');

    final stored = await AuthRepository.storage.read(key: 'user_token');
    expect(stored, 'identity-token-refresh');
    final storedUserId = await AuthRepository.storage.read(key: 'user_id');
    expect(storedUserId, 'user-refresh');
  });
}

class _FakeBackend extends BackendContract {
  _FakeBackend({required this.auth});

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
  final AuthBackendContract auth;

  @override
  TenantBackendContract get tenant => _UnsupportedTenantBackend();

  @override
  AccountProfilesBackendContract get accountProfiles =>
      _NoopAccountProfilesBackend();

  @override
  FavoriteBackendContract get favorites => _UnsupportedFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _UnsupportedVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _UnsupportedScheduleBackend();
}

class _UnsupportedAppDataBackend extends AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() => throw UnimplementedError();
}

class _NoopAccountProfilesBackend implements AccountProfilesBackendContract {
  @override
  Future<List<AccountProfileModel>> fetchAccountProfiles() =>
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

class _FakeAuthBackend extends AuthBackendContract {
  _FakeAuthBackend({
    required this.tokenToReturn,
    required this.userIdToReturn,
  });

  final String tokenToReturn;
  final String userIdToReturn;
  int issueCount = 0;

  @override
  Future<AnonymousIdentityResponse> issueAnonymousIdentity({
    required String deviceName,
    required String fingerprintHash,
    String? userAgent,
    String? locale,
    Map<String, dynamic>? metadata,
  }) async {
    issueCount += 1;
    return AnonymousIdentityResponse(
      token: tokenToReturn,
      userId: userIdToReturn,
      identityState: 'anonymous',
    );
  }

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> loginCheck() async {
    return UserDto(
      id: '507f1f77bcf86cd799439011',
      profile: UserProfileDto(
        name: 'Test User',
        email: 'user@example.com',
        birthday: '',
        pictureUrl: null,
      ),
      customData: const {},
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthRegistrationResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    List<String>? anonymousUserIds,
  }) =>
      throw UnimplementedError();
}

class _FlakyAuthBackend extends AuthBackendContract {
  _FlakyAuthBackend({
    required this.failuresBeforeSuccess,
    required this.tokenToReturn,
    required this.userIdToReturn,
  });

  final int failuresBeforeSuccess;
  final String tokenToReturn;
  final String userIdToReturn;
  int issueCount = 0;

  @override
  Future<AnonymousIdentityResponse> issueAnonymousIdentity({
    required String deviceName,
    required String fingerprintHash,
    String? userAgent,
    String? locale,
    Map<String, dynamic>? metadata,
  }) async {
    issueCount += 1;
    if (issueCount <= failuresBeforeSuccess) {
      throw Exception('Transient identity failure');
    }
    return AnonymousIdentityResponse(
      token: tokenToReturn,
      userId: userIdToReturn,
      identityState: 'anonymous',
    );
  }

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> loginCheck() async {
    return UserDto(
      id: '507f1f77bcf86cd799439011',
      profile: UserProfileDto(
        name: 'Test User',
        email: 'user@example.com',
        birthday: '',
        pictureUrl: null,
      ),
      customData: const {},
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthRegistrationResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    List<String>? anonymousUserIds,
  }) =>
      throw UnimplementedError();
}

class _FailingLoginCheckBackend extends _FakeAuthBackend {
  _FailingLoginCheckBackend({
    required super.tokenToReturn,
    required super.userIdToReturn,
  });

  @override
  Future<UserDto> loginCheck() async {
    throw Exception('Failed to validate auth token [status=401]');
  }
}

class _UnsupportedTenantBackend extends TenantBackendContract {
  @override
  Future<Tenant> getTenant() => throw UnimplementedError();
}

class _UnsupportedFavoriteBackend extends FavoriteBackendContract {
  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() =>
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

AppData _buildLandlordAppData() {
  final platform = PlatformTypeValue(defaultValue: AppType.mobile)
    ..parse(AppType.mobile.name);
  return AppData.fromInitialization(
    remoteData: {
      'name': 'Landlord',
      'type': 'landlord',
      'main_domain': 'https://landlord.example',
      'profile_types': const <Map<String, dynamic>>[],
      'domains': const <String>[],
      'app_domains': const <String>[],
      'theme_data_settings': {
        'primary_seed_color': '#000000',
        'secondary_seed_color': '#FFFFFF',
        'brightness_default': 'light',
      },
    },
    localInfo: {
      'platformType': platform,
      'port': '1.0.0',
      'hostname': 'landlord.example',
      'href': 'https://landlord.example',
      'device': 'test-device',
    },
  );
}
