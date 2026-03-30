import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
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
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  testWidgets(
    'stream disconnect triggers deterministic page-1 rehydrate and reconnect',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final controller = EventSearchScreenController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );

      await controller.init();
      final baselineFetchCalls = scheduleRepository.getEventsPageCallCount;
      final baselineWatchCalls = scheduleRepository.watchEventsStreamCallCount;

      scheduleRepository.emitDisconnectError();
      await tester.pump();

      expect(
        scheduleRepository.getEventsPageCallCount,
        greaterThanOrEqualTo(baselineFetchCalls + 1),
      );
      expect(scheduleRepository.lastRequestedPage, 1);

      await tester.pump(const Duration(seconds: 3));

      expect(
        scheduleRepository.watchEventsStreamCallCount,
        greaterThanOrEqualTo(baselineWatchCalls + 1),
      );
      expect(scheduleRepository.lastRequestedPage, 1);

      controller.onDispose();
      scheduleRepository.dispose();
    },
  );

  testWidgets(
    'initial loading is finalized when first page fetch fails',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository()
        ..failOnPageFetch = true;
      final controller = EventSearchScreenController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );

      await controller.init();

      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(controller.displayedEventsStreamValue.value, isEmpty);

      controller.onDispose();
      scheduleRepository.dispose();
    },
  );

  testWidgets(
    'does not fetch or subscribe stream when effective origin is missing',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final controller = EventSearchScreenController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository:
            _FakeAppDataRepository(_buildAppData(includeDefaultOrigin: false)),
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 0);
      expect(scheduleRepository.watchEventsStreamCallCount, 0);
      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(controller.hasMoreStreamValue.value, isFalse);

      controller.onDispose();
      scheduleRepository.dispose();
    },
  );

  testWidgets(
    'uses tenant default origin when cached user location is stale',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-23.550520'),
            longitudeValue: LongitudeValue()..parse('-46.633308'),
          ),
        )
        ..lastKnownCapturedAtStreamValue.addValue(
          DateTime.now().subtract(const Duration(hours: 2)),
        );
      final controller = EventSearchScreenController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(scheduleRepository.lastOriginLat, closeTo(-20.671339, 0.000001));
      expect(scheduleRepository.lastOriginLng, closeTo(-40.495395, 0.000001));

      controller.onDispose();
      scheduleRepository.dispose();
    },
  );
}

AppData _buildAppData({bool includeDefaultOrigin = true}) {
  final mapUi = <String, dynamic>{
    'radius': {
      'min_km': 1,
      'default_km': 5,
      'max_km': 50,
    },
  };
  if (includeDefaultOrigin) {
    mapUi['default_origin'] = const {
      'lat': -20.671339,
      'lng': -40.495395,
      'label': 'Praia do Morro',
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

  return buildAppDataFromInitialization(
      remoteData: remoteData, localInfo: localInfo);
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

class _FakeScheduleRepository implements ScheduleRepositoryContract {
  _FakeScheduleRepository();

  @override
  final StreamValue<List<EventModel>?> homeAgendaEventsStreamValue =
      StreamValue<List<EventModel>?>();
  @override
  final StreamValue<HomeAgendaCacheSnapshot?> homeAgendaCacheStreamValue =
      StreamValue<HomeAgendaCacheSnapshot?>();
  @override
  final StreamValue<List<EventModel>> eventSearchDisplayedEventsStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const <EventModel>[]);
  @override
  final StreamValue<List<EventModel>> eventsByDateStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const <EventModel>[]);
  @override
  final StreamValue<PagedEventsResult?> pagedEventsStreamValue =
      StreamValue<PagedEventsResult?>(defaultValue: null);
  @override
  final StreamValue<ScheduleRepoBool> hasMorePagedEventsStreamValue =
      StreamValue<ScheduleRepoBool>(
    defaultValue: ScheduleRepoBool.fromRaw(
      true,
      defaultValue: true,
    ),
  );
  @override
  final StreamValue<ScheduleRepoBool> isPagedEventsPageLoadingStreamValue =
      StreamValue<ScheduleRepoBool>(
    defaultValue: ScheduleRepoBool.fromRaw(
      false,
      defaultValue: false,
    ),
  );
  @override
  final StreamValue<ScheduleRepoString?> pagedEventsErrorStreamValue =
      StreamValue<ScheduleRepoString?>(defaultValue: null);

  int getEventsPageCallCount = 0;
  int watchEventsStreamCallCount = 0;
  int? lastRequestedPage;
  ScheduleRepoInt _currentPagedEventsPage = ScheduleRepoInt.fromRaw(
    0,
    defaultValue: 0,
  );
  double? lastOriginLat;
  double? lastOriginLng;
  bool failOnPageFetch = false;

  final List<StreamController<EventDeltaModel>> _streamControllers = [];

  void emitDisconnectError() {
    if (_streamControllers.isEmpty) return;
    _streamControllers.last.addError(Exception('stream disconnected'));
  }

  void dispose() {
    for (final controller in _streamControllers) {
      controller.close();
    }
    _streamControllers.clear();
  }

  @override
  HomeAgendaCacheSnapshot? readHomeAgendaCache({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
  }) {
    final snapshot = homeAgendaCacheStreamValue.value;
    if (snapshot == null) return null;
    if (snapshot.showPastOnly != showPastOnly.value) return null;
    if (snapshot.searchQuery != searchQuery.value) return null;
    if (snapshot.confirmedOnly != confirmedOnly.value) return null;
    return snapshot;
  }

  @override
  void writeHomeAgendaCache(HomeAgendaCacheSnapshot snapshot) {
    homeAgendaCacheStreamValue.addValue(snapshot);
    homeAgendaEventsStreamValue.addValue(snapshot.events);
  }

  @override
  void clearHomeAgendaCache() {
    homeAgendaCacheStreamValue.addValue(null);
    homeAgendaEventsStreamValue.addValue(null);
  }

  @override
  ScheduleRepoInt get currentPagedEventsPage => _currentPagedEventsPage;

  @override
  Future<List<EventModel>> getAllEvents() async => const [];

  @override
  Future<EventModel?> getEventBySlug(ScheduleRepoString slug) async => null;

  @override
  Future<List<EventModel>> getEventsByDate(
    ScheduleRepoDateTime date, {
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async =>
      const [];

  @override
  Future<void> refreshEventsByDate(
    ScheduleRepoDateTime date, {
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final events = await getEventsByDate(
      date,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    eventsByDateStreamValue.addValue(events);
  }

  @override
  Future<PagedEventsResult> getEventsPage({
    required ScheduleRepoInt page,
    required ScheduleRepoInt pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    lastRequestedPage = page.value;
    lastOriginLat = originLat?.value;
    lastOriginLng = originLng?.value;
    if (failOnPageFetch) {
      throw Exception('forced first-page failure');
    }
    return pagedEventsResultFromRaw(events: [], hasMore: false);
  }

  @override
  Future<void> refreshEventsPage({
    required ScheduleRepoInt page,
    required ScheduleRepoInt pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final pageResult = await getEventsPage(
      page: page,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    _currentPagedEventsPage = page;
    hasMorePagedEventsStreamValue.addValue(
      ScheduleRepoBool.fromRaw(
        pageResult.hasMore,
        defaultValue: pageResult.hasMore,
      ),
    );
    pagedEventsStreamValue.addValue(pageResult);
  }

  @override
  Future<void> loadEventsPage({
    ScheduleRepoInt? pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    await refreshEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: pageSize ?? ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
  }

  @override
  Future<void> loadNextEventsPage({
    ScheduleRepoInt? pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    if (!hasMorePagedEventsStreamValue.value.value) {
      return;
    }
    await refreshEventsPage(
      page: ScheduleRepoInt.fromRaw(
        _currentPagedEventsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: pageSize ?? ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
  }

  @override
  void resetPagedEventsState() {
    _currentPagedEventsPage = ScheduleRepoInt.fromRaw(0, defaultValue: 0);
    pagedEventsStreamValue.addValue(null);
    hasMorePagedEventsStreamValue.addValue(
      ScheduleRepoBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );
    isPagedEventsPageLoadingStreamValue.addValue(
      ScheduleRepoBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
    pagedEventsErrorStreamValue.addValue(null);
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    throw UnimplementedError();
  }

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(
          ScheduleRepoDateTime date) async =>
      const <VenueEventResume>[];

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async =>
      const <VenueEventResume>[];

  @override
  Stream<EventDeltaModel> watchEventsStream({
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    watchEventsStreamCallCount += 1;
    lastOriginLat = originLat?.value;
    lastOriginLng = originLng?.value;
    final controller = StreamController<EventDeltaModel>.broadcast();
    _streamControllers.add(controller);
    return controller.stream;
  }

  @override
  Stream<void> watchEventsSignal({
    required ScheduleRepositoryContractDeltaHandler onDelta,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
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
    ).map((delta) {
      onDelta(delta);
    });
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  @override
  Future<List<InviteModel>> fetchInvites(
          {InvitesRepositoryContractPrimInt? page,
          InvitesRepositoryContractPrimInt? pageSize}) async =>
      const [];

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(
          InvitesRepositoryContractPrimString inviteId) async =>
      buildInviteAcceptResult(
        inviteId: inviteId.value,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteDeclineResult> declineInvite(
          InvitesRepositoryContractPrimString inviteId) async =>
      buildInviteDeclineResult(
        inviteId: inviteId.value,
        status: 'declined',
        groupHasOtherPending: false,
      );
  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts) async =>
      const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async =>
      buildInviteShareCodeResult(
        code: 'CODE123',
        eventId: eventId.value,
        occurrenceId: occurrenceId?.value,
      );

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      InvitesRepositoryContractPrimString eventSlug) async {
    return const [];
  }

  @override
  Future<void> sendInvites(InvitesRepositoryContractPrimString eventSlug,
      InviteRecipients recipients,
      {InvitesRepositoryContractPrimString? occurrenceId,
      InvitesRepositoryContractPrimString? message}) async {}
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
          defaultValue: const {});

  @override
  Future<void> confirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
          UserEventsRepositoryContractPrimString eventId) =>
      userEventsRepoBool(false, defaultValue: false, isRequired: true);

  @override
  Future<void> unconfirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {}
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
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
  Future<bool> warmUpIfPermitted() async => false;

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
