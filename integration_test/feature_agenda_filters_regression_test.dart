import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';
import 'dart:io';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

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
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section_view.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/models/tenant_home_agenda_display_state.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/event_search_screen.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'support/fake_schedule_repository.dart';
import 'support/integration_test_bootstrap.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('Home agenda filters (invites, confirmed) hide text search',
      (tester) async {
    debugPrint('Home agenda test: start');
    final harness = _AgendaFiltersHarness();
    await harness.register();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeAgendaSectionView(
            controller: harness.homeController,
            builder: (context, slots) {
              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  slots.header,
                ],
                body: slots.body,
              );
            },
          ),
        ),
      ),
    );

    await _pumpFor(tester);
    debugPrint('Home agenda test: widget pumped');
    await _waitForDisplayedHomeEvents(
      tester,
      harness.homeController.displayStateStreamValue,
    );

    final controller = harness.homeController;
    expect(controller.displayedEvents, isNotEmpty);
    debugPrint('Home agenda test: initial events ready');

    debugPrint('Home agenda test: set invite filter');
    controller.setInviteFilter(InviteFilter.invitesAndConfirmed);
    debugPrint('Home agenda test: pump after invite filter');
    await _pumpFor(tester);
    debugPrint('Home agenda test: pump done');
    _expectOnlyInviteFiltered(
      controller.displayedEvents!,
      harness.pendingInviteEventId,
      const {},
    );
    expect(
      controller.pendingInviteCount(harness.pendingInviteEventId),
      1,
    );
    expect(controller.isEventConfirmed(harness.pendingInviteEventId), isFalse);
    debugPrint('Home agenda test: invite filter checked');

    harness.invitesRepository.acceptInvite(
      invitesRepoString(
        harness.pendingInviteEventId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    await _pumpFor(tester);
    controller.setInviteFilter(InviteFilter.confirmedOnly);
    await _pumpFor(tester);
    _expectOnlyInviteFiltered(
      controller.displayedEvents!,
      '',
      {harness.pendingInviteEventId},
    );
    expect(
      controller.pendingInviteCount(harness.pendingInviteEventId),
      0,
    );
    expect(controller.isEventConfirmed(harness.pendingInviteEventId), isTrue);
    debugPrint('Home agenda test: confirmed filter checked');

    controller.setInviteFilter(InviteFilter.none);
    await _pumpFor(tester);
    expect(find.byTooltip('Buscar eventos'), findsNothing);
    expect(find.byKey(const ValueKey('searchField')), findsNothing);
    debugPrint('Home agenda test: search affordance hidden');

    harness.dispose();
    debugPrint('Home agenda test: done');
  });

  testWidgets(
      'Agenda screen filters (past, invites, confirmed) hide text search',
      (tester) async {
    debugPrint('Agenda screen test: start');
    final harness = _AgendaFiltersHarness();
    await harness.register(forAgendaScreen: true);

    await tester.pumpWidget(
      MaterialApp(
        home: EventSearchScreen(),
      ),
    );

    await _pumpFor(tester);
    debugPrint('Agenda screen test: widget pumped');
    await _waitForDisplayedEvents(
      tester,
      harness.agendaController.displayedEventsStreamValue,
    );

    final controller = harness.agendaController;
    expect(controller.displayedEventsStreamValue.value, isNotEmpty);
    debugPrint('Agenda screen test: initial events ready');

    controller.toggleHistory();
    await _pumpFor(tester);
    for (final event in controller.displayedEventsStreamValue.value) {
      expect(
        event.startDateTime.isBefore(DateTime.now()),
        isTrue,
      );
    }
    debugPrint('Agenda screen test: past filter checked');

    controller.toggleHistory();
    await _pumpFor(tester);

    controller.setInviteFilter(InviteFilter.invitesAndConfirmed);
    await _pumpFor(tester);
    _expectOnlyInviteFiltered(
      controller.displayedEventsStreamValue.value,
      harness.pendingInviteEventId,
      const {},
    );
    expect(
      controller.pendingInviteCount(harness.pendingInviteEventId),
      1,
    );
    expect(controller.isEventConfirmed(harness.pendingInviteEventId), isFalse);
    debugPrint('Agenda screen test: invite filter checked');

    harness.invitesRepository.acceptInvite(
      invitesRepoString(
        harness.pendingInviteEventId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    await _pumpFor(tester);
    controller.setInviteFilter(InviteFilter.confirmedOnly);
    await _pumpFor(tester);
    _expectOnlyInviteFiltered(
      controller.displayedEventsStreamValue.value,
      '',
      {harness.pendingInviteEventId},
    );
    expect(
      controller.pendingInviteCount(harness.pendingInviteEventId),
      0,
    );
    expect(controller.isEventConfirmed(harness.pendingInviteEventId), isTrue);
    debugPrint('Agenda screen test: confirmed filter checked');

    controller.setInviteFilter(InviteFilter.none);
    await _pumpFor(tester);
    expect(find.byTooltip('Buscar eventos'), findsNothing);
    expect(find.byKey(const ValueKey('searchField')), findsNothing);
    debugPrint('Agenda screen test: search affordance hidden');

    harness.dispose();
    debugPrint('Agenda screen test: done');
  });
}

void _expectOnlyInviteFiltered(
  Iterable<Object> events,
  String pendingEventId,
  Set<String> confirmedEventIds,
) {
  expect(events, isNotEmpty);
  for (final event in events) {
    final id = _eventId(event);
    final isPending = id == pendingEventId;
    final isConfirmed = confirmedEventIds.contains(id);
    expect(isPending || isConfirmed, isTrue);
  }
}

String _eventId(Object event) {
  return switch (event) {
    EventModel() => event.id.value,
    VenueEventResume() => event.id,
    _ => throw StateError('Unsupported event type: ${event.runtimeType}'),
  };
}

class _AgendaFiltersHarness {
  _AgendaFiltersHarness()
      : pendingInviteEventId = _pendingInviteEventId,
        scheduleRepository = _TestScheduleRepository(_buildEvents()),
        userEventsRepository = _TestUserEventsRepository(),
        invitesRepository = _TestInvitesRepository(_buildInvites()),
        userLocationRepository = _TestUserLocationRepository(),
        appDataRepository = AppDataRepository(
          backend: _TestAppDataBackend(),
          localInfoSource: _TestAppDataLocalInfoSource(),
        );

  static final String _pendingInviteEventId = _mongoIdForSeed('event-invite');
  final String pendingInviteEventId;
  final _TestScheduleRepository scheduleRepository;
  final _TestUserEventsRepository userEventsRepository;
  final _TestInvitesRepository invitesRepository;
  final _TestUserLocationRepository userLocationRepository;
  final AppDataRepository appDataRepository;

  late final TenantHomeAgendaController homeController;
  late final EventSearchScreenController agendaController;

  Future<void> register({bool forAgendaScreen = false}) async {
    final getIt = GetIt.I;
    _unregisterIfRegistered<ScheduleRepositoryContract>();
    _unregisterIfRegistered<UserEventsRepositoryContract>();
    _unregisterIfRegistered<InvitesRepositoryContract>();
    _unregisterIfRegistered<UserLocationRepositoryContract>();
    _unregisterIfRegistered<AppDataRepository>();
    _unregisterIfRegistered<TenantHomeAgendaController>();
    _unregisterIfRegistered<EventSearchScreenController>();

    getIt.registerSingleton<ScheduleRepositoryContract>(scheduleRepository);
    getIt.registerSingleton<UserEventsRepositoryContract>(userEventsRepository);
    getIt.registerSingleton<InvitesRepositoryContract>(invitesRepository);
    getIt.registerSingleton<UserLocationRepositoryContract>(
      userLocationRepository,
    );
    getIt.registerSingleton<AppDataRepository>(appDataRepository);
    await appDataRepository.init();

    final locationOriginService = LocationOriginService(
      appDataRepository: appDataRepository,
      userLocationRepository: userLocationRepository,
    );

    homeController = _TestTenantHomeAgendaController(
      scheduleRepository: scheduleRepository,
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      userLocationRepository: userLocationRepository,
      appDataRepository: appDataRepository,
      locationOriginService: locationOriginService,
    );
    getIt.registerSingleton<TenantHomeAgendaController>(homeController);

    agendaController = _TestEventSearchScreenController(
      scheduleRepository: scheduleRepository,
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      userLocationRepository: userLocationRepository,
      appDataRepository: appDataRepository,
      locationOriginService: locationOriginService,
    );
    if (forAgendaScreen) {
      getIt.registerSingleton<EventSearchScreenController>(agendaController);
    }
  }

  void dispose() {
    _unregisterIfRegistered<EventSearchScreenController>();
    _unregisterIfRegistered<TenantHomeAgendaController>();
    _unregisterIfRegistered<AppDataRepository>();
    _unregisterIfRegistered<UserLocationRepositoryContract>();
    _unregisterIfRegistered<InvitesRepositoryContract>();
    _unregisterIfRegistered<UserEventsRepositoryContract>();
    _unregisterIfRegistered<ScheduleRepositoryContract>();
  }

  void _unregisterIfRegistered<T extends Object>() {
    final getIt = GetIt.I;
    if (getIt.isRegistered<T>()) {
      getIt.unregister<T>();
    }
  }
}

class _TestScheduleRepository extends IntegrationTestScheduleRepositoryFake {
  _TestScheduleRepository(List<EventModel> events)
      : super(
          seededEvents: events,
          queryResolver: ({
            required List<EventModel> seededEvents,
            required bool showPastOnly,
            required bool liveNowOnly,
            String? searchQuery,
            required bool confirmedOnly,
            double? originLat,
            double? originLng,
            double? maxDistanceMeters,
          }) {
            final now = DateTime.now();
            final filtered = seededEvents.where((event) {
              final start = event.dateTimeStart.value!;
              final isPast = start.isBefore(now);
              return showPastOnly == isPast;
            }).toList(growable: false);
            return List<EventModel>.unmodifiable(filtered);
          },
        );
}

class _TestUserEventsRepository implements UserEventsRepositoryContract {
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      _confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
          defaultValue: const {});

  @override
  StreamValue<Set<UserEventsRepositoryContractPrimString>>
      get confirmedEventIdsStream => _confirmedEventIdsStream;

  @override
  Future<void> confirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {
    final updated = {..._confirmedEventIdsStream.value, eventId};
    _confirmedEventIdsStream.addValue(updated);
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
          UserEventsRepositoryContractPrimString eventId) =>
      userEventsRepoBool(
        _confirmedEventIdsStream.value.contains(eventId),
        defaultValue: false,
        isRequired: true,
      );

  @override
  Future<void> unconfirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {
    final updated = {..._confirmedEventIdsStream.value}..remove(eventId);
    _confirmedEventIdsStream.addValue(updated);
  }

  @override
  Future<void> refreshConfirmedEventIds() async {}
}

class _TestInvitesRepository extends InvitesRepositoryContract {
  _TestInvitesRepository(this._pendingInvites) {
    pendingInvitesStreamValue.addValue(_pendingInvites);
  }

  List<InviteModel> _pendingInvites;

  @override
  Future<InviteAcceptResult> acceptInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    final matchedInvite = _pendingInvites.cast<InviteModel?>().firstWhere(
          (invite) =>
              invite?.id == inviteId.value || invite?.eventId == inviteId.value,
          orElse: () => null,
        );
    final resolvedEventId = matchedInvite?.eventId ?? inviteId.value;
    _pendingInvites = _pendingInvites
        .where(
          (invite) =>
              invite.id != inviteId.value && invite.eventId != resolvedEventId,
        )
        .toList(growable: false);
    pendingInvitesStreamValue.addValue(_pendingInvites);
    await GetIt.I.get<UserEventsRepositoryContract>().confirmEventAttendance(
          userEventsRepoString(
            resolvedEventId,
            defaultValue: '',
            isRequired: true,
          ),
        );
    return buildInviteAcceptResult(
      inviteId: matchedInvite?.id ?? inviteId.value,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    return buildInviteAcceptResult(
      inviteId: 'mock-${code.value}',
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<List<InviteModel>> fetchInvites(
          {InvitesRepositoryContractPrimInt? page,
          InvitesRepositoryContractPrimInt? pageSize}) async =>
      _pendingInvites;

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
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

class _TestUserLocationRepository implements UserLocationRepositoryContract {
  static final CityCoordinate _defaultCoordinate = CityCoordinate(
    latitudeValue: LatitudeValue()..parse('-20.6772'),
    longitudeValue: LongitudeValue()..parse('-40.5093'),
  );

  final StreamValue<CityCoordinate?> _locationStream =
      StreamValue<CityCoordinate?>(defaultValue: _defaultCoordinate);
  final StreamValue<DateTime?> _nullDateStream =
      StreamValue<DateTime?>(defaultValue: null);
  final StreamValue<double?> _nullDoubleStream =
      StreamValue<double?>(defaultValue: null);
  final StreamValue<String?> _nullStringStream =
      StreamValue<String?>(defaultValue: null);

  @override
  StreamValue<String?> get lastKnownAddressStreamValue => _nullStringStream;

  @override
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
          defaultValue: LocationResolutionPhase.unknown);

  @override
  StreamValue<DateTime?> get lastKnownCapturedAtStreamValue => _nullDateStream;

  @override
  StreamValue<double?> get lastKnownAccuracyStreamValue => _nullDoubleStream;

  @override
  StreamValue<CityCoordinate?> get lastKnownLocationStreamValue =>
      _locationStream;

  @override
  StreamValue<CityCoordinate?> get userLocationStreamValue => _locationStream;

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

class _TestAppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() async {
    return AppDataDTO(
      tenantId: 'tenant-guarappari',
      name: 'Guarappari',
      type: 'tenant',
      mainDomain: 'https://guarappari.belluga.space',
      domains: const ['guarappari.belluga.space'],
      appDomains: const ['com.guarappari.app'],
      themeDataSettings: const {
        'brightness_default': 'light',
        'primary_seed_color': '#009688',
        'secondary_seed_color': '#3F51B5',
      },
      telemetry: const {
        'trackers': [],
      },
      telemetryContext: const {
        'location_freshness_minutes': 5,
      },
      push: const {
        'enabled': true,
        'types': ['event'],
        'throttles': {'max_per_hour': 20},
      },
    );
  }
}

class _TestAppDataLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<AppDataLocalInfoDTO> getInfo() async => AppDataLocalInfoDTO(
        platformTypeValue: PlatformTypeValue(defaultValue: AppType.mobile),
        port: null,
        hostname: '',
        href: '',
        device: 'guarappari-device-test',
      );
}

List<EventModel> _buildEvents() {
  final now = DateTime.now();
  return [
    _buildEvent(
      id: 'event-alpha',
      title: 'Show Alpha',
      artistName: 'Alpha',
      location: 'Arena Alpha',
      date: now.add(const Duration(days: 1)),
    ),
    _buildEvent(
      id: 'event-invite',
      title: 'Show Beta',
      artistName: 'Beta',
      location: 'Beta Hall',
      date: now.add(const Duration(days: 2)),
    ),
    _buildEvent(
      id: 'event-gamma',
      title: 'Show Gamma',
      artistName: 'Gamma',
      location: 'Lounge Gamma',
      date: now.add(const Duration(days: 3)),
    ),
    _buildEvent(
      id: 'event-past',
      title: 'Past Alpha',
      artistName: 'Alpha',
      location: 'Archive Hall',
      date: now.subtract(const Duration(days: 2)),
    ),
  ];
}

List<InviteModel> _buildInvites() {
  return [
    buildInviteModelFromPrimitives(
      id: _mongoIdForSeed('invite-1'),
      eventId: _AgendaFiltersHarness._pendingInviteEventId,
      eventName: 'Show Beta',
      eventDateTime: DateTime.now().add(const Duration(days: 2)),
      eventImageUrl: 'https://example.com/invite.png',
      location: 'Centro',
      hostName: 'Host',
      message: 'Vamos?',
      tags: const ['convite'],
    ),
  ];
}

EventModel _buildEvent({
  required String id,
  required String title,
  required String artistName,
  required String location,
  required DateTime date,
}) {
  final dto = EventDTO(
    id: _mongoIdForSeed(id),
    slug: id,
    type: EventTypeDTO(
      id: _mongoIdForSeed('type-show'),
      name: 'Show',
      slug: 'show',
      description: 'Show description for agenda regression tests.',
      icon: 'music',
      color: '#000000',
    ),
    title: title,
    content: 'Content for $title',
    location: location,
    venue: {
      'id': _mongoIdForSeed('venue-$location'),
      'display_name': location,
      'avatar_url': 'https://example.com/$location.png',
      'highlight': false,
      'is_favorite': false,
      'genres': const <String>[],
      'city': 'Guarapari',
      'state': 'ES',
      'country': 'BR',
      'partner_type': 'venue',
    },
    dateTimeStart: date.toIso8601String(),
    artists: [
      EventArtistDTO(
        id: _mongoIdForSeed('artist-$artistName'),
        name: artistName,
        avatarUrl: 'https://example.com/$artistName.png',
      ),
    ],
  );
  return dto.toDomain();
}

String _mongoIdForSeed(String seed) {
  final hash = seed.hashCode.abs();
  final hex = hash.toRadixString(16).padLeft(24, '0');
  return hex.substring(0, 24);
}

class _TestTenantHomeAgendaController extends TenantHomeAgendaController {
  _TestTenantHomeAgendaController({
    required ScheduleRepositoryContract scheduleRepository,
    required UserEventsRepositoryContract userEventsRepository,
    required InvitesRepositoryContract invitesRepository,
    required UserLocationRepositoryContract userLocationRepository,
    required AppDataRepository appDataRepository,
    required LocationOriginServiceContract locationOriginService,
  }) : super(
          scheduleRepository: scheduleRepository,
          userEventsRepository: userEventsRepository,
          invitesRepository: invitesRepository,
          userLocationRepository: userLocationRepository,
          appDataRepository: appDataRepository,
          locationOriginService: locationOriginService,
        );

  bool _disposed = false;

  @override
  void onDispose() {
    if (_disposed) return;
    _disposed = true;
    super.onDispose();
  }
}

class _TestEventSearchScreenController extends EventSearchScreenController {
  _TestEventSearchScreenController({
    required ScheduleRepositoryContract scheduleRepository,
    required UserEventsRepositoryContract userEventsRepository,
    required InvitesRepositoryContract invitesRepository,
    required UserLocationRepositoryContract userLocationRepository,
    required AppDataRepository appDataRepository,
    required LocationOriginServiceContract locationOriginService,
  }) : super(
          scheduleRepository: scheduleRepository,
          userEventsRepository: userEventsRepository,
          invitesRepository: invitesRepository,
          userLocationRepository: userLocationRepository,
          appDataRepository: appDataRepository,
          locationOriginService: locationOriginService,
        );

  bool _disposed = false;

  @override
  void onDispose() {
    if (_disposed) return;
    _disposed = true;
    super.onDispose();
  }
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _TestHttpClient implements HttpClient {
  bool _autoUncompress = true;

  static final List<int> _transparentImage = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientRequest implements HttpClientRequest {
  _TestHttpClientRequest(this._imageBytes);

  final List<int> _imageBytes;

  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse(_imageBytes);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _TestHttpClientResponse(this._imageBytes);

  final List<int> _imageBytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _imageBytes.length;

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => const [];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _TestHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  Future<Socket> detachSocket() async {
    throw UnsupportedError('detachSocket not supported in test client');
  }

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) async {
    return this;
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    controller.add(_imageBytes);
    controller.close();
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _TestHttpHeaders implements HttpHeaders {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpFor(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 250),
}) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _waitForDisplayedEvents(
  WidgetTester tester,
  StreamValue<List<VenueEventResume>> eventsStreamValue, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (eventsStreamValue.value.isNotEmpty) {
      return;
    }
    await _pumpFor(tester);
  }
}

Future<void> _waitForDisplayedHomeEvents(
  WidgetTester tester,
  StreamValue<TenantHomeAgendaDisplayState?> displayStateStreamValue, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if ((displayStateStreamValue.value?.events ?? const <EventModel>[])
        .isNotEmpty) {
      return;
    }
    await _pumpFor(tester);
  }
}
