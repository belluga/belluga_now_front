import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
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

  test('fetchAccountProfilesPage returns items when registry enables type',
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

    final page = await repository.fetchAccountProfilesPage(
      page: AccountProfilesRepositoryContractPrimInt.fromRaw(1),
      pageSize: AccountProfilesRepositoryContractPrimInt.fromRaw(30),
    );

    expect(page.profiles, hasLength(1));
    expect(page.profiles.first.type, 'artist');
  });

  test('fetchAccountProfilesPage does not force profile_type list for "Todos"',
      () async {
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
          name: 'Artist One',
          slug: 'artist-one',
          type: 'artist',
        ),
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
          name: 'Artist Two',
          slug: 'artist-two',
          type: 'artist',
        ),
      ],
    );
    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: _StubFavoriteBackend(favorites: const []),
      favoriteAccountProfileIds: const {},
    );

    final page = await repository.fetchAccountProfilesPage(
      page: AccountProfilesRepositoryContractPrimInt.fromRaw(1),
      pageSize: AccountProfilesRepositoryContractPrimInt.fromRaw(30),
      typeFilter: null,
    );

    expect(backend.lastAllowedTypes, isNull);
    expect(page.profiles, hasLength(2));
  });

  test('fetchAccountProfilesPage forwards canonical type and taxonomy filters',
      () async {
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
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

    await repository.fetchAccountProfilesPage(
      page: AccountProfilesRepositoryContractPrimInt.fromRaw(1),
      pageSize: AccountProfilesRepositoryContractPrimInt.fromRaw(30),
      typeFilters: [
        AccountProfilesRepositoryContractPrimString.fromRaw('artist'),
        AccountProfilesRepositoryContractPrimString.fromRaw('venue'),
      ],
      taxonomyFilters: [
        AccountProfilesRepositoryTaxonomyFilter.fromRaw(
          type: 'genre',
          value: 'rock',
        ),
      ],
    );

    expect(backend.lastTypeFilters, const ['artist', 'venue']);
    expect(backend.lastTaxonomyFilters.map((filter) => filter.type.value),
        const ['genre']);
    expect(backend.lastTaxonomyFilters.map((filter) => filter.term.value),
        const ['rock']);
  });

  test(
      'init loads favorite ids from backend favorites source without preloading full catalog',
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
      repository.favoriteAccountProfileIdsStreamValue.value
          .map((entry) => entry.value)
          .toSet(),
      contains('profile-fav-1'),
    );
    expect(backend.fetchAccountProfilesPageCalls, 0);
    expect(repository.allAccountProfilesStreamValue.value, isEmpty);
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

    await repository.toggleFavorite(
      AccountProfilesRepositoryContractPrimString.fromRaw(validId),
    );
    expect(favoritesBackend.favoritedIds, contains(validId));
    expect(
      repository.favoriteAccountProfileIdsStreamValue.value
          .map((entry) => entry.value)
          .toSet(),
      contains(validId),
    );

    await repository.toggleFavorite(
      AccountProfilesRepositoryContractPrimString.fromRaw(validId),
    );
    expect(favoritesBackend.unfavoritedIds, contains(validId));
    expect(
      repository.favoriteAccountProfileIdsStreamValue.value
          .map((entry) => entry.value)
          .toSet(),
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

  test(
      'toggleFavorite refreshes canonical favorite resumes consumed by Home after mutations',
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
      favoritePreviewsByAccountProfileId: {
        validId: _favoritePreview(
          id: validId,
          title: 'Artist One',
        ),
      },
    );
    final favoriteRepository = _TrackingFavoriteRepository(
      favoriteBackend: favoritesBackend,
    );
    GetIt.I.registerSingleton<FavoriteRepositoryContract>(favoriteRepository);

    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: favoritesBackend,
      favoriteAccountProfileIds: const {},
    );

    await repository.toggleFavorite(
      AccountProfilesRepositoryContractPrimString.fromRaw(validId),
    );

    expect(favoritesBackend.favoritedIds, contains(validId));
    expect(
      favoritesBackend.operationLog,
      ['favorite:$validId', 'fetchFavorites'],
    );
    expect(favoriteRepository.fetchFavoriteResumesCallCount, 1);
    expect(
      favoriteRepository.favoriteResumesStreamValue.value
          ?.map((favorite) => favorite.title)
          .toList(),
      ['Artist One'],
    );

    await repository.toggleFavorite(
      AccountProfilesRepositoryContractPrimString.fromRaw(validId),
    );

    expect(favoritesBackend.unfavoritedIds, contains(validId));
    expect(
      favoritesBackend.operationLog,
      [
        'favorite:$validId',
        'fetchFavorites',
        'unfavorite:$validId',
        'fetchFavorites',
      ],
    );
    expect(favoriteRepository.fetchFavoriteResumesCallCount, 2);
    expect(favoriteRepository.favoriteResumesStreamValue.value, isEmpty);
  });

  test(
      'toggleFavorite does not refresh Home favorite resumes when persistence fails',
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
      throwOnFavorite: true,
      favoritePreviewsByAccountProfileId: {
        validId: _favoritePreview(
          id: validId,
          title: 'Artist One',
        ),
      },
    );
    final favoriteRepository = _TrackingFavoriteRepository(
      favoriteBackend: favoritesBackend,
    );
    GetIt.I.registerSingleton<FavoriteRepositoryContract>(favoriteRepository);

    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: favoritesBackend,
      favoriteAccountProfileIds: const {},
    );

    await repository.toggleFavorite(
      AccountProfilesRepositoryContractPrimString.fromRaw(validId),
    );

    expect(favoritesBackend.operationLog, ['favorite:$validId']);
    expect(favoritesBackend.favoritedIds, isEmpty);
    expect(favoriteRepository.fetchFavoriteResumesCallCount, 0);
    expect(favoriteRepository.favoriteResumesStreamValue.value, isNull);
    expect(
      repository.favoriteAccountProfileIdsStreamValue.value
          .map((entry) => entry.value),
      isNot(contains(validId)),
    );
  });

  test(
      'toggleFavorite keeps persisted state when Home favorite resume refresh fails',
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
      favoritePreviewsByAccountProfileId: {
        validId: _favoritePreview(
          id: validId,
          title: 'Artist One',
        ),
      },
    );
    final favoriteRepository = _TrackingFavoriteRepository(
      favoriteBackend: favoritesBackend,
      throwOnRefreshFavoriteResumes: true,
    );
    GetIt.I.registerSingleton<FavoriteRepositoryContract>(favoriteRepository);

    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: favoritesBackend,
      favoriteAccountProfileIds: const {},
    );

    await repository.toggleFavorite(
      AccountProfilesRepositoryContractPrimString.fromRaw(validId),
    );

    expect(favoritesBackend.favoritedIds, contains(validId));
    expect(favoriteRepository.refreshFavoriteResumesCallCount, 1);
    expect(
      repository.favoriteAccountProfileIdsStreamValue.value
          .map((entry) => entry.value),
      contains(validId),
    );
  });

  test('fetchNearbyAccountProfiles keeps only favoritable registry types',
      () async {
    final artistId = _generateMongoId();
    final curatorId = _generateMongoId();
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: artistId,
          name: 'Nearby Artist',
          slug: 'nearby-artist',
          type: 'artist',
        ),
        buildAccountProfileModelFromPrimitives(
          id: curatorId,
          name: 'Nearby Curator',
          slug: 'nearby-curator',
          type: 'curator',
        ),
      ],
    );
    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: _StubFavoriteBackend(favorites: const []),
      favoriteAccountProfileIds: const {},
    );

    final nearby = await repository.fetchNearbyAccountProfiles(
      pageSize: AccountProfilesRepositoryContractPrimInt.fromRaw(10),
    );

    expect(nearby, hasLength(1));
    expect(nearby.first.type, 'artist');
  });

  test(
      'getAccountProfileBySlug delegates to backend direct lookup without paged scans',
      () async {
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
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

    final profile = await repository.getAccountProfileBySlug(
      AccountProfilesRepositoryContractPrimString.fromRaw('artist-one'),
    );

    expect(profile?.slug, 'artist-one');
    expect(backend.fetchBySlugCalls, 1);
    expect(backend.fetchAccountProfilesPageCalls, 0);
  });

  test('paged account profiles stream accumulates loaded pages canonically',
      () async {
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
          name: 'Artist One',
          slug: 'artist-one',
          type: 'artist',
        ),
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
          name: 'Artist Two',
          slug: 'artist-two',
          type: 'artist',
        ),
      ],
    );
    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: _StubFavoriteBackend(favorites: const []),
      favoriteAccountProfileIds: const {},
    );

    await repository.loadAccountProfilesPage(
      pageSize: AccountProfilesRepositoryContractPrimInt.fromRaw(1),
    );
    expect(repository.currentPagedAccountProfilesPage.value, 1);
    expect(repository.pagedAccountProfilesStreamValue.value?.profiles,
        hasLength(1));
    expect(
        repository.hasMorePagedAccountProfilesStreamValue.value.value, isTrue);

    await repository.loadNextAccountProfilesPage(
      pageSize: AccountProfilesRepositoryContractPrimInt.fromRaw(1),
    );
    expect(repository.currentPagedAccountProfilesPage.value, 2);
    expect(repository.pagedAccountProfilesStreamValue.value?.profiles,
        hasLength(2));
    expect(
        repository.hasMorePagedAccountProfilesStreamValue.value.value, isFalse);
  });

  test(
      'discovery nearby stream uses dedicated near endpoint even with paged cache',
      () async {
    final backend = _StubAccountProfilesBackend(
      accountProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
          name: 'Artist One',
          slug: 'artist-one',
          type: 'artist',
        ),
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
          name: 'Curator One',
          slug: 'curator-one',
          type: 'curator',
        ),
      ],
      nearbyProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
          name: 'Nearest Venue',
          slug: 'nearest-venue',
          type: 'artist',
          distanceMeters: 120,
        ),
        buildAccountProfileModelFromPrimitives(
          id: _generateMongoId(),
          name: 'Second Venue',
          slug: 'second-venue',
          type: 'artist',
          distanceMeters: 340,
        ),
      ],
    );
    final repository = AccountProfilesRepository(
      backend: backend,
      favoriteBackend: _StubFavoriteBackend(favorites: const []),
      favoriteAccountProfileIds: const {},
    );

    await repository.loadAccountProfilesPage(
      pageSize: AccountProfilesRepositoryContractPrimInt.fromRaw(10),
    );
    await repository.syncDiscoveryNearbyAccountProfiles(
      pageSize: AccountProfilesRepositoryContractPrimInt.fromRaw(10),
    );

    expect(backend.fetchNearbyCalls, 1);
    expect(repository.discoveryNearbyAccountProfilesStreamValue.value,
        hasLength(2));
    expect(
      repository.discoveryNearbyAccountProfilesStreamValue.value
          .map((profile) => profile.name)
          .toList(),
      ['Nearest Venue', 'Second Venue'],
    );
  });
}

class _StubAccountProfilesBackend implements AccountProfilesBackendContract {
  _StubAccountProfilesBackend({
    required this.accountProfiles,
    this.nearbyProfiles = const <AccountProfileModel>[],
  });

  final List<AccountProfileModel> accountProfiles;
  final List<AccountProfileModel> nearbyProfiles;
  List<String>? lastAllowedTypes;
  List<String>? lastTypeFilters;
  List<AccountProfilesRepositoryTaxonomyFilter> lastTaxonomyFilters =
      const <AccountProfilesRepositoryTaxonomyFilter>[];
  int fetchAccountProfilesPageCalls = 0;
  int fetchBySlugCalls = 0;
  int fetchNearbyCalls = 0;

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
    List<String>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
    List<String>? allowedTypes,
  }) async {
    fetchAccountProfilesPageCalls += 1;
    lastAllowedTypes = allowedTypes;
    lastTypeFilters = typeFilters;
    lastTaxonomyFilters =
        List<AccountProfilesRepositoryTaxonomyFilter>.of(taxonomyFilters ?? []);
    final start = (page - 1) * pageSize;
    if (start < 0 || start >= accountProfiles.length) {
      return pagedAccountProfilesResultFromRaw(
        profiles: <AccountProfileModel>[],
        hasMore: false,
      );
    }
    final end = (start + pageSize).clamp(0, accountProfiles.length);
    return pagedAccountProfilesResultFromRaw(
      profiles: accountProfiles.sublist(start, end),
      hasMore: end < accountProfiles.length,
    );
  }

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) async {
    fetchBySlugCalls += 1;
    return accountProfiles.firstWhere((profile) => profile.slug == slug);
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
    List<String>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async {
    fetchNearbyCalls += 1;
    final source = nearbyProfiles.isEmpty ? accountProfiles : nearbyProfiles;
    return source.take(pageSize).toList(growable: false);
  }
}

class _NoopTelemetry implements TelemetryRepositoryContract {
  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
          EventTrackerTimedEventHandle handle) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      telemetryRepoBool(true);

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      null;

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
          {required TelemetryRepositoryContractPrimString
              previousUserId}) async =>
      telemetryRepoBool(true);
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
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    calls.add(
      _TelemetryCall(
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
          EventTrackerTimedEventHandle handle) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      null;

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
          {required TelemetryRepositoryContractPrimString
              previousUserId}) async =>
      telemetryRepoBool(true);
}

class _StubFavoriteBackend extends FavoriteBackendContract {
  _StubFavoriteBackend({
    required this.favorites,
    Map<String, FavoritePreviewDTO>? favoritePreviewsByAccountProfileId,
    this.throwOnFavorite = false,
  })  : _favoritesByAccountProfileId = {
          for (final favorite in favorites)
            (favorite.targetId ?? favorite.id): favorite,
        },
        _favoritePreviewsByAccountProfileId =
            Map<String, FavoritePreviewDTO>.from(
          favoritePreviewsByAccountProfileId ?? const {},
        );

  final List<FavoritePreviewDTO> favorites;
  final bool throwOnFavorite;
  final List<String> favoritedIds = <String>[];
  final List<String> unfavoritedIds = <String>[];
  final List<String> operationLog = <String>[];
  final Map<String, FavoritePreviewDTO> _favoritesByAccountProfileId;
  final Map<String, FavoritePreviewDTO> _favoritePreviewsByAccountProfileId;

  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() async {
    operationLog.add('fetchFavorites');
    return _favoritesByAccountProfileId.values.toList(growable: false);
  }

  @override
  Future<void> favoriteAccountProfile(String accountProfileId) async {
    operationLog.add('favorite:$accountProfileId');
    if (throwOnFavorite) {
      throw StateError('favorite failed');
    }
    favoritedIds.add(accountProfileId);
    _favoritesByAccountProfileId[accountProfileId] =
        _favoritePreviewsByAccountProfileId[accountProfileId] ??
            _favoritePreview(
              id: accountProfileId,
              title: accountProfileId,
            );
  }

  @override
  Future<void> unfavoriteAccountProfile(String accountProfileId) async {
    operationLog.add('unfavorite:$accountProfileId');
    unfavoritedIds.add(accountProfileId);
    _favoritesByAccountProfileId.remove(accountProfileId);
  }
}

class _TrackingFavoriteRepository extends FavoriteRepositoryContract {
  _TrackingFavoriteRepository({
    required this.favoriteBackend,
    this.throwOnRefreshFavoriteResumes = false,
  });

  final FavoriteBackendContract favoriteBackend;
  final bool throwOnRefreshFavoriteResumes;
  int fetchFavoriteResumesCallCount = 0;
  int refreshFavoriteResumesCallCount = 0;

  @override
  Future<List<Favorite>> fetchFavorites() async {
    final favorites = await favoriteBackend.fetchFavorites();
    return favorites.map((favorite) => favorite.toDomain()).toList(
          growable: false,
        );
  }

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async {
    fetchFavoriteResumesCallCount += 1;
    final favorites = await favoriteBackend.fetchFavorites();
    return favorites.map((favorite) => favorite.toResume()).toList(
          growable: false,
        );
  }

  @override
  Future<void> refreshFavoriteResumes() async {
    refreshFavoriteResumesCallCount += 1;
    if (throwOnRefreshFavoriteResumes) {
      throw StateError('refresh failed');
    }
    await super.refreshFavoriteResumes();
  }
}

FavoritePreviewDTO _favoritePreview({
  required String id,
  required String title,
}) {
  return FavoritePreviewDTO(
    id: id,
    title: title,
    targetId: id,
    registryKey: 'account_profile',
    targetType: 'account_profile',
    assetPath: 'assets/images/placeholder_avatar.png',
  );
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
      {
        'type': 'venue',
        'label': 'Venue',
        'allowed_taxonomies': ['genre'],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
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
