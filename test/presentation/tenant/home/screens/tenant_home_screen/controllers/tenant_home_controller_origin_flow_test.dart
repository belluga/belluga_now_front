import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/user_events_backend_contract.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  tearDown(() async {
    await GetIt.I.reset();
  });

  test('my-events home flow uses confirmed_only agenda contract', () async {
    final tenantDefaultOrigin = _buildCoordinate(
      latitude: -20.671339,
      longitude: -40.495395,
    );
    final appData = _buildAppData(defaultOrigin: tenantDefaultOrigin);
    final appDataRepository = _FakeAppDataRepository(appData);
    final userLocationRepository = _FakeUserLocationRepository();
    final backend = _CapturingScheduleBackend();

    GetIt.I.registerSingleton<AppData>(appData);

    final scheduleRepository = ScheduleRepository(
      backend: backend,
      userLocationRepository: userLocationRepository,
      appDataRepository: appDataRepository,
    );
    final userEventsRepository = UserEventsRepository(
      scheduleRepository: scheduleRepository,
      backend: _FakeUserEventsBackend(),
    );
    await userEventsRepository.confirmEventAttendance(
      userEventsRepoString(_CapturingScheduleBackend.eventId),
    );

    final controller = TenantHomeController(
      userEventsRepository: userEventsRepository,
      userLocationRepository: userLocationRepository,
    );

    await controller.init();

    expect(backend.requests, isNotEmpty);
    expect(backend.requests.first.confirmedOnly, isTrue);
    expect(backend.requests.first.showPastOnly, isFalse);
    expect(
      controller.myEventsFilteredStreamValue.value.map((event) => event.id),
      contains(_CapturingScheduleBackend.eventId),
    );

    controller.onDispose();
  });

  test('my-events home flow no longer depends on origin availability',
      () async {
    final appData = _buildAppData(defaultOrigin: null);
    final appDataRepository = _FakeAppDataRepository(appData);
    final userLocationRepository = _FakeUserLocationRepository();
    final backend = _CapturingScheduleBackend();

    GetIt.I.registerSingleton<AppData>(appData);

    final scheduleRepository = ScheduleRepository(
      backend: backend,
      userLocationRepository: userLocationRepository,
      appDataRepository: appDataRepository,
    );
    final userEventsRepository = UserEventsRepository(
      scheduleRepository: scheduleRepository,
      backend: _FakeUserEventsBackend(),
    );
    await userEventsRepository.confirmEventAttendance(
      userEventsRepoString(_CapturingScheduleBackend.eventId),
    );

    final controller = TenantHomeController(
      userEventsRepository: userEventsRepository,
      userLocationRepository: userLocationRepository,
    );

    await controller.init();

    expect(backend.requests, isNotEmpty);
    expect(backend.requests.first.confirmedOnly, isTrue);
    expect(
      controller.myEventsFilteredStreamValue.value.map((event) => event.id),
      contains(_CapturingScheduleBackend.eventId),
    );

    controller.onDispose();
  });

  test('my-events home flow paginates until has_more is false', () async {
    final tenantDefaultOrigin = _buildCoordinate(
      latitude: -20.671339,
      longitude: -40.495395,
    );
    final appData = _buildAppData(defaultOrigin: tenantDefaultOrigin);
    final appDataRepository = _FakeAppDataRepository(appData);
    final userLocationRepository = _FakeUserLocationRepository();
    final backend = _CapturingScheduleBackend(hasMoreFirstPage: true);

    GetIt.I.registerSingleton<AppData>(appData);

    final scheduleRepository = ScheduleRepository(
      backend: backend,
      userLocationRepository: userLocationRepository,
      appDataRepository: appDataRepository,
    );
    final userEventsRepository = UserEventsRepository(
      scheduleRepository: scheduleRepository,
      backend: _FakeUserEventsBackend(),
    );

    final events = await userEventsRepository.fetchMyEvents();

    expect(events.length, 2);
    expect(backend.requests.map((sample) => sample.page), [1, 2]);
    expect(backend.requests.every((sample) => sample.confirmedOnly), isTrue);
  });
}

class _CapturingScheduleBackend implements ScheduleBackendContract {
  _CapturingScheduleBackend({
    this.hasMoreFirstPage = false,
  });

  static const String eventId = '507f1f77bcf86cd799439011';
  final bool hasMoreFirstPage;

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
    bool liveNowOnly = false,
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
        confirmedOnly: confirmedOnly,
        showPastOnly: showPastOnly,
      ),
    );
    if (page > 1) {
      if (hasMoreFirstPage && page == 2) {
        return EventPageDTO(
          events: [_buildEventDto(eventId: '507f1f77bcf86cd799439013')],
          hasMore: false,
        );
      }
      return EventPageDTO(events: const [], hasMore: false);
    }
    return EventPageDTO(
      events: [_buildEventDto()],
      hasMore: hasMoreFirstPage,
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

class _FakeUserEventsBackend implements UserEventsBackendContract {
  final Set<String> _confirmed = <String>{};

  @override
  Future<Map<String, dynamic>> fetchConfirmedEventIds() async {
    return {'confirmed_event_ids': _confirmed.toList(growable: false)};
  }

  @override
  Future<Map<String, dynamic>> confirmAttendance({
    required String eventId,
    String? occurrenceId,
  }) async {
    _confirmed.add(eventId);
    return {
      'event_id': eventId,
      'occurrence_id': occurrenceId,
      'status': 'active',
      'kind': 'free_confirmation',
    };
  }

  @override
  Future<Map<String, dynamic>> unconfirmAttendance({
    required String eventId,
    String? occurrenceId,
  }) async {
    _confirmed.remove(eventId);
    return {
      'event_id': eventId,
      'occurrence_id': occurrenceId,
      'status': 'canceled',
      'kind': 'free_confirmation',
    };
  }
}

class _AgendaRequestSample {
  const _AgendaRequestSample({
    required this.page,
    required this.confirmedOnly,
    required this.showPastOnly,
  });

  final int page;
  final bool confirmedOnly;
  final bool showPastOnly;
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
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(Object? address) async {
    lastKnownAddressStreamValue.addValue(address as dynamic);
  }

  @override
  Future<bool> warmUpIfPermitted() async {
    return userLocationStreamValue.value != null ||
        lastKnownLocationStreamValue.value != null;
  }

  @override
  Future<bool> refreshIfPermitted({
    Object? minInterval,
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
            StreamValue<DistanceInMetersValue>(
              defaultValue: DistanceInMetersValue.fromRaw(
                _appData.mapRadiusMaxMeters,
                defaultValue: _appData.mapRadiusMaxMeters,
              ),
            );

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
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
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

  return buildAppDataFromInitialization(
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

EventDTO _buildEventDto({
  String eventId = _CapturingScheduleBackend.eventId,
}) {
  return EventDTO.fromJson({
    'event_id': eventId,
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
