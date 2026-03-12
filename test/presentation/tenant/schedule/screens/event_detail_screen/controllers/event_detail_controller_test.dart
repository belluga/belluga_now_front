import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
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
  Future<List<EventModel>> getAllEvents() async => throw UnimplementedError();

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
  final List<String> confirmedCalls = <String>[];

  @override
  bool isEventConfirmed(String eventId) => _confirmed.contains(eventId);

  @override
  Future<void> confirmEventAttendance(String eventId) async {
    confirmedCalls.add(eventId);
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
  Future<List<VenueEventResume>> fetchMyEvents() async => <VenueEventResume>[];
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({
    this.acceptStatus = 'accepted',
    this.acceptNextStep = InviteNextStep.freeConfirmationCreated,
    this.initialPendingInvites = const <InviteModel>[],
  }) {
    pendingInvitesStreamValue.addValue(initialPendingInvites);
  }

  final String acceptStatus;
  final InviteNextStep acceptNextStep;
  final List<InviteModel> initialPendingInvites;
  final List<String> acceptedInviteIds = <String>[];
  final List<String> declinedInviteIds = <String>[];
  int sendInvitesCallCount = 0;
  String? lastSentEventId;
  List<EventFriendResume> lastSentRecipients = const <EventFriendResume>[];

  @override
  Future<List<InviteModel>> fetchInvites(
          {int page = 1, int pageSize = 20}) async =>
      initialPendingInvites;

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      const InviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async {
    acceptedInviteIds.add(inviteId);
    return InviteAcceptResult(
      inviteId: inviteId,
      status: acceptStatus,
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: acceptNextStep,
      closedDuplicateInviteIds: const [],
    );
  }

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async {
    declinedInviteIds.add(inviteId);
    return InviteDeclineResult(
      inviteId: inviteId,
      status: 'declined',
      groupHasOtherPending: false,
    );
  }

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
  Future<void> sendInvites(
    String eventId,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {
    sendInvitesCallCount += 1;
    lastSentEventId = eventId;
    lastSentRecipients = List<EventFriendResume>.from(recipients);
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
          String eventSlug) async =>
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

  test(
      'acceptInvite marks event confirmed only when free confirmation is created',
      () async {
    final event = _buildEvent();
    final controller = EventDetailController(
      repository: _FakeScheduleRepository(event),
      userEventsRepository: _FakeUserEventsRepository(),
      invitesRepository: _FakeInvitesRepository(
        acceptStatus: 'accepted',
        acceptNextStep: InviteNextStep.freeConfirmationCreated,
      ),
      telemetryRepository: _FakeTelemetryRepository(),
    );

    await controller.loadEventBySlug(event.slug);
    await controller.acceptInvite('invite-1');

    expect(controller.isConfirmedStreamValue.value, isTrue);
    expect(controller.totalConfirmedStreamValue.value, 1);
  });

  test(
      'acceptInvite keeps event unconfirmed when next step requires reservation',
      () async {
    final event = _buildEvent();
    final controller = EventDetailController(
      repository: _FakeScheduleRepository(event),
      userEventsRepository: _FakeUserEventsRepository(),
      invitesRepository: _FakeInvitesRepository(
        acceptStatus: 'accepted',
        acceptNextStep: InviteNextStep.reservationRequired,
      ),
      telemetryRepository: _FakeTelemetryRepository(),
    );

    await controller.loadEventBySlug(event.slug);
    await controller.acceptInvite('invite-2');

    expect(controller.isConfirmedStreamValue.value, isFalse);
    expect(controller.totalConfirmedStreamValue.value, 0);
  });

  test('confirmAttendance persists confirmation and clears invite deck',
      () async {
    final event = _buildEvent();
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository(
      initialPendingInvites: [
        InviteModel.fromPrimitives(
          id: 'invite-11',
          eventId: event.id.value,
          eventName: event.title.value,
          eventDateTime: event.dateTimeStart.value!,
          eventImageUrl: 'https://example.org/event-11.jpg',
          location: event.location.value,
          hostName: 'Host',
          message: 'Join us',
          tags: const ['music'],
          inviterName: 'Ana',
        ),
      ],
    );
    final controller = EventDetailController(
      repository: _FakeScheduleRepository(event),
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      telemetryRepository: _FakeTelemetryRepository(),
    );

    await controller.loadEventBySlug(event.slug);
    expect(controller.receivedInvitesStreamValue.value, hasLength(1));

    await controller.confirmAttendance();

    expect(userEventsRepository.confirmedCalls, [event.id.value]);
    expect(controller.isConfirmedStreamValue.value, isTrue);
    expect(controller.totalConfirmedStreamValue.value, 1);
    expect(controller.receivedInvitesStreamValue.value, isEmpty);
    expect(controller.inviteDeckIndexStreamValue.value, 0);
  });

  test('inviteFriends sends invite payload with event id and recipients',
      () async {
    final event = _buildEvent();
    final invitesRepository = _FakeInvitesRepository();
    final controller = EventDetailController(
      repository: _FakeScheduleRepository(event),
      userEventsRepository: _FakeUserEventsRepository(),
      invitesRepository: invitesRepository,
      telemetryRepository: _FakeTelemetryRepository(),
    );
    final recipients = <EventFriendResume>[
      EventFriendResume.fromPrimitives(
        id: 'friend-1',
        displayName: 'Friend One',
      ),
      EventFriendResume.fromPrimitives(
        id: 'friend-2',
        displayName: 'Friend Two',
      ),
    ];

    await controller.loadEventBySlug(event.slug);
    await controller.inviteFriends(recipients);

    expect(invitesRepository.sendInvitesCallCount, 1);
    expect(invitesRepository.lastSentEventId, event.id.value);
    expect(
      invitesRepository.lastSentRecipients.map((friend) => friend.id).toList(),
      ['friend-1', 'friend-2'],
    );
  });

  test(
      'inviteFriends is a no-op when event is not loaded or recipients are empty',
      () async {
    final event = _buildEvent();
    final invitesRepository = _FakeInvitesRepository();
    final controller = EventDetailController(
      repository: _FakeScheduleRepository(event),
      userEventsRepository: _FakeUserEventsRepository(),
      invitesRepository: invitesRepository,
      telemetryRepository: _FakeTelemetryRepository(),
    );

    await controller.inviteFriends([
      EventFriendResume.fromPrimitives(id: 'friend-1', displayName: 'Friend'),
    ]);
    await controller.loadEventBySlug(event.slug);
    await controller.inviteFriends(const <EventFriendResume>[]);

    expect(invitesRepository.sendInvitesCallCount, 0);
  });

  test('acceptInvite does not auto-confirm when status is already_accepted',
      () async {
    final event = _buildEvent();
    final controller = EventDetailController(
      repository: _FakeScheduleRepository(event),
      userEventsRepository: _FakeUserEventsRepository(),
      invitesRepository: _FakeInvitesRepository(
        acceptStatus: 'already_accepted',
        acceptNextStep: InviteNextStep.freeConfirmationCreated,
      ),
      telemetryRepository: _FakeTelemetryRepository(),
    );

    await controller.loadEventBySlug(event.slug);
    await controller.acceptInvite('invite-3');

    expect(controller.isConfirmedStreamValue.value, isFalse);
    expect(controller.totalConfirmedStreamValue.value, 0);
  });
}

EventModel _buildEvent() {
  return EventModel(
    id: MongoIDValue()..parse('507f1f77bcf86cd799439012'),
    slugValue: SlugValue()..parse('evento-teste'),
    type: EventTypeModel(
      id: EventTypeIdValue()..parse('event-type-1'),
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
