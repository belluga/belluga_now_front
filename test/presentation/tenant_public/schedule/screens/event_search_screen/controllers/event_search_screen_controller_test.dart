import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
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
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/event_search_screen.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets(
    'stream disconnect triggers deterministic page-1 rehydrate and reconnect',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final controller = _buildEventSearchController(
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
      final controller = _buildEventSearchController(
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
      final controller = _buildEventSearchController(
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
      final controller = _buildEventSearchController(
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

  testWidgets(
    'agenda system back falls back to profile when no history exists',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final controller = _buildEventSearchController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );
      GetIt.I.registerSingleton<EventSearchScreenController>(controller);
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpEventSearchScreen(tester,
          controller: controller, router: router);

      final popScope = tester.widget<PopScope<dynamic>>(
        find.byWidgetPredicate((widget) => widget is PopScope),
      );
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pumpAndSettle();

      expect(router.canPopCallCount, 1);
      expect(router.popCallCount, 0);
      expect(router.replaceAllRoutes, hasLength(1));
      expect(
          router.replaceAllRoutes.single.single.routeName, ProfileRoute.name);
    },
  );

  testWidgets(
    'agenda header back matches profile fallback when no history exists',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final controller = _buildEventSearchController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );
      GetIt.I.registerSingleton<EventSearchScreenController>(controller);
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpEventSearchScreen(tester,
          controller: controller, router: router);

      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();

      expect(router.canPopCallCount, 1);
      expect(router.popCallCount, 0);
      expect(router.replaceAllRoutes, hasLength(1));
      expect(
          router.replaceAllRoutes.single.single.routeName, ProfileRoute.name);
    },
  );

  testWidgets(
    'agenda header back returns to previous route when history exists',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final controller = _buildEventSearchController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );
      GetIt.I.registerSingleton<EventSearchScreenController>(controller);
      final router = _RecordingStackRouter()..canPopResult = true;

      await _pumpEventSearchScreen(tester,
          controller: controller, router: router);

      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();

      expect(router.canPopCallCount, 1);
      expect(router.popCallCount, 1);
      expect(router.replaceAllRoutes, isEmpty);
    },
  );

  testWidgets(
    'logs radius change telemetry only when the effective agenda radius changes',
    (tester) async {
      final telemetryRepository = _FakeTelemetryRepository();
      final controller = _buildEventSearchController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
        telemetryRepository: telemetryRepository,
      );

      await controller.init();

      expect(telemetryRepository.events, isEmpty);

      controller.setRadiusMeters(7000);
      await tester.pump();

      expect(telemetryRepository.events, hasLength(1));
      expect(telemetryRepository.events.single.event,
          EventTrackerEvents.selectItem);
      expect(
          telemetryRepository.events.single.eventName, 'agenda_radius_changed');
      expect(telemetryRepository.events.single.properties, <String, dynamic>{
        'surface': 'agenda',
        'previous_radius_meters': 5000,
        'selected_radius_meters': 7000,
      });

      controller.setRadiusMeters(7000);
      await tester.pump();

      expect(
        telemetryRepository.events,
        hasLength(1),
        reason: 'No-op re-selection must not emit a second tracking event.',
      );

      controller.onDispose();
    },
  );

  testWidgets(
    'radius action compacts on first scroll movement and expands again at top',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository()
        ..eventSearchPages = [
          List<EventModel>.generate(
            12,
            (index) => _buildScheduleEvent(
              id: '507f1f77bcf86cd7994390${(10 + index).toString().padLeft(2, '0')}',
              title: 'Evento $index',
              slug: 'evento-$index',
              startAt: DateTime.utc(2026, 4, 15 + (index ~/ 3), 18, 0),
            ),
          ),
        ];
      final controller = _buildEventSearchController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );
      GetIt.I.registerSingleton<EventSearchScreenController>(controller);
      final router = _RecordingStackRouter();

      await _pumpEventSearchScreen(
        tester,
        controller: controller,
        router: router,
      );

      expect(controller.isRadiusActionCompactStreamValue.value, isFalse);

      controller.scrollController.jumpTo(1);
      await tester.pump();

      expect(controller.isRadiusActionCompactStreamValue.value, isTrue);

      controller.scrollController.jumpTo(0);
      await tester.pump();

      expect(controller.isRadiusActionCompactStreamValue.value, isFalse);
    },
  );

  testWidgets(
    'radius compact state syncs from existing scroll offset after listener attaches',
    (tester) async {
      final controller = _buildEventSearchController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );

      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller.scrollController,
              itemCount: 40,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 72,
                  child: Text('row $index'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.scrollController.jumpTo(80);
      await tester.pump();

      expect(controller.isRadiusActionCompactStreamValue.value, isFalse);

      await controller.init();
      await tester.pump();
      await tester.pump();

      expect(controller.isRadiusActionCompactStreamValue.value, isTrue);
    },
  );
}

Future<void> _pumpEventSearchScreen(
  WidgetTester tester, {
  required EventSearchScreenController controller,
  required _RecordingStackRouter router,
}) async {
  final routeData = RouteData(
    route: _FakeRouteMatch(
      name: EventSearchRoute.name,
      fullPath: '/agenda',
      meta: canonicalRouteMeta(
        family: CanonicalRouteFamily.eventSearch,
      ),
    ),
    router: router,
    stackKey: const ValueKey('stack'),
    pendingChildren: const [],
    type: const RouteType.material(),
  );

  await tester.pumpWidget(
    StackRouterScope(
      controller: router,
      stateHash: 0,
      child: MaterialApp(
        home: RouteDataScope(
          routeData: routeData,
          child: const EventSearchScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

EventSearchScreenController _buildEventSearchController({
  required ScheduleRepositoryContract scheduleRepository,
  required UserEventsRepositoryContract userEventsRepository,
  required InvitesRepositoryContract invitesRepository,
  required UserLocationRepositoryContract? userLocationRepository,
  required AppDataRepositoryContract appDataRepository,
  TelemetryRepositoryContract? telemetryRepository,
}) {
  return EventSearchScreenController(
    scheduleRepository: scheduleRepository,
    userEventsRepository: userEventsRepository,
    invitesRepository: invitesRepository,
    userLocationRepository: userLocationRepository,
    appDataRepository: appDataRepository,
    telemetryRepository: telemetryRepository,
    locationOriginService: LocationOriginService(
      appDataRepository: appDataRepository,
      userLocationRepository: userLocationRepository,
    ),
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

class _RecordingStackRouter extends Fake implements StackRouter {
  bool canPopResult = false;
  int canPopCallCount = 0;
  int popCallCount = 0;
  final List<List<PageRouteInfo<dynamic>>> replaceAllRoutes = [];

  @override
  RootStackRouter get root => _FakeRootStackRouter('/agenda');

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    canPopCallCount += 1;
    return canPopResult;
  }

  @override
  Future<bool> pop<T extends Object?>([T? result]) async {
    popCallCount += 1;
    return canPopResult;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo<dynamic>> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllRoutes.add(List<PageRouteInfo<dynamic>>.from(routes));
  }
}

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  _FakeRootStackRouter(this.currentPath);

  @override
  final String currentPath;

  @override
  Object? get pathState => null;

  @override
  RootStackRouter get root => this;
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.name,
    required this.fullPath,
    required this.meta,
    PageRouteInfo<dynamic>? pageRouteInfo,
    Map<String, dynamic> queryParams = const {},
  })  : pageRouteInfo = pageRouteInfo ?? EventSearchRoute(),
        _queryParams = Parameters(queryParams);

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  final PageRouteInfo<dynamic> pageRouteInfo;

  final Parameters _queryParams;

  @override
  Parameters get queryParams => _queryParams;

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => pageRouteInfo;
}

class _LoggedEvent {
  _LoggedEvent({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  final List<_LoggedEvent> events = [];

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    events.add(
      _LoggedEvent(
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
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      null;

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData)
      : maxRadiusMetersStreamValue = StreamValue<DistanceInMetersValue>(
            defaultValue: DistanceInMetersValue.fromRaw(
                _appData.mapRadiusMaxMeters,
                defaultValue: _appData.mapRadiusMaxMeters));

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

class _FakeScheduleRepository implements ScheduleRepositoryContract {
  _FakeScheduleRepository();

  @override
  final StreamValue<List<EventModel>?> homeAgendaStreamValue =
      StreamValue<List<EventModel>?>();
  @override
  final StreamValue<List<EventModel>?> discoveryLiveNowEventsStreamValue =
      StreamValue<List<EventModel>?>(defaultValue: null);

  int getEventsPageCallCount = 0;
  int watchEventsStreamCallCount = 0;
  int? lastRequestedPage;
  double? lastOriginLat;
  double? lastOriginLng;
  bool failOnPageFetch = false;
  List<List<EventModel>> eventSearchPages = const <List<EventModel>>[];

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
  List<EventModel>? readHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    List<ScheduleRepoString>? categories,
    ScheduleRepoTaxonomyEntries? taxonomy,
  }) {
    return homeAgendaStreamValue.value;
  }

  void writeHomeAgendaCache(List<EventModel> events) {
    homeAgendaStreamValue.addValue(List<EventModel>.unmodifiable(events));
  }

  void clearHomeAgendaCache() {
    homeAgendaStreamValue.addValue(null);
  }

  @override
  Future<List<EventModel>> loadHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    List<ScheduleRepoString>? categories,
    ScheduleRepoTaxonomyEntries? taxonomy,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<EventModel>> loadMoreHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    List<ScheduleRepoString>? categories,
    ScheduleRepoTaxonomyEntries? taxonomy,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EventModel?> getEventBySlug(
    ScheduleRepoString slug, {
    ScheduleRepoString? occurrenceId,
  }) async =>
      null;

  Future<List<EventModel>> _fetchPage({
    required int page,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    lastRequestedPage = page;
    lastOriginLat = originLat?.value;
    lastOriginLng = originLng?.value;
    if (failOnPageFetch) {
      throw Exception('forced first-page failure');
    }
    final pageIndex = page - 1;
    if (pageIndex < 0 || pageIndex >= eventSearchPages.length) {
      return const <EventModel>[];
    }
    return eventSearchPages[pageIndex];
  }

  @override
  Future<List<EventModel>> loadEventSearch({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async =>
      _fetchPage(
        page: 1,
        showPastOnly: showPastOnly,
        searchQuery: searchQuery,
        confirmedOnly: confirmedOnly,
        originLat: originLat,
        originLng: originLng,
        maxDistanceMeters: maxDistanceMeters,
      );

  @override
  Future<List<EventModel>> loadMoreEventSearch({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async =>
      _fetchPage(
        page: (lastRequestedPage ?? 0) + 1,
        showPastOnly: showPastOnly,
        searchQuery: searchQuery,
        confirmedOnly: confirmedOnly,
        originLat: originLat,
        originLng: originLng,
        maxDistanceMeters: maxDistanceMeters,
      );

  @override
  Future<List<EventModel>> loadConfirmedEvents({
    required ScheduleRepoBool showPastOnly,
  }) async =>
      const <EventModel>[];

  @override
  Future<void> refreshDiscoveryLiveNowEvents({
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final events = await _fetchPage(
      page: 1,
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      liveNowOnly: ScheduleRepoBool.fromRaw(true, defaultValue: true),
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    discoveryLiveNowEventsStreamValue.addValue(events);
  }

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

EventModel _buildScheduleEvent({
  required String id,
  required String title,
  required String slug,
  required DateTime startAt,
}) {
  return eventModelFromRaw(
    id: MongoIDValue()..parse(id),
    slugValue: SlugValue()..parse(slug),
    type: EventTypeModel(
      id: EventTypeIdValue()..parse('concert'),
      name: TitleValue(minLenght: 1)..parse('Show'),
      slug: SlugValue()..parse('show'),
      description: DescriptionValue(minLenght: 1)..parse('Show'),
      icon: SlugValue()..parse('music'),
      color: ColorValue(defaultValue: const Color(0xFF1D3557))
        ..parse('#1D3557'),
    ),
    title: TitleValue(minLenght: 1)..parse(title),
    content: HTMLContentValue()..parse('<p>$title</p>'),
    location: DescriptionValue(minLenght: 1)..parse('Praia do Morro'),
    venue: null,
    thumb: ThumbModel(
      thumbUri: ThumbUriValue(
        defaultValue: Uri.parse('https://cdn.test/$slug.jpg'),
      )..parse('https://cdn.test/$slug.jpg'),
      thumbType: ThumbTypeValue(defaultValue: ThumbTypes.image)
        ..parse(ThumbTypes.image.name),
    ),
    dateTimeStart: DateTimeValue()..parse(startAt.toIso8601String()),
    dateTimeEnd: null,
    artists: const [],
    coordinate: null,
    tags: const <String>[],
    isConfirmedValue: EventIsConfirmedValue()..parse('false'),
    totalConfirmedValue: EventTotalConfirmedValue()..parse('0'),
  );
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
  Future<InviteAcceptResult> acceptInviteByCode(
          InvitesRepositoryContractPrimString code) async =>
      buildInviteAcceptResult(
        inviteId: 'mock-${code.value}',
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
        occurrenceId: occurrenceId?.value ?? 'occurrence-1',
      );

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
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
      confirmedOccurrenceIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
          defaultValue: const {});

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isOccurrenceConfirmed(
          UserEventsRepositoryContractPrimString eventId) =>
      userEventsRepoBool(false, defaultValue: false, isRequired: true);

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {}

  @override
  Future<void> refreshConfirmedOccurrenceIds() async {}
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
