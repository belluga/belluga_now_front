import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
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
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  @override
  Future<List<InviteModel>> fetchInvites() async => <InviteModel>[];

  @override
  Future<void> sendInvites(String eventSlug, List<String> friendIds) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(String eventSlug) async =>
      <SentInviteStatus>[];
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  int startCount = 0;
  EventTrackerEvents? lastEvent;
  Map<String, dynamic>? lastProperties;

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    startCount += 1;
    lastEvent = event;
    lastProperties = properties;
    return const EventTrackerTimedEventHandle('handle');
  }

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

void main() {
  test('loadEventBySlug starts telemetry for the loaded event', () async {
    final event = _buildEvent();
    final telemetryRepository = _FakeTelemetryRepository();
    final controller = EventDetailController(
      repository: _FakeScheduleRepository(event),
      userEventsRepository: _FakeUserEventsRepository(),
      invitesRepository: _FakeInvitesRepository(),
      telemetryRepository: telemetryRepository,
    );

    await controller.loadEventBySlug(event.slug);

    expect(telemetryRepository.startCount, 1);
    expect(telemetryRepository.lastEvent, EventTrackerEvents.eventOpened);
    expect(telemetryRepository.lastProperties?['event_id'], event.id.value);
  });
}

EventModel _buildEvent() {
  return EventModel(
    id: MongoIDValue()..parse('507f1f77bcf86cd799439012'),
    slugValue: SlugValue()..parse('evento-teste'),
    type: EventTypeModel(
      id: MongoIDValue()..parse('507f1f77bcf86cd799439013'),
      name: TitleValue()..parse('Evento Teste'),
      slug: SlugValue()..parse('evento-tipo'),
      description: DescriptionValue()..parse('Descricao do evento tipo'),
      icon: SlugValue()..parse('event'),
      color: ColorValue(defaultValue: Colors.blue)..parse('3366FF'),
    ),
    title: TitleValue()..parse('Evento Teste'),
    content: HTMLContentValue()..parse('<p>Conteudo do evento</p>'),
    location: DescriptionValue()..parse('Localizacao principal'),
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
