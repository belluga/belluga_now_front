import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
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
      'User Name',
      'user@example.com',
      'Secret!234',
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
}

class _CaptureTelemetryRepository implements TelemetryRepositoryContract {
  final List<String> mergeCalls = <String>[];

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
    mergeCalls.add(previousUserId);
    return true;
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
  PartnersBackendContract get partners => _UnsupportedPartnersBackend();

  @override
  FavoriteBackendContract get favorites => _UnsupportedFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _UnsupportedVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _UnsupportedScheduleBackend();
}

class _CaptureAuthBackend extends AuthBackendContract {
  int registerCalls = 0;
  List<String>? lastAnonymousUserIds;

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) {
    throw UnimplementedError();
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

class _UnsupportedPartnersBackend extends PartnersBackendContract {
  @override
  Future<PartnerModel?> fetchPartnerBySlug(String slug) =>
      throw UnimplementedError();

  @override
  Future<List<PartnerModel>> fetchPartners() => throw UnimplementedError();

  @override
  Future<List<PartnerModel>> searchPartners({
    String? query,
    PartnerType? typeFilter,
  }) =>
      throw UnimplementedError();
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
      throw UnimplementedError();
}
