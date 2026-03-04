import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test(
      'favorites home flow sends agenda request with user origin when available',
      () async {
    final tenantDefaultOrigin = _buildCoordinate(
      latitude: -20.671339,
      longitude: -40.495395,
    );
    final userOrigin = _buildCoordinate(
      latitude: -20.611121,
      longitude: -40.498617,
    );
    final appData = _buildAppData(defaultOrigin: tenantDefaultOrigin);
    final appDataRepository = _FakeAppDataRepository(appData);
    final userLocationRepository = _FakeUserLocationRepository(
      userCoordinate: userOrigin,
    );
    final backend = _CapturingScheduleBackend();
    final scheduleRepository = ScheduleRepository(
      backend: backend,
      userLocationRepository: userLocationRepository,
      appDataRepository: appDataRepository,
    );

    final controller = FavoritesSectionController(
      favoriteRepository: _FakeFavoriteRepository(),
      partnersRepository: _FakeAccountProfilesRepository(),
      scheduleRepository: scheduleRepository,
      appDataRepository: appDataRepository,
    );

    await controller.init();

    expect(backend.requests, isNotEmpty);
    expect(
      backend.requests.first.originLat,
      closeTo(userOrigin.latitude, 0.000001),
    );
    expect(
      backend.requests.first.originLng,
      closeTo(userOrigin.longitude, 0.000001),
    );

    controller.onDispose();
  });

  test(
      'favorites home flow skips agenda request when user and tenant default origins are unavailable',
      () async {
    final appData = _buildAppData(defaultOrigin: null);
    final appDataRepository = _FakeAppDataRepository(appData);
    final userLocationRepository = _FakeUserLocationRepository();
    final backend = _CapturingScheduleBackend();
    final scheduleRepository = ScheduleRepository(
      backend: backend,
      userLocationRepository: userLocationRepository,
      appDataRepository: appDataRepository,
    );

    final controller = FavoritesSectionController(
      favoriteRepository: _FakeFavoriteRepository(),
      partnersRepository: _FakeAccountProfilesRepository(),
      scheduleRepository: scheduleRepository,
      appDataRepository: appDataRepository,
    );

    await controller.init();

    expect(backend.requests, isEmpty);
    expect(controller.favoritesStreamValue.value, isNotNull);

    controller.onDispose();
  });
}

class _FakeFavoriteRepository implements FavoriteRepositoryContract {
  @override
  Future<List<Favorite>> fetchFavorites() async => <Favorite>[];

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async =>
      <FavoriteResume>[];
}

class _FakeAccountProfilesRepository
    implements AccountProfilesRepositoryContract {
  @override
  final StreamValue<List<AccountProfileModel>> allAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);

  @override
  final StreamValue<Set<String>> favoriteAccountProfileIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  Future<void> init() async {}

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async =>
      <AccountProfileModel>[];

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async =>
      <AccountProfileModel>[];

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(String slug) async =>
      null;

  @override
  Future<void> toggleFavorite(String accountProfileId) async {}

  @override
  bool isFavorite(String accountProfileId) => false;

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() =>
      <AccountProfileModel>[];
}

class _CapturingScheduleBackend implements ScheduleBackendContract {
  final List<_AgendaRequestSample> requests = <_AgendaRequestSample>[];

  @override
  Future<EventSummaryDTO> fetchSummary() async =>
      EventSummaryDTO(items: const []);

  @override
  Future<List<EventDTO>> fetchEvents() async => const [];

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      null;

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
  }) async {
    requests.add(
      _AgendaRequestSample(
        page: page,
        originLat: originLat,
        originLng: originLng,
      ),
    );
    if (page > 1) {
      return EventPageDTO(events: const [], hasMore: false);
    }
    return EventPageDTO(
      events: [_buildEventDto()],
      hasMore: false,
    );
  }

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
      const Stream<EventDeltaDTO>.empty();
}

class _AgendaRequestSample {
  const _AgendaRequestSample({
    required this.page,
    required this.originLat,
    required this.originLng,
  });

  final int page;
  final double? originLat;
  final double? originLng;
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  _FakeUserLocationRepository({
    CityCoordinate? userCoordinate,
    CityCoordinate? lastKnownCoordinate,
  })  : userLocationStreamValue =
            StreamValue<CityCoordinate?>(defaultValue: userCoordinate),
        lastKnownLocationStreamValue =
            StreamValue<CityCoordinate?>(defaultValue: lastKnownCoordinate);

  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue;

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue;

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
  Future<bool> warmUpIfPermitted() async {
    return userLocationStreamValue.value != null ||
        lastKnownLocationStreamValue.value != null;
  }

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

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData)
      : maxRadiusMetersStreamValue =
            StreamValue<double>(defaultValue: _appData.mapRadiusMaxMeters);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeStreamValue.addValue(mode);
  }

  @override
  final StreamValue<double> maxRadiusMetersStreamValue;

  @override
  double get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(double meters) async {
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

AppData _buildAppData({
  required CityCoordinate? defaultOrigin,
}) {
  final mapUi = <String, dynamic>{
    'radius': const {
      'min_km': 1,
      'default_km': 5,
      'max_km': 50,
    },
  };
  if (defaultOrigin != null) {
    mapUi['default_origin'] = {
      'lat': defaultOrigin.latitude,
      'lng': defaultOrigin.longitude,
      'label': 'Tenant Default',
    };
  }

  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
        },
      },
    ],
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
      'brightness_default': 'dark',
      'primary_seed_color': '#112233',
      'secondary_seed_color': '#445566',
    },
    'main_color': '#112233',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
    'settings': {
      'map_ui': mapUi,
    },
  };

  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };

  return AppData.fromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

CityCoordinate _buildCoordinate({
  required double latitude,
  required double longitude,
}) {
  final lat = LatitudeValue()..parse(latitude.toString());
  final lng = LongitudeValue()..parse(longitude.toString());
  return CityCoordinate(
    latitudeValue: lat,
    longitudeValue: lng,
  );
}

EventDTO _buildEventDto() {
  return EventDTO.fromJson({
    'event_id': '507f1f77bcf86cd799439011',
    'occurrence_id': '507f1f77bcf86cd799439012',
    'slug': 'evento-teste',
    'title': 'Evento Teste',
    'content': 'Conteudo do evento completo',
    'type': {
      'id': 'type-1',
      'name': 'Show',
      'slug': 'show',
      'description': 'Show type description',
      'color': '#112233',
    },
    'location': {
      'mode': 'physical',
      'display_name': 'Praia do Morro',
      'geo': {
        'type': 'Point',
        'coordinates': [-40.495395, -20.671339],
      },
    },
    'date_time_start': '2099-01-01T20:00:00+00:00',
    'artists': const [],
    'tags': const ['music'],
  });
}
