import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/common/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/common/location_permission/screens/location_not_live_screen/location_not_live_screen.dart';
import 'package:belluga_now/presentation/common/location_permission/screens/location_permission_screen/location_permission_screen.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/event_search_screen.dart';
import 'package:belluga_now/presentation/tenant/schedule/widgets/agenda_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

import 'package:belluga_now/application/router/guards/location_permission_state.dart';
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

  testWidgets('LocationNotLiveScreen uses SafeArea', (tester) async {
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
        home: LocationNotLiveScreen(
          blockerState: LocationPermissionState.denied,
          addressLabel: null,
          capturedAt: null,
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

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: 24)),
        child: MaterialApp(
          home: EventSearchScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

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
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeAgendaSection(
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

    final agendaAppBar =
        tester.widget<AgendaAppBar>(find.byType(AgendaAppBar));
    expect(agendaAppBar.controller, same(controller));

    if (getIt.isRegistered<TenantHomeAgendaController>()) {
      getIt.unregister<TenantHomeAgendaController>();
    }
  });
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
        );

  @override
  Future<void> init({bool startWithHistory = false}) async {
    showHistoryStreamValue.addValue(startWithHistory);
    radiusMetersStreamValue.addValue(maxRadiusMetersStreamValue.value);
    isInitialLoadingStreamValue.addValue(false);
    displayedEventsStreamValue.addValue(const []);
  }
}

class FakeScheduleRepository implements ScheduleRepositoryContract {
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
        );

  bool _disposed = false;

  @override
  Future<void> init({bool startWithHistory = false}) async {
    showHistoryStreamValue.addValue(startWithHistory);
    isInitialLoadingStreamValue.addValue(false);
    hasMoreStreamValue.addValue(false);
    displayedEventsStreamValue.addValue(const []);
  }

  @override
  void onDispose() {
    // Keep idempotent in tests to avoid double-dispose during widget unmount.
    if (_disposed) return;
    _disposed = true;
  }
}

class FakeUserEventsRepository implements UserEventsRepositoryContract {
  final StreamValue<Set<String>> _confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  StreamValue<Set<String>> get confirmedEventIdsStream =>
      _confirmedEventIdsStream;

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
}

class FakeInvitesRepository extends InvitesRepositoryContract {
  @override
  Future<List<InviteModel>> fetchInvites() async => const [];

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(String eventSlug) async {
    return const [];
  }

  @override
  Future<void> sendInvites(String eventSlug, List<String> friendIds) async {}
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
  Future<bool> refreshIfPermitted({Duration minInterval = const Duration(seconds: 30)}) async =>
      false;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      false;

  @override
  Future<void> stopTracking() async {}

  @override
  Future<void> setLastKnownAddress(String? address) async {}

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
  Future<Map<String, dynamic>> getInfo() async => const {};
}