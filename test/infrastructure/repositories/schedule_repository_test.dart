import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('fetchUpcomingEvents uses user location as agenda origin', () async {
    final backend = _CapturingScheduleBackend();
    final userOrigin = _buildCoordinate(
      latitude: -20.611121,
      longitude: -40.498617,
    );
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(
        userCoordinate: userOrigin,
      ),
      appDataRepository: _FakeAppDataRepository(_buildAppData()),
    );

    final events = await repository.fetchUpcomingEvents();

    expect(events, isNotEmpty);
    expect(backend.requests, isNotEmpty);
    expect(backend.requests.first.originLat,
        closeTo(userOrigin.latitude, 0.000001));
    expect(backend.requests.first.originLng,
        closeTo(userOrigin.longitude, 0.000001));
  });

  test('fetchUpcomingEvents falls back to tenant default origin', () async {
    final backend = _CapturingScheduleBackend();
    final tenantDefault = _buildCoordinate(
      latitude: -20.671339,
      longitude: -40.495395,
    );
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(defaultOrigin: tenantDefault),
      ),
    );

    final events = await repository.fetchUpcomingEvents();

    expect(events, isNotEmpty);
    expect(backend.requests, isNotEmpty);
    expect(
      backend.requests.first.originLat,
      closeTo(tenantDefault.latitude, 0.000001),
    );
    expect(
      backend.requests.first.originLng,
      closeTo(tenantDefault.longitude, 0.000001),
    );
  });

  test('fetchUpcomingEvents skips backend when origin cannot be resolved',
      () async {
    final backend = _CapturingScheduleBackend();
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(defaultOrigin: null),
      ),
    );

    final events = await repository.fetchUpcomingEvents();

    expect(events, isEmpty);
    expect(backend.requests, isEmpty);
  });

  test(
      'fetchUpcomingEvents falls back to last-known user coordinate when warm-up throws',
      () async {
    final backend = _CapturingScheduleBackend();
    final lastKnownOrigin = _buildCoordinate(
      latitude: -20.622222,
      longitude: -40.477777,
    );
    final tenantDefault = _buildCoordinate(
      latitude: -20.671339,
      longitude: -40.495395,
    );
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(
        lastKnownCoordinate: lastKnownOrigin,
        throwOnWarmUp: true,
      ),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(defaultOrigin: tenantDefault),
      ),
    );

    final events = await repository.fetchUpcomingEvents();

    expect(events, isNotEmpty);
    expect(backend.requests, isNotEmpty);
    expect(
      backend.requests.first.originLat,
      closeTo(lastKnownOrigin.latitude, 0.000001),
    );
    expect(
      backend.requests.first.originLng,
      closeTo(lastKnownOrigin.longitude, 0.000001),
    );
  });

  test('fetchUpcomingEvents keeps origin across paginated requests', () async {
    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439011',
              occurrenceId: '507f1f77bcf86cd799439012',
              startsAtIso: '2099-01-01T20:00:00+00:00',
            ),
          ],
          hasMore: true,
        ),
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439021',
              occurrenceId: '507f1f77bcf86cd799439022',
              startsAtIso: '2099-01-02T20:00:00+00:00',
            ),
          ],
          hasMore: false,
        ),
      ],
    );
    final userOrigin = _buildCoordinate(
      latitude: -20.611121,
      longitude: -40.498617,
    );
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(
        userCoordinate: userOrigin,
      ),
      appDataRepository: _FakeAppDataRepository(_buildAppData()),
    );

    final events = await repository.fetchUpcomingEvents();

    expect(events, hasLength(2));
    expect(backend.requests, hasLength(2));
    expect(backend.requests.map((request) => request.page), [1, 2]);
    for (final request in backend.requests) {
      expect(request.originLat, closeTo(userOrigin.latitude, 0.000001));
      expect(request.originLng, closeTo(userOrigin.longitude, 0.000001));
    }
  });

  test('fetchUpcomingEvents does not call unscoped fetchEvents endpoint',
      () async {
    final backend = _CapturingScheduleBackend();
    final userOrigin = _buildCoordinate(
      latitude: -20.611121,
      longitude: -40.498617,
    );
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(
        userCoordinate: userOrigin,
      ),
      appDataRepository: _FakeAppDataRepository(_buildAppData()),
    );

    await repository.fetchUpcomingEvents();

    expect(backend.fetchEventsCalls, 0);
  });

  test('getEventsPage maps events when event type description is null',
      () async {
    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439031',
              occurrenceId: '507f1f77bcf86cd799439032',
              typeDescription: null,
            ),
          ],
          hasMore: false,
        ),
      ],
    );
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(),
      appDataRepository: _FakeAppDataRepository(_buildAppData()),
    );

    final result = await repository.getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(result.events, hasLength(1));
    expect(result.events.first.type.description.value, isEmpty);
  });

  test('getEventsPage maps events when event content is null', () async {
    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439041',
              occurrenceId: '507f1f77bcf86cd799439042',
              eventContent: null,
            ),
          ],
          hasMore: false,
        ),
      ],
    );
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(),
      appDataRepository: _FakeAppDataRepository(_buildAppData()),
    );

    final result = await repository.getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(result.events, hasLength(1));
    expect(result.events.first.content.valueText, isEmpty);
  });

  test('getEventsPage maps events when type description and content are null',
      () async {
    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439051',
              occurrenceId: '507f1f77bcf86cd799439052',
              typeDescription: null,
              eventContent: null,
            ),
          ],
          hasMore: false,
        ),
      ],
    );
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(),
      appDataRepository: _FakeAppDataRepository(_buildAppData()),
    );

    final result = await repository.getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(result.events, hasLength(1));
    expect(result.events.first.type.description.value, isEmpty);
    expect(result.events.first.content.valueText, isEmpty);
  });

  test(
      'loadEventsPage ignores second first-page request while one is in-flight',
      () async {
    final backend = _BlockingFirstPageScheduleBackend();
    final repository = ScheduleRepository(
      backend: backend,
      userLocationRepository: _FakeUserLocationRepository(),
      appDataRepository: _FakeAppDataRepository(_buildAppData()),
    );

    final firstLoadFuture = repository.loadEventsPage(
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    await backend.waitUntilFirstRequestStarts();

    await repository.loadEventsPage(
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(
      backend.fetchEventsPageCalls,
      1,
      reason: 'A second first-page request must be ignored while in-flight.',
    );

    backend.releaseFirstRequest();
    await firstLoadFuture;

    expect(repository.currentPagedEventsPage.value, 1);
  });
}

class _CapturingScheduleBackend implements ScheduleBackendContract {
  _CapturingScheduleBackend({
    this.pagedResponses,
  });

  final List<EventPageDTO>? pagedResponses;
  final List<_AgendaRequestSample> requests = <_AgendaRequestSample>[];
  int fetchEventsCalls = 0;

  @override
  Future<EventSummaryDTO> fetchSummary() async =>
      EventSummaryDTO(items: const []);

  @override
  Future<List<EventDTO>> fetchEvents() async {
    fetchEventsCalls += 1;
    return const [];
  }

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
    if (pagedResponses != null) {
      final index = page - 1;
      if (index < 0 || index >= pagedResponses!.length) {
        return EventPageDTO(events: const [], hasMore: false);
      }
      return pagedResponses![index];
    }
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
  }) {
    return const Stream<EventDeltaDTO>.empty();
  }
}

class _BlockingFirstPageScheduleBackend implements ScheduleBackendContract {
  final Completer<void> _firstRequestStarted = Completer<void>();
  final Completer<void> _releaseFirstRequest = Completer<void>();
  int fetchEventsPageCalls = 0;

  Future<void> waitUntilFirstRequestStarts() => _firstRequestStarted.future;

  void releaseFirstRequest() {
    if (!_releaseFirstRequest.isCompleted) {
      _releaseFirstRequest.complete();
    }
  }

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
    fetchEventsPageCalls += 1;
    if (fetchEventsPageCalls == 1) {
      if (!_firstRequestStarted.isCompleted) {
        _firstRequestStarted.complete();
      }
      await _releaseFirstRequest.future;
    }

    return EventPageDTO(events: const [], hasMore: false);
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
  }) {
    return const Stream<EventDeltaDTO>.empty();
  }
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
    this.throwOnWarmUp = false,
  })  : userLocationStreamValue =
            StreamValue<CityCoordinate?>(defaultValue: userCoordinate),
        lastKnownLocationStreamValue =
            StreamValue<CityCoordinate?>(defaultValue: lastKnownCoordinate);

  final bool throwOnWarmUp;

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
    if (throwOnWarmUp) {
      throw Exception('warm-up failed');
    }
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
            StreamValue<DistanceInMetersValue>(defaultValue: DistanceInMetersValue.fromRaw(_appData.mapRadiusMaxMeters, defaultValue: _appData.mapRadiusMaxMeters));

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
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

AppData _buildAppData({
  CityCoordinate? defaultOrigin,
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
  String eventId = '507f1f77bcf86cd799439011',
  String occurrenceId = '507f1f77bcf86cd799439012',
  String startsAtIso = '2099-01-01T20:00:00+00:00',
  String? typeDescription = 'Show type description',
  String? eventContent = 'Conteudo do evento completo',
}) {
  return EventDTO.fromJson({
    'event_id': eventId,
    'occurrence_id': occurrenceId,
    'slug': 'evento-teste',
    'title': 'Evento Teste',
    'content': eventContent,
    'type': {
      'id': 'type-1',
      'name': 'Show',
      'slug': 'show',
      'description': typeDescription,
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
    'date_time_start': startsAtIso,
    'artists': const [],
    'tags': const ['music'],
  });
}
