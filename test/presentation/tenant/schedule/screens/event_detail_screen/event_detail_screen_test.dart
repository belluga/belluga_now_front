import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/event_detail_screen.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class _FakeScheduleRepository implements ScheduleRepositoryContract {
  _FakeScheduleRepository(this._event);

  final EventModel _event;

  @override
  Future<EventModel?> getEventBySlug(String slug) async => _event;

  @override
  Future<List<EventModel>> getAllEvents() async =>
      throw UnimplementedError();

  @override
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async =>
      throw UnimplementedError();

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
  }) async =>
      throw UnimplementedError();

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async =>
      throw UnimplementedError();

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date) async =>
      throw UnimplementedError();

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async =>
      throw UnimplementedError();

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
  }) =>
      const Stream.empty();
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: <String>{});

  final Set<String> _confirmed = <String>{};

  @override
  bool isEventConfirmed(String eventId) => _confirmed.contains(eventId);

  @override
  Future<void> confirmEventAttendance(String eventId) async {
    _confirmed.add(eventId);
    confirmedEventIdsStream.addValue(Set<String>.from(_confirmed));
  }

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {
    _confirmed.remove(eventId);
    confirmedEventIdsStream.addValue(Set<String>.from(_confirmed));
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async =>
      <VenueEventResume>[];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async =>
      <VenueEventResume>[];
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository(List<InviteModel> invites) {
    pendingInvitesStreamValue.addValue(invites);
  }

  @override
  Future<List<InviteModel>> fetchInvites() async =>
      pendingInvitesStreamValue.value;

  @override
  Future<void> sendInvites(String eventSlug, List<String> friendIds) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(String eventSlug) async =>
      <SentInviteStatus>[];
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      const EventTrackerTimedEventHandle('handle');

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async =>
      true;

  @override
  Future<bool> flushTimedEvents() async => true;

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      true;

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;
}

class _RecordingStackRouter extends Mock implements StackRouter {
  bool pushCalled = false;
  PageRouteInfo? lastRoute;

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushCalled = true;
    lastRoute = route;
    return null;
  }
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = _TestHttpOverrides();
    await initializeDateFormatting('pt_BR');
  });

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('Accept invite navigates to invite flow', (tester) async {
    final event = _buildEvent();
    final invite = _buildInvite(eventId: event.id.value);
    final controller = EventDetailController(
      repository: _FakeScheduleRepository(event),
      userEventsRepository: _FakeUserEventsRepository(),
      invitesRepository: _FakeInvitesRepository([invite]),
      telemetryRepository: _FakeTelemetryRepository(),
    );
    GetIt.I.registerSingleton<EventDetailController>(controller);

    final mockRouter = _RecordingStackRouter();

    await tester.pumpWidget(
      StackRouterScope(
        controller: mockRouter,
        stateHash: 0,
        child: MaterialApp(
          home: EventDetailScreen(event: event),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    final acceptFinder = find.text('Aceitar convite');
    expect(acceptFinder, findsOneWidget);
    await tester.tap(acceptFinder, warnIfMissed: false);
    await tester.pump();

    expect(mockRouter.pushCalled, isTrue);
    expect(mockRouter.lastRoute, isA<InviteFlowRoute>());
  });
}

EventModel _buildEvent() {
  return EventModel(
    id: MongoIDValue()..parse('507f1f77bcf86cd799439112'),
    slugValue: SlugValue()..parse('evento-teste'),
    type: EventTypeModel(
      id: MongoIDValue()..parse('507f1f77bcf86cd799439113'),
      name: TitleValue()..parse('Evento Tipo'),
      slug: SlugValue()..parse('evento-tipo'),
      description: DescriptionValue()..parse('Descricao do tipo de evento'),
      icon: SlugValue()..parse('event'),
      color: ColorValue(defaultValue: Colors.blue)..parse('3366FF'),
    ),
    title: TitleValue()..parse('Evento Teste'),
    content: HTMLContentValue()..parse('<p>Conteudo do evento</p>'),
    location: DescriptionValue()..parse('Localizacao teste'),
    venue: null,
    thumb: null,
    dateTimeStart: DateTimeValue()..parse('2026-01-01T10:00:00.000Z'),
    dateTimeEnd: DateTimeValue()..parse('2026-01-01T12:00:00.000Z'),
    artists: const [],
    coordinate: null,
    tags: const [],
    isConfirmedValue: EventIsConfirmedValue()..parse('false'),
    totalConfirmedValue: EventTotalConfirmedValue()..parse('0'),
    friendsGoing: const [],
  );
}

InviteModel _buildInvite({required String eventId}) {
  return InviteModel.fromPrimitives(
    id: 'invite-123',
    eventId: eventId,
    eventName: 'Evento Teste',
    eventDateTime: DateTime(2026, 1, 1, 10, 0),
    eventImageUrl: 'https://example.com/event.png',
    location: 'Praia Central',
    hostName: 'Host Teste',
    message: 'Bora?',
    tags: const ['show'],
  );
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

  Stream<List<int>> get stream => Stream<List<int>>.value(_imageBytes);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
