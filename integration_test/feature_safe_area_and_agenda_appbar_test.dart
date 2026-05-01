import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/shared/location_permission/screens/location_permission_screen/location_permission_screen.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section_view.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/models/tenant_home_agenda_display_state.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/event_search_screen.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/widgets/agenda_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'support/fake_schedule_repository.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  testWidgets('LocationPermissionScreen uses SafeArea', (tester) async {
    final getIt = GetIt.I;
    if (getIt.isRegistered<LocationPermissionController>()) {
      getIt.unregister<LocationPermissionController>();
    }
    final controller = LocationPermissionController();
    getIt.registerSingleton<LocationPermissionController>(controller);
    addTearDown(() {
      if (getIt.isRegistered<LocationPermissionController>()) {
        getIt.unregister<LocationPermissionController>();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.body, isA<SafeArea>());
  });

  testWidgets('LocationPermissionScreen keeps SafeArea in live-only mode',
      (tester) async {
    final getIt = GetIt.I;
    if (getIt.isRegistered<LocationPermissionController>()) {
      getIt.unregister<LocationPermissionController>();
    }
    final controller = LocationPermissionController();
    getIt.registerSingleton<LocationPermissionController>(controller);
    addTearDown(() {
      if (getIt.isRegistered<LocationPermissionController>()) {
        getIt.unregister<LocationPermissionController>();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LocationPermissionScreen(
          initialState: LocationPermissionState.denied,
          allowContinueWithoutLocation: false,
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.body, isA<SafeArea>());
  });

  testWidgets('EventSearchScreen app bar respects status bar padding',
      (tester) async {
    final getIt = GetIt.I;
    if (getIt.isRegistered<EventSearchScreenController>()) {
      getIt.unregister<EventSearchScreenController>();
    }
    getIt.registerSingleton<EventSearchScreenController>(
      FakeEventSearchScreenController(
        scheduleRepository: FakeScheduleRepository(),
        userEventsRepository: FakeUserEventsRepository(),
        invitesRepository: FakeInvitesRepository(),
        userLocationRepository: FakeUserLocationRepository(),
        appDataRepository: AppDataRepository(
          backend: FakeAppDataBackend(),
          localInfoSource: FakeAppDataLocalInfoSource(),
        ),
      ),
    );
    addTearDown(() {
      if (getIt.isRegistered<EventSearchScreenController>()) {
        getIt.unregister<EventSearchScreenController>(
          disposingFunction: (controller) => controller.onDispose(),
        );
      }
    });

    await _pumpEventSearchScreen(tester);

    await _pumpUntilFound(
      tester,
      find.byType(PreferredSize),
    );

    final preferred =
        tester.widget<PreferredSize>(find.byType(PreferredSize).first);
    expect(preferred.preferredSize.height, kToolbarHeight + 24);
  });

  testWidgets('Home agenda filters share the same controller', (tester) async {
    final getIt = GetIt.I;
    if (getIt.isRegistered<TenantHomeAgendaController>()) {
      getIt.unregister<TenantHomeAgendaController>();
    }

    final controller = FakeTenantHomeAgendaController(
      scheduleRepository: FakeScheduleRepository(),
      userEventsRepository: FakeUserEventsRepository(),
      invitesRepository: FakeInvitesRepository(),
      userLocationRepository: FakeUserLocationRepository(),
      appDataRepository: AppDataRepository(
        backend: FakeAppDataBackend(),
        localInfoSource: FakeAppDataLocalInfoSource(),
      ),
    );
    getIt.registerSingleton<TenantHomeAgendaController>(controller);
    addTearDown(() {
      if (getIt.isRegistered<TenantHomeAgendaController>()) {
        getIt.unregister<TenantHomeAgendaController>(
          disposingFunction: (value) => value.onDispose(),
        );
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeAgendaSectionView(
            controller: controller,
            builder: (context, slots) {
              return CustomScrollView(
                slivers: [
                  slots.header,
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();

    final agendaAppBar = tester.widget<AgendaAppBar>(find.byType(AgendaAppBar));
    expect(agendaAppBar.controller, same(controller));
  });
}

Future<void> _pumpEventSearchScreen(WidgetTester tester) async {
  final router = _RecordingStackRouter();
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
    MediaQuery(
      data: const MediaQueryData(padding: EdgeInsets.only(top: 24)),
      child: StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: const EventSearchScreen(),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure(
    'Timed out waiting for ${finder.describeMatch(Plurality.many)}.',
  );
}

class _RecordingStackRouter extends Fake implements StackRouter {
  @override
  RootStackRouter get root => _FakeRootStackRouter('/agenda');

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    return false;
  }

  @override
  Future<bool> pop<T extends Object?>([T? result]) async => false;

  @override
  Future<void> replaceAll(
    List<PageRouteInfo<dynamic>> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {}
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
  }) : pageRouteInfo = pageRouteInfo ?? EventSearchRoute();

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  final PageRouteInfo<dynamic> pageRouteInfo;

  @override
  Parameters get queryParams => const Parameters({});

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => pageRouteInfo;
}

class FakeEventSearchScreenController extends EventSearchScreenController {
  FakeEventSearchScreenController({
    required ScheduleRepositoryContract scheduleRepository,
    required UserEventsRepositoryContract userEventsRepository,
    required InvitesRepositoryContract invitesRepository,
    required UserLocationRepositoryContract userLocationRepository,
    required AppDataRepository appDataRepository,
  }) : super(
          scheduleRepository: scheduleRepository,
          userEventsRepository: userEventsRepository,
          invitesRepository: invitesRepository,
          userLocationRepository: userLocationRepository,
          appDataRepository: appDataRepository,
          locationOriginService: LocationOriginService(
            appDataRepository: appDataRepository,
            userLocationRepository: userLocationRepository,
          ),
        );

  @override
  Future<void> init({bool startWithHistory = false}) async {
    showHistoryStreamValue.addValue(startWithHistory);
    radiusMetersStreamValue.addValue(maxRadiusMetersStreamValue.value);
    isInitialLoadingStreamValue.addValue(false);
    displayedEventsStreamValue.addValue(const []);
  }

  @override
  void setInviteFilter(InviteFilter filter) {
    inviteFilterStreamValue.addValue(filter);
  }
}

class FakeScheduleRepository extends IntegrationTestScheduleRepositoryFake {
  @override
  Stream<EventDeltaModel> watchEventsStream({
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    List<ScheduleRepoString>? occurrenceIds,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    // Keep the stream open in tests; a closed stream triggers reconnect loops.
    return Stream<EventDeltaModel>.multi((_) {});
  }
}

class FakeTenantHomeAgendaController extends TenantHomeAgendaController {
  FakeTenantHomeAgendaController({
    required ScheduleRepositoryContract scheduleRepository,
    required UserEventsRepositoryContract userEventsRepository,
    required InvitesRepositoryContract invitesRepository,
    required UserLocationRepositoryContract userLocationRepository,
    required AppDataRepository appDataRepository,
  }) : super(
          scheduleRepository: scheduleRepository,
          userEventsRepository: userEventsRepository,
          invitesRepository: invitesRepository,
          userLocationRepository: userLocationRepository,
          appDataRepository: appDataRepository,
          locationOriginService: LocationOriginService(
            appDataRepository: appDataRepository,
            userLocationRepository: userLocationRepository,
          ),
        );

  bool _disposed = false;

  @override
  Future<void> init({bool startWithHistory = false}) async {
    showHistoryStreamValue.addValue(startWithHistory);
    isInitialLoadingStreamValue.addValue(false);
    hasMoreStreamValue.addValue(false);
    displayStateStreamValue.addValue(
      TenantHomeAgendaDisplayState(events: []),
    );
  }

  @override
  void setInviteFilter(InviteFilter filter) {
    inviteFilterStreamValue.addValue(filter);
  }

  @override
  void onDispose() {
    // Keep idempotent in tests to avoid double-dispose during widget unmount.
    if (_disposed) return;
    _disposed = true;
  }
}

class FakeUserEventsRepository implements UserEventsRepositoryContract {
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      _confirmedOccurrenceIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
          defaultValue: const {});

  @override
  StreamValue<Set<UserEventsRepositoryContractPrimString>>
      get confirmedOccurrenceIdsStream => _confirmedOccurrenceIdsStream;

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

class FakeInvitesRepository extends InvitesRepositoryContract {
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
    InviteContacts contacts,
  ) async =>
      const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async =>
      buildInviteShareCodeResult(
        code: 'test-share-code',
        eventId: eventId.value,
        occurrenceId: occurrenceId?.value ?? 'occurrence-1',
      );

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
      InvitesRepositoryContractPrimString eventSlug) async {
    return [];
  }

  @override
  Future<void> sendInvites(InvitesRepositoryContractPrimString eventSlug,
      InviteRecipients recipients,
      {InvitesRepositoryContractPrimString? occurrenceId,
      InvitesRepositoryContractPrimString? message}) async {}
}

class FakeUserLocationRepository implements UserLocationRepositoryContract {
  final StreamValue<CityCoordinate?> _userLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);
  final StreamValue<CityCoordinate?> _lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);
  final StreamValue<DateTime?> _lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>(defaultValue: null);
  final StreamValue<double?> _lastKnownAccuracyStreamValue =
      StreamValue<double?>(defaultValue: null);
  final StreamValue<String?> _lastKnownAddressStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
          defaultValue: LocationResolutionPhase.unknown);

  @override
  StreamValue<String?> get lastKnownAddressStreamValue =>
      _lastKnownAddressStreamValue;

  @override
  StreamValue<DateTime?> get lastKnownCapturedAtStreamValue =>
      _lastKnownCapturedAtStreamValue;

  @override
  StreamValue<double?> get lastKnownAccuracyStreamValue =>
      _lastKnownAccuracyStreamValue;

  @override
  StreamValue<CityCoordinate?> get lastKnownLocationStreamValue =>
      _lastKnownLocationStreamValue;

  @override
  StreamValue<CityCoordinate?> get userLocationStreamValue =>
      _userLocationStreamValue;

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> refreshIfPermitted({Object? minInterval}) async => false;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      false;

  @override
  Future<void> stopTracking() async {}

  @override
  Future<void> setLastKnownAddress(Object? address) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;
}

class FakeAppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() async {
    return AppDataDTO(
      name: 'Test',
      type: 'test',
      mainDomain: 'example.com',
      themeDataSettings: const {},
    );
  }
}

class FakeAppDataLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<AppDataLocalInfoDTO> getInfo() async => AppDataLocalInfoDTO(
        platformTypeValue: PlatformTypeValue(defaultValue: AppType.mobile),
        port: null,
        hostname: '',
        href: '',
        device: '',
      );
}
