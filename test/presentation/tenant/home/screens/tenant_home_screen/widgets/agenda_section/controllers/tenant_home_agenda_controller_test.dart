import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_body.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  group('TenantHomeAgendaController radius bounds', () {
    test('initializes from tenant radius default and exposes min bound',
        () async {
      final appData = _buildAppData(
        minKm: 2,
        defaultKm: 7,
        maxKm: 15,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final controller = TenantHomeAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(controller.minRadiusMeters, 2000);
      expect(controller.radiusMetersStreamValue.value, 7000);

      controller.onDispose();
    });

    test('clamps radius updates to tenant bounds and reacts to max changes',
        () async {
      final appData = _buildAppData(
        minKm: 2,
        defaultKm: 7,
        maxKm: 15,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final controller = TenantHomeAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      controller.setRadiusMeters(1000);
      expect(controller.radiusMetersStreamValue.value, 2000);

      controller.setRadiusMeters(25000);
      expect(controller.radiusMetersStreamValue.value, 15000);

      await appDataRepository.setMaxRadiusMeters(5000);
      expect(controller.radiusMetersStreamValue.value, 5000);

      controller.onDispose();
    });

    test('normalizes invalid tenant radius settings when parsing app data', () {
      final appData = _buildAppData(
        minKm: 10,
        defaultKm: 30,
        maxKm: 20,
      );

      expect(appData.mapRadiusMinMeters, 10000);
      expect(appData.mapRadiusMaxMeters, 20000);
      expect(appData.mapRadiusDefaultMeters, 20000);
    });

    test('finalizes initial loading even when first fetch fails', () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final controller = TenantHomeAgendaController(
        scheduleRepository: _FailingScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(controller.displayedEventsStreamValue.value, isEmpty);

      controller.onDispose();
    });

    test('uses tenant default origin when user location is unavailable',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..warmUpResult = false;

      final controller = TenantHomeAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(locationRepository.warmUpCalled, isTrue);
      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(scheduleRepository.lastOriginLat, closeTo(-20.671339, 0.000001));
      expect(scheduleRepository.lastOriginLng, closeTo(-40.495395, 0.000001));

      controller.onDispose();
    });

    test('uses tenant default origin when map_ui default origin is flattened',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
        flattenDefaultOrigin: true,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..warmUpResult = false;

      final controller = TenantHomeAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(scheduleRepository.lastOriginLat, closeTo(-20.671339, 0.000001));
      expect(scheduleRepository.lastOriginLng, closeTo(-40.495395, 0.000001));

      controller.onDispose();
    });

    test('does not fetch when neither user location nor tenant default exists',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
        includeDefaultOrigin: false,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..warmUpResult = false;

      final controller = TenantHomeAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 0);
      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(controller.displayedEventsStreamValue.value, isEmpty);
      expect(controller.hasMoreStreamValue.value, isFalse);

      controller.onDispose();
    });

    test(
        'renders event from canonical agenda payload when type.id is non-ObjectId',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );

      final controller = TenantHomeAgendaController(
        scheduleRepository: ScheduleRepository(
          backend: _PayloadScheduleBackend(),
        ),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(controller.displayedEventsStreamValue.value, hasLength(1));
      final event = controller.displayedEventsStreamValue.value.first;
      expect(event.type.id.value, 'type-1');
      expect(event.coordinate, isNotNull);
      expect(event.coordinate!.latitude, closeTo(-20.671339, 0.000001));
      expect(event.coordinate!.longitude, closeTo(-40.495395, 0.000001));
      expect(event.artists.single.avatarUri, isNull);

      controller.onDispose();
    });

    test('does not auto-page when current filter leaves first page empty',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );
      final backend = _AutoPageRegressionBackend();
      final controller = TenantHomeAgendaController(
        scheduleRepository: ScheduleRepository(backend: backend),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(backend.requestedPages, [1]);

      controller.setInviteFilter(InviteFilter.confirmedOnly);

      expect(controller.displayedEventsStreamValue.value, isEmpty);
      expect(backend.requestedPages, [1]);

      controller.onDispose();
    });

    testWidgets('home agenda body does not load next page on initial build',
        (tester) async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );
      final backend = _AutoPageRegressionBackend();
      final controller = TenantHomeAgendaController(
        scheduleRepository: ScheduleRepository(backend: backend),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(backend.requestedPages, [1]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeAgendaBody(controller: controller),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(backend.requestedPages, [1]);

      controller.onDispose();
    });
  });
}

AppData _buildAppData({
  required num minKm,
  required num defaultKm,
  required num maxKm,
  bool includeDefaultOrigin = true,
  bool flattenDefaultOrigin = false,
}) {
  final mapUi = <String, dynamic>{
    'radius': {
      'min_km': minKm,
      'default_km': defaultKm,
      'max_km': maxKm,
    },
  };
  if (includeDefaultOrigin) {
    if (flattenDefaultOrigin) {
      mapUi['default_origin.lat'] = -20.671339;
      mapUi['default_origin.lng'] = -40.495395;
      mapUi['default_origin.label'] = 'Praia do Morro';
    } else {
      mapUi['default_origin'] = const {
        'lat': -20.671339,
        'lng': -40.495395,
        'label': 'Praia do Morro',
      };
    }
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
          'is_poi_enabled': false,
        },
      },
    ],
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
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

  return AppData.fromInitialization(
      remoteData: remoteData, localInfo: localInfo);
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

class _FakeScheduleRepository implements ScheduleRepositoryContract {
  int getEventsPageCallCount = 0;
  double? lastOriginLat;
  double? lastOriginLng;

  @override
  Future<List<EventModel>> getAllEvents() async => const [];

  @override
  Future<EventModel?> getEventBySlug(String slug) async => null;

  @override
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async =>
      const [];

  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    lastOriginLat = originLat;
    lastOriginLng = originLng;
    return const PagedEventsResult(events: [], hasMore: false);
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    throw UnimplementedError();
  }

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date) async =>
      const [];

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async => const [];

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
}

class _FailingScheduleRepository extends _FakeScheduleRepository {
  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    throw Exception('forced first-page failure');
  }
}

class _PayloadScheduleBackend implements ScheduleBackendContract {
  @override
  Future<EventSummaryDTO> fetchSummary() async =>
      EventSummaryDTO(items: const []);

  @override
  Future<List<EventDTO>> fetchEvents() async => [
        _eventDto(),
      ];

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      _eventDto();

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
    if (page > 1) {
      return EventPageDTO(events: const [], hasMore: false);
    }

    return EventPageDTO(
      events: [_eventDto()],
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

  EventDTO _eventDto() {
    return EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439011',
      'occurrence_id': '507f1f77bcf86cd799439012',
      'slug': 'evento-teste',
      'title': 'Evento Teste',
      'content': 'Conteudo do evento',
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
      'date_time_start': '2026-03-03T20:00:00+00:00',
      'artists': const [
        {
          'id': '507f1f77bcf86cd799439013',
          'name': 'Main Artist',
          'avatar_url': null,
          'genres': ['rock'],
        },
      ],
      'tags': const ['music'],
    });
  }
}

class _AutoPageRegressionBackend implements ScheduleBackendContract {
  final List<int> requestedPages = <int>[];

  @override
  Future<EventSummaryDTO> fetchSummary() async =>
      EventSummaryDTO(items: const []);

  @override
  Future<List<EventDTO>> fetchEvents() async => [_pageOneEvent()];

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      _pageOneEvent();

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
    requestedPages.add(page);
    if (page == 1) {
      return EventPageDTO(
        events: [_pageOneEvent()],
        hasMore: true,
      );
    }

    return EventPageDTO(
      events: [_pageTwoEvent()],
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

  EventDTO _pageOneEvent() {
    return EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439111',
      'occurrence_id': '507f1f77bcf86cd799439112',
      'slug': 'pagina-um',
      'title': 'Pagina Um',
      'content': 'Conteudo',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type description',
      },
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-03T20:00:00+00:00',
      'artists': const [],
      'tags': const ['music'],
    });
  }

  EventDTO _pageTwoEvent() {
    return EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439121',
      'occurrence_id': '507f1f77bcf86cd799439122',
      'slug': 'pagina-dois',
      'title': 'Pagina Dois',
      'content': 'Conteudo',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type description',
      },
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-04T20:00:00+00:00',
      'artists': const [],
      'tags': const ['music'],
    });
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  @override
  Future<List<InviteModel>> fetchInvites(
          {int page = 1, int pageSize = 20}) async =>
      const [];

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      const InviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async =>
      InviteAcceptResult(
        inviteId: inviteId,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        closedDuplicateInviteIds: const [],
      );

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async =>
      InviteDeclineResult(
        inviteId: inviteId,
        status: 'declined',
        groupHasOtherPending: false,
      );

  @override
  Future<InviteAcceptResult> acceptShareCode(String code) async =>
      InviteAcceptResult(
        inviteId: code,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.openAppToContinue,
        closedDuplicateInviteIds: const [],
      );

  @override
  Future<List<InviteContactMatch>> importContacts(
          List<ContactModel> contacts) async =>
      const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  }) async =>
      InviteShareCodeResult(
        code: 'CODE123',
        eventId: eventId,
        occurrenceId: occurrenceId,
      );

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      String eventSlug) async {
    return const [];
  }

  @override
  Future<void> sendInvites(
    String eventSlug,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {}
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  Future<void> confirmEventAttendance(String eventId) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  bool isEventConfirmed(String eventId) => false;

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {}
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  bool warmUpCalled = false;
  bool warmUpResult = false;

  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

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
    warmUpCalled = true;
    return warmUpResult;
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
