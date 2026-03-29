import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/controllers/discovery_screen_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('available discovery types include only favoritable profile types',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: PagedAccountProfilesResult(
          profiles: [
            _profile(id: _mongoId('a'), type: 'artist', name: 'Artist'),
            _profile(id: _mongoId('b'), type: 'curator', name: 'Curator'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(controller.availableTypesStreamValue.value, ['artist']);
    controller.onDispose();
  });

  test('toggle favorite requires authentication for anonymous users', () async {
    final artist = _profile(id: _mongoId('c'), type: 'artist', name: 'Artist');
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: PagedAccountProfilesResult(
          profiles: [artist],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: false),
    );

    await controller.init();
    final outcome = controller.toggleFavorite(artist.id);

    expect(outcome, FavoriteToggleOutcome.requiresAuthentication);
    expect(repository.toggleCalls, isEmpty);
    controller.onDispose();
  });

  test('discovery loads additional pages with loadNextPage', () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: PagedAccountProfilesResult(
          profiles: [
            _profile(id: _mongoId('d'), type: 'artist', name: 'First'),
          ],
          hasMore: true,
        ),
        2: PagedAccountProfilesResult(
          profiles: [
            _profile(id: _mongoId('e'), type: 'artist', name: 'Second'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(controller.hasMoreStreamValue.value, isTrue);

    await controller.loadNextPage();
    expect(controller.filteredPartnersStreamValue.value, hasLength(2));
    expect(controller.hasMoreStreamValue.value, isFalse);
    controller.onDispose();
  });

  test('discovery nearby section loads from independent repository request',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: PagedAccountProfilesResult(
          profiles: [
            _profile(id: _mongoId('d1'), type: 'artist', name: 'Grid Artist'),
          ],
          hasMore: false,
        ),
      },
      nearbyProfiles: [
        buildAccountProfileModelFromPrimitives(
          id: _mongoId('d2'),
          name: 'Nearby Venue',
          slug: 'nearby-venue',
          type: 'artist',
          distanceMeters: 320,
        ),
      ],
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.nearbyFetchCalls, 1);
    expect(controller.nearbyStreamValue.value, hasLength(1));
    expect(controller.nearbyStreamValue.value.first.name, 'Nearby Venue');
    expect(controller.nearbyStreamValue.value.first.distanceMeters, 320);
    controller.onDispose();
  });

  test('discovery live-now section loads real event page with live_now_only',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: PagedAccountProfilesResult(
          profiles: [
            _profile(id: _mongoId('l1'), type: 'artist', name: 'Grid Artist'),
          ],
          hasMore: false,
        ),
      },
    );
    final scheduleRepository = _FakeDiscoveryScheduleRepository(
      liveNowEvents: [
        _event(
          id: _mongoId('evt-live'),
          slug: 'evento-live',
          title: 'Evento ao vivo',
          artistName: 'Artista Live',
        ),
      ],
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
      scheduleRepository: scheduleRepository,
    );

    await controller.init();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(scheduleRepository.liveNowFetchCalls, 1);
    expect(controller.liveNowEventsStreamValue.value, hasLength(1));
    expect(controller.liveNowEventsStreamValue.value.first.slug, 'evento-live');
    expect(
      controller.liveNowEventsStreamValue.value.first.artists.first.displayName,
      'Artista Live',
    );
    controller.onDispose();
  });

  test(
      'discovery search keeps backend matches even when local name/tags do not match',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: PagedAccountProfilesResult(
          profiles: [
            buildAccountProfileModelFromPrimitives(
              id: _mongoId('f'),
              name: 'Resultado remoto',
              slug: 'slug-exato-remoto',
              type: 'artist',
              tags: const <String>[],
            ),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    controller.setSearchQuery('slug-exato-remoto');
    await Future<void>.delayed(const Duration(milliseconds: 450));

    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(controller.filteredPartnersStreamValue.value.first.slug,
        'slug-exato-remoto');
    expect(repository.pageRequests.last.query, 'slug-exato-remoto');
    controller.onDispose();
  });

  test('discovery selecting "Todos" resets to unfiltered list', () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: PagedAccountProfilesResult(
          profiles: [
            _profile(id: _mongoId('t1'), type: 'artist', name: 'Artist One'),
            _profile(id: _mongoId('t2'), type: 'venue', name: 'Venue One'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    expect(controller.filteredPartnersStreamValue.value, hasLength(2));

    controller.setTypeFilter('artist');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(controller.filteredPartnersStreamValue.value.first.type, 'artist');

    controller.setTypeFilter(null);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.filteredPartnersStreamValue.value, hasLength(2));
    expect(repository.pageRequests.last.typeFilter, isNull);
    controller.onDispose();
  });

  test(
      'discovery stops loading and keeps favoritable chips when first page fails',
      () async {
    final repository = _FailingAccountProfilesRepository();
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(controller.isLoadingStreamValue.value, isFalse);
    expect(controller.hasLoadedStreamValue.value, isTrue);
    expect(controller.availableTypesStreamValue.value, ['artist']);
    expect(controller.filteredPartnersStreamValue.value, isEmpty);
    controller.onDispose();
  });

  test('discovery still loads first page when repository init fails', () async {
    final repository = _InitFailingAccountProfilesRepository(
      firstPage: PagedAccountProfilesResult(
        profiles: [
          _profile(id: _mongoId('h'), type: 'artist', name: 'Recovered'),
        ],
        hasMore: false,
      ),
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(controller.isLoadingStreamValue.value, isFalse);
    expect(controller.hasLoadedStreamValue.value, isTrue);
    expect(controller.availableTypesStreamValue.value, ['artist']);
    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(
        controller.filteredPartnersStreamValue.value.first.name, 'Recovered');
    expect(repository.fetchPageCalls, 1);
    controller.onDispose();
  });

  test('toggle favorite persists mutation for identified users', () async {
    final artist = _profile(id: _mongoId('g'), type: 'artist', name: 'Artist');
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: PagedAccountProfilesResult(
          profiles: [artist],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    final outcome = controller.toggleFavorite(artist.id);

    expect(outcome, FavoriteToggleOutcome.toggled);
    await Future<void>.delayed(Duration.zero);
    expect(repository.toggleCalls, [artist.id]);
    expect(controller.favoriteIdsStreamValue.value.contains(artist.id), isTrue);
    controller.onDispose();
  });
}

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({
    required this.pages,
    this.nearbyProfiles = const <AccountProfileModel>[],
  });

  final Map<int, PagedAccountProfilesResult> pages;
  final List<AccountProfileModel> nearbyProfiles;
  final List<String> toggleCalls = <String>[];
  final List<_PageRequest> pageRequests = <_PageRequest>[];
  final Map<String, AccountProfileModel> _bySlug =
      <String, AccountProfileModel>{};
  int nearbyFetchCalls = 0;

  @override
  Future<void> init() async {
    final all =
        pages.values.expand((entry) => entry.profiles).toList(growable: false);
    allAccountProfilesStreamValue.addValue(all);
    favoriteAccountProfileIdsStreamValue.addValue(const <String>{});
    for (final profile in all) {
      _bySlug[profile.slug] = profile;
    }
  }

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async {
    return pages.values
        .expand((entry) => entry.profiles)
        .toList(growable: false);
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  }) async {
    pageRequests.add(
      _PageRequest(
        page: page,
        pageSize: pageSize,
        query: query?.trim(),
        typeFilter: typeFilter?.trim(),
      ),
    );
    var result = pages[page] ??
        const PagedAccountProfilesResult(
          profiles: <AccountProfileModel>[],
          hasMore: false,
        );

    var profiles = result.profiles;
    final normalizedType = typeFilter?.trim();
    if (normalizedType != null && normalizedType.isNotEmpty) {
      profiles = profiles
          .where((profile) => profile.type == normalizedType)
          .toList(growable: false);
    }

    final normalizedQuery = query?.trim().toLowerCase();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      profiles = profiles.where((profile) {
        return profile.name.toLowerCase().contains(normalizedQuery) ||
            profile.slug.toLowerCase().contains(normalizedQuery) ||
            profile.tags.any(
              (tag) => tag.toLowerCase().contains(normalizedQuery),
            );
      }).toList(growable: false);
    }

    result = PagedAccountProfilesResult(
      profiles: profiles,
      hasMore: result.hasMore,
    );

    return result;
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async {
    final all = await fetchAllAccountProfiles();
    final normalizedType = typeFilter?.trim();
    final normalizedQuery = query?.trim().toLowerCase();

    return all.where((profile) {
      final typeMatches = normalizedType == null ||
          normalizedType.isEmpty ||
          profile.type == normalizedType;
      if (!typeMatches) return false;
      if (normalizedQuery == null || normalizedQuery.isEmpty) {
        return true;
      }
      return profile.name.toLowerCase().contains(normalizedQuery) ||
          profile.slug.toLowerCase().contains(normalizedQuery) ||
          profile.tags
              .any((tag) => tag.toLowerCase().contains(normalizedQuery));
    }).toList(growable: false);
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(String slug) async {
    return _bySlug[slug];
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
  }) async {
    nearbyFetchCalls += 1;
    final source = nearbyProfiles.isEmpty
        ? await fetchAllAccountProfiles()
        : nearbyProfiles;
    return source.take(pageSize).toList(growable: false);
  }

  @override
  Future<void> toggleFavorite(String accountProfileId) async {
    toggleCalls.add(accountProfileId);
    final current =
        Set<String>.from(favoriteAccountProfileIdsStreamValue.value);
    if (current.contains(accountProfileId)) {
      current.remove(accountProfileId);
    } else {
      current.add(accountProfileId);
    }
    favoriteAccountProfileIdsStreamValue.addValue(current);
  }

  @override
  bool isFavorite(String accountProfileId) {
    return favoriteAccountProfileIdsStreamValue.value
        .contains(accountProfileId);
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    final ids = favoriteAccountProfileIdsStreamValue.value;
    return allAccountProfilesStreamValue.value
        .where((profile) => ids.contains(profile.id))
        .toList(growable: false);
  }
}

class _FailingAccountProfilesRepository
    extends AccountProfilesRepositoryContract {
  @override
  Future<void> init() async {
    allAccountProfilesStreamValue.addValue(const <AccountProfileModel>[]);
    favoriteAccountProfileIdsStreamValue.addValue(const <String>{});
  }

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async {
    return const <AccountProfileModel>[];
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  }) async {
    throw Exception('forced discovery page failure');
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async {
    return const <AccountProfileModel>[];
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(String slug) async {
    return null;
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
  }) async {
    return const <AccountProfileModel>[];
  }

  @override
  Future<void> toggleFavorite(String accountProfileId) async {}

  @override
  bool isFavorite(String accountProfileId) {
    return false;
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    return const <AccountProfileModel>[];
  }
}

class _InitFailingAccountProfilesRepository
    extends AccountProfilesRepositoryContract {
  _InitFailingAccountProfilesRepository({
    required this.firstPage,
  });

  final PagedAccountProfilesResult firstPage;
  int fetchPageCalls = 0;

  @override
  Future<void> init() async {
    throw Exception('forced repository init failure');
  }

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async {
    return firstPage.profiles;
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  }) async {
    fetchPageCalls += 1;
    if (page != 1) {
      return const PagedAccountProfilesResult(
        profiles: <AccountProfileModel>[],
        hasMore: false,
      );
    }
    return firstPage;
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async {
    return firstPage.profiles;
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(String slug) async {
    return null;
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
  }) async {
    return firstPage.profiles.take(pageSize).toList(growable: false);
  }

  @override
  Future<void> toggleFavorite(String accountProfileId) async {}

  @override
  bool isFavorite(String accountProfileId) {
    return false;
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    return const <AccountProfileModel>[];
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    required this.isAuthorizedValue,
  });

  final bool isAuthorizedValue;

  @override
  BackendContract get backend => throw UnimplementedError();

  @override
  String get userToken => 'token';

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => isAuthorizedValue;

  @override
  bool get isAuthorized => isAuthorizedValue;

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

class _FakeDiscoveryScheduleRepository extends ScheduleRepositoryContract {
  _FakeDiscoveryScheduleRepository({
    required this.liveNowEvents,
  });

  final List<EventModel> liveNowEvents;
  int liveNowFetchCalls = 0;
  HomeAgendaCacheSnapshot? _cacheSnapshot;

  @override
  final StreamValue<List<EventModel>?> homeAgendaEventsStreamValue =
      StreamValue<List<EventModel>?>();

  @override
  final StreamValue<HomeAgendaCacheSnapshot?> homeAgendaCacheStreamValue =
      StreamValue<HomeAgendaCacheSnapshot?>();

  @override
  HomeAgendaCacheSnapshot? readHomeAgendaCache({
    required bool showPastOnly,
    required String searchQuery,
    required bool confirmedOnly,
  }) {
    final snapshot = _cacheSnapshot;
    if (snapshot == null) {
      return null;
    }
    if (snapshot.showPastOnly != showPastOnly) {
      return null;
    }
    if (snapshot.searchQuery != searchQuery) {
      return null;
    }
    if (snapshot.confirmedOnly != confirmedOnly) {
      return null;
    }
    return snapshot;
  }

  @override
  void writeHomeAgendaCache(HomeAgendaCacheSnapshot snapshot) {
    _cacheSnapshot = snapshot;
    homeAgendaCacheStreamValue.addValue(snapshot);
    homeAgendaEventsStreamValue.addValue(snapshot.events);
  }

  @override
  void clearHomeAgendaCache() {
    _cacheSnapshot = null;
    homeAgendaCacheStreamValue.addValue(null);
    homeAgendaEventsStreamValue.addValue(null);
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    throw UnimplementedError();
  }

  @override
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    return const <EventModel>[];
  }

  @override
  Future<List<EventModel>> getAllEvents() async {
    return const <EventModel>[];
  }

  @override
  Future<EventModel?> getEventBySlug(String slug) async {
    return null;
  }

  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    if (liveNowOnly) {
      liveNowFetchCalls += 1;
      return PagedEventsResult(
        events: liveNowEvents.take(pageSize).toList(growable: false),
        hasMore: false,
      );
    }
    return const PagedEventsResult(events: <EventModel>[], hasMore: false);
  }

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date) async {
    return const <VenueEventResume>[];
  }

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async {
    return const <VenueEventResume>[];
  }

  @override
  Stream<EventDeltaModel> watchEventsStream({
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) {
    return const Stream<EventDeltaModel>.empty();
  }

  @override
  Stream<void> watchEventsSignal({
    required void Function(EventDeltaModel delta) onDelta,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) {
    return watchEventsStream(
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
      lastEventId: lastEventId,
      showPastOnly: showPastOnly,
    ).map((delta) => onDelta(delta));
  }
}

class _PageRequest {
  const _PageRequest({
    required this.page,
    required this.pageSize,
    required this.query,
    required this.typeFilter,
  });

  final int page;
  final int pageSize;
  final String? query;
  final String? typeFilter;
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
        'allowed_taxonomies': const [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
      {
        'type': 'curator',
        'label': 'Curator',
        'allowed_taxonomies': const [],
        'capabilities': {
          'is_favoritable': false,
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

AccountProfileModel _profile({
  required String id,
  required String type,
  required String name,
}) {
  return buildAccountProfileModelFromPrimitives(
    id: id,
    name: name,
    slug: '$name-$type'.toLowerCase().replaceAll(' ', '-'),
    type: type,
  );
}

EventModel _event({
  required String id,
  required String slug,
  required String title,
  required String artistName,
}) {
  return EventDTO.fromJson({
    'event_id': id,
    'slug': slug,
    'type': {
      'id': 'type-live',
      'name': 'Show',
      'slug': 'show',
      'description': 'Show',
      'icon': null,
      'color': null,
    },
    'title': title,
    'content': 'Conteúdo',
    'location': 'Local',
    'date_time_start': DateTime.now().toIso8601String(),
    'date_time_end':
        DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    'artists': [
      {
        'id': _mongoId('artist-live'),
        'display_name': artistName,
        'avatar_url': null,
        'highlight': true,
        'genres': ['samba'],
      },
    ],
    'thumb': {
      'type': 'image',
      'data': {'url': 'https://tenant.test/live.jpg'},
    },
  }).toDomain();
}

String _mongoId(String seed) {
  final base =
      seed.codeUnits.fold<int>(0, (acc, item) => acc + item).toRadixString(16);
  final repeated = List<String>.filled(24, base).join().substring(0, 24);
  return repeated;
}
