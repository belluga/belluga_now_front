import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
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
    final storedUserId =
        await AuthRepository.storage.read(key: 'user_id');
    expect(storedUserId, 'user-1');
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
}

class _FakeBackend extends BackendContract {
  _FakeBackend({required this.auth});

  @override
  final AuthBackendContract auth;

  @override
  TenantBackendContract get tenant => _UnsupportedTenantBackend();

  @override
  FavoriteBackendContract get favorites => _UnsupportedFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _UnsupportedVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _UnsupportedScheduleBackend();
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
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String? searchQuery,
  }) =>
      throw UnimplementedError();
}
