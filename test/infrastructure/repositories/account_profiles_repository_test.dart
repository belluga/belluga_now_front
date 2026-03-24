import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/repositories/account_profiles_repository.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(_NoopTelemetry());
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('fetchAllAccountProfiles returns items when registry enables type',
      () async {
    final validId = _generateMongoId();
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: validId,
          name: 'Artist One',
          slug: 'artist-one',
          type: 'artist',
        ),
      ],
    );
    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: _StubFavoriteBackend(favorites: const []),
      favoriteAccountProfileIds: const {},
    );

    final profiles = await repository.fetchAllAccountProfiles();

    expect(profiles, hasLength(1));
    expect(profiles.first.type, 'artist');
  });

  test('init loads favorite ids from backend favorites source', () async {
    final validId = _generateMongoId();
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: validId,
          name: 'Artist One',
          slug: 'artist-one',
          type: 'artist',
        ),
      ],
    );
    final favoritesBackend = _StubFavoriteBackend(
      favorites: [
        const FavoritePreviewDTO(
          id: 'profile-fav-1',
          title: 'Fav 1',
          targetId: 'profile-fav-1',
          registryKey: 'account_profile',
          targetType: 'account_profile',
        ),
      ],
    );

    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: favoritesBackend,
      favoriteAccountProfileIds: const {},
    );

    await repository.init();

    expect(
      repository.favoriteAccountProfileIdsStreamValue.value,
      contains('profile-fav-1'),
    );
  });

  test('toggleFavorite persists favorite and unfavorite through backend',
      () async {
    final validId = _generateMongoId();
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: validId,
          name: 'Artist One',
          slug: 'artist-one',
          type: 'artist',
        ),
      ],
    );
    final favoritesBackend = _StubFavoriteBackend(
      favorites: const [],
    );
    final telemetry = _SpyTelemetry();

    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: favoritesBackend,
      favoriteAccountProfileIds: const {},
      telemetryRepository: telemetry,
    );

    await repository.toggleFavorite(validId);
    expect(favoritesBackend.favoritedIds, contains(validId));
    expect(
      repository.favoriteAccountProfileIdsStreamValue.value,
      contains(validId),
    );

    await repository.toggleFavorite(validId);
    expect(favoritesBackend.unfavoritedIds, contains(validId));
    expect(
      repository.favoriteAccountProfileIdsStreamValue.value,
      isNot(contains(validId)),
    );

    expect(telemetry.calls, hasLength(2));
    expect(
      telemetry.calls.first.event,
      EventTrackerEvents.favoriteArtistToggled,
    );
    expect(
      telemetry.calls.first.eventName,
      'favorite_artist_toggled',
    );
    expect(
      telemetry.calls.first.properties?['account_profile_id'],
      validId,
    );
    expect(telemetry.calls.first.properties?['is_favorite'], isTrue);

    expect(
      telemetry.calls.last.event,
      EventTrackerEvents.favoriteArtistToggled,
    );
    expect(
      telemetry.calls.last.eventName,
      'favorite_artist_toggled',
    );
    expect(
      telemetry.calls.last.properties?['account_profile_id'],
      validId,
    );
    expect(telemetry.calls.last.properties?['is_favorite'], isFalse);
  });
}

class _StubAccountProfilesBackend implements AccountProfilesBackendContract {
  _StubAccountProfilesBackend({required this.accountProfiles});

  final List<AccountProfileModel> accountProfiles;

  @override
  Future<List<AccountProfileModel>> fetchAccountProfiles() async =>
      accountProfiles;

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  }) async {
    final start = (page - 1) * pageSize;
    if (start < 0 || start >= accountProfiles.length) {
      return const PagedAccountProfilesResult(
        profiles: <AccountProfileModel>[],
        hasMore: false,
      );
    }
    final end = (start + pageSize).clamp(0, accountProfiles.length);
    return PagedAccountProfilesResult(
      profiles: accountProfiles.sublist(start, end),
      hasMore: end < accountProfiles.length,
    );
  }

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) async =>
      accountProfiles.firstWhere((profile) => profile.slug == slug);

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async =>
      accountProfiles;
}

class _NoopTelemetry implements TelemetryRepositoryContract {
  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async =>
      true;

  @override
  Future<bool> flushTimedEvents() async => true;

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      true;

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      null;

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;
}

class _TelemetryCall {
  _TelemetryCall({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _SpyTelemetry implements TelemetryRepositoryContract {
  final List<_TelemetryCall> calls = <_TelemetryCall>[];

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    calls.add(
      _TelemetryCall(
        event: event,
        eventName: eventName,
        properties: properties,
      ),
    );
    return true;
  }

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async =>
      true;

  @override
  Future<bool> flushTimedEvents() async => true;

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      null;

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;
}

class _StubFavoriteBackend extends FavoriteBackendContract {
  _StubFavoriteBackend({
    required this.favorites,
  });

  final List<FavoritePreviewDTO> favorites;
  final List<String> favoritedIds = <String>[];
  final List<String> unfavoritedIds = <String>[];

  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() async => favorites;

  @override
  Future<void> favoriteAccountProfile(String accountProfileId) async {
    favoritedIds.add(accountProfileId);
  }

  @override
  Future<void> unfavoriteAccountProfile(String accountProfileId) async {
    unfavoritedIds.add(accountProfileId);
  }
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
      remoteData: remoteData, localInfo: localInfo);
}

String _generateMongoId() {
  // 24-char hex string to satisfy MongoIDValue validation in AccountProfileModel.
  return DateTime.now()
      .microsecondsSinceEpoch
      .toRadixString(16)
      .padLeft(24, '0')
      .substring(0, 24);
}
