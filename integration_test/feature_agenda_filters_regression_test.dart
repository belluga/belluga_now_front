import 'dart:async';
import 'dart:io';

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
import 'package:belluga_now/infrastructure/dal/dto/mappers/artist_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_status_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/partner_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/schedule_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/thumb_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/event_search_screen.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('Home agenda filters (invites, confirmed, search)',
      (tester) async {
    debugPrint('Home agenda test: start');
    final harness = _AgendaFiltersHarness();
    harness.register();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeAgendaSection(
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

    final controller = harness.homeController;
    expect(controller.displayedEventsStreamValue.value, isNotEmpty);
    debugPrint('Home agenda test: initial events ready');

    debugPrint('Home agenda test: set invite filter');
    controller.setInviteFilter(InviteFilter.invitesAndConfirmed);
    debugPrint('Home agenda test: pump after invite filter');
    await _pumpFor(tester);
    debugPrint('Home agenda test: pump done');
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
    debugPrint('Home agenda test: invite filter checked');

    harness.invitesRepository.acceptInvite(harness.pendingInviteEventId);
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
    debugPrint('Home agenda test: confirmed filter checked');

    controller.setInviteFilter(InviteFilter.none);
    await _pumpFor(tester);

    final artistName =
        controller.displayedEventsStreamValue.value.first.artists.first.displayName;
    controller.searchController.text = artistName;
    controller.searchEvents(artistName);
    await _pumpFor(tester);

    _expectOnlyArtistMatches(
      controller.displayedEventsStreamValue.value,
      artistName,
    );
    expect(
      controller.displayedEventsStreamValue.value
          .map((event) => event.title.value)
          .toList(),
      ['Show Alpha'],
    );
    debugPrint('Home agenda test: search checked');

    harness.dispose();
    debugPrint('Home agenda test: done');
  });

  testWidgets('Agenda screen filters (past, invites, confirmed, search)',
      (tester) async {
    debugPrint('Agenda screen test: start');
    final harness = _AgendaFiltersHarness();
    harness.register(forAgendaScreen: true);

    await tester.pumpWidget(
      const MaterialApp(
        home: EventSearchScreen(),
      ),
    );

    await _pumpFor(tester);
    debugPrint('Agenda screen test: widget pumped');

    final controller = harness.agendaController;
    expect(controller.displayedEventsStreamValue.value, isNotEmpty);
    debugPrint('Agenda screen test: initial events ready');

    controller.toggleHistory();
    await _pumpFor(tester);
    for (final event in controller.displayedEventsStreamValue.value) {
      expect(
        event.dateTimeStart.value!.isBefore(DateTime.now()),
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

    harness.invitesRepository.acceptInvite(harness.pendingInviteEventId);
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

    final artistName =
        controller.displayedEventsStreamValue.value.first.artists.first.displayName;
    controller.searchController.text = artistName;
    controller.searchEvents(artistName);
    await _pumpFor(tester);

    _expectOnlyArtistMatches(
      controller.displayedEventsStreamValue.value,
      artistName,
    );
    expect(
      controller.displayedEventsStreamValue.value
          .map((event) => event.title.value)
          .toList(),
      ['Show Alpha'],
    );
    debugPrint('Agenda screen test: search checked');

    harness.dispose();
    debugPrint('Agenda screen test: done');
  });
}

void _expectOnlyInviteFiltered(
  List<EventModel> events,
  String pendingEventId,
  Set<String> confirmedEventIds,
) {
  expect(events, isNotEmpty);
  for (final event in events) {
    final id = event.id.value;
    final isPending = id == pendingEventId;
    final isConfirmed = confirmedEventIds.contains(id);
    expect(isPending || isConfirmed, isTrue);
  }
}

void _expectOnlyArtistMatches(List<EventModel> events, String artistName) {
  expect(events, isNotEmpty);
  for (final event in events) {
    final matchesArtist =
        event.artists.any((artist) => artist.displayName == artistName);
    expect(matchesArtist, isTrue);
  }
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

  static final String _pendingInviteEventId =
      _mongoIdForSeed('event-invite');
  final String pendingInviteEventId;
  final _TestScheduleRepository scheduleRepository;
  final _TestUserEventsRepository userEventsRepository;
  final _TestInvitesRepository invitesRepository;
  final _TestUserLocationRepository userLocationRepository;
  final AppDataRepository appDataRepository;

  late final TenantHomeAgendaController homeController;
  late final EventSearchScreenController agendaController;

  void register({bool forAgendaScreen = false}) {
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

    homeController = _TestTenantHomeAgendaController(
      scheduleRepository: scheduleRepository,
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      userLocationRepository: userLocationRepository,
      appDataRepository: appDataRepository,
    );
    getIt.registerSingleton<TenantHomeAgendaController>(homeController);

    agendaController = _TestEventSearchScreenController(
      scheduleRepository: scheduleRepository,
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      userLocationRepository: userLocationRepository,
      appDataRepository: appDataRepository,
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

class _TestScheduleRepository implements ScheduleRepositoryContract {
  _TestScheduleRepository(this._events);

  final List<EventModel> _events;

  @override
  Future<List<EventModel>> getAllEvents() async => _events;

  @override
  Future<EventModel?> getEventBySlug(String slug) async {
    for (final event in _events) {
      if (event.slug == slug) return event;
    }
    return null;
  }

  @override
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async =>
      [];

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
    final now = DateTime.now();
    final query = searchQuery.trim().toLowerCase();

    final filtered = _events.where((event) {
      final start = event.dateTimeStart.value!;
      final isPast = start.isBefore(now);
      if (showPastOnly != isPast) return false;

      if (query.isEmpty) return true;

      final title = event.title.value.toLowerCase();
      final location = event.location.value.toLowerCase();
      final artists =
          event.artists.map((artist) => artist.displayName.toLowerCase());

      return title.contains(query) ||
          location.contains(query) ||
          artists.any((name) => name.contains(query));
    }).toList();

    return PagedEventsResult(events: filtered, hasMore: false);
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async =>
      throw UnimplementedError();

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

class _TestUserEventsRepository implements UserEventsRepositoryContract {
  final StreamValue<Set<String>> _confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  StreamValue<Set<String>> get confirmedEventIdsStream =>
      _confirmedEventIdsStream;

  @override
  Future<void> confirmEventAttendance(String eventId) async {
    final updated = {..._confirmedEventIdsStream.value, eventId};
    _confirmedEventIdsStream.addValue(updated);
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  bool isEventConfirmed(String eventId) =>
      _confirmedEventIdsStream.value.contains(eventId);

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {
    final updated = {..._confirmedEventIdsStream.value}..remove(eventId);
    _confirmedEventIdsStream.addValue(updated);
  }
}

class _TestInvitesRepository extends InvitesRepositoryContract {
  _TestInvitesRepository(this._pendingInvites);

  List<InviteModel> _pendingInvites;

  void acceptInvite(String eventId) {
    _pendingInvites = _pendingInvites
        .where((invite) => invite.eventId != eventId)
        .toList(growable: false);
    pendingInvitesStreamValue.addValue(_pendingInvites);
    GetIt.I.get<UserEventsRepositoryContract>().confirmEventAttendance(eventId);
  }

  @override
  Future<List<InviteModel>> fetchInvites() async => _pendingInvites;

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(String eventSlug) async {
    return const [];
  }

  @override
  Future<void> sendInvites(String eventSlug, List<String> friendIds) async {}
}

class _TestUserLocationRepository implements UserLocationRepositoryContract {
  final StreamValue<CityCoordinate?> _nullLocationStream =
      StreamValue<CityCoordinate?>(defaultValue: null);
  final StreamValue<DateTime?> _nullDateStream =
      StreamValue<DateTime?>(defaultValue: null);
  final StreamValue<double?> _nullDoubleStream =
      StreamValue<double?>(defaultValue: null);
  final StreamValue<String?> _nullStringStream =
      StreamValue<String?>(defaultValue: null);

  @override
  StreamValue<String?> get lastKnownAddressStreamValue => _nullStringStream;

  @override
  StreamValue<DateTime?> get lastKnownCapturedAtStreamValue => _nullDateStream;

  @override
  StreamValue<double?> get lastKnownAccuracyStreamValue => _nullDoubleStream;

  @override
  StreamValue<CityCoordinate?> get lastKnownLocationStreamValue =>
      _nullLocationStream;

  @override
  StreamValue<CityCoordinate?> get userLocationStreamValue =>
      _nullLocationStream;

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

class _TestAppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() async {
    return AppDataDTO(
      name: 'Test',
      type: 'tenant',
      mainDomain: 'example.com',
      themeDataSettings: const {},
    );
  }
}

class _TestAppDataLocalInfoSource extends AppDataLocalInfoSource {
  @override
  Future<Map<String, dynamic>> getInfo() async => const {};
}

List<EventModel> _buildEvents() {
  final now = DateTime.now();
  return [
    _buildEvent(
      id: 'event-alpha',
      title: 'Show Alpha',
      artistName: 'Alpha',
      date: now.add(const Duration(days: 1)),
    ),
    _buildEvent(
      id: 'event-invite',
      title: 'Show Beta',
      artistName: 'Beta',
      date: now.add(const Duration(days: 2)),
    ),
    _buildEvent(
      id: 'event-gamma',
      title: 'Show Gamma',
      artistName: 'Gamma',
      date: now.add(const Duration(days: 3)),
    ),
    _buildEvent(
      id: 'event-past',
      title: 'Past Alpha',
      artistName: 'Alpha',
      date: now.subtract(const Duration(days: 2)),
    ),
  ];
}

List<InviteModel> _buildInvites() {
  return [
    InviteModel.fromPrimitives(
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

final _scheduleDtoMapper = _TestScheduleDtoMapper();

EventModel _buildEvent({
  required String id,
  required String title,
  required String artistName,
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
    location: 'Centro',
    dateTimeStart: date.toIso8601String(),
    artists: [
      EventArtistDTO(
        id: _mongoIdForSeed('artist-$artistName'),
        name: artistName,
        avatarUrl: 'https://example.com/$artistName.png',
      ),
    ],
  );
  return _scheduleDtoMapper.mapEventDto(dto);
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
  }) : super(
          scheduleRepository: scheduleRepository,
          userEventsRepository: userEventsRepository,
          invitesRepository: invitesRepository,
          userLocationRepository: userLocationRepository,
          appDataRepository: appDataRepository,
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
  }) : super(
          scheduleRepository: scheduleRepository,
          userEventsRepository: userEventsRepository,
          invitesRepository: invitesRepository,
          userLocationRepository: userLocationRepository,
          appDataRepository: appDataRepository,
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
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
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

class _TestScheduleDtoMapper
    with
        InviteDtoMapper,
        ThumbDtoMapper,
        ArtistDtoMapper,
        PartnerDtoMapper,
        InviteStatusDtoMapper,
        ScheduleDtoMapper {}

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
Future<void> _pumpFor(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
}
