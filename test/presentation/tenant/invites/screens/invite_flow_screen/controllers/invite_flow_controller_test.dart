import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

class _TrackedEvent {
  _TrackedEvent({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  final List<_TrackedEvent> startedEvents = [];
  int _seed = 0;

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    return true;
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    startedEvents.add(
      _TrackedEvent(
        event: event,
        eventName: eventName,
        properties: properties,
      ),
    );
    return EventTrackerTimedEventHandle('handle-${_seed++}');
  }

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async {
    return true;
  }

  @override
  Future<bool> flushTimedEvents() async {
    return true;
  }

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({required List<InviteModel> initialInvites})
      : _initialInvites = initialInvites;

  final List<InviteModel> _initialInvites;

  @override
  Future<List<InviteModel>> fetchInvites() async => _initialInvites;

  @override
  Future<void> sendInvites(String eventSlug, List<String> friendIds) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    String eventSlug,
  ) async =>
      const [];
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<void> confirmEventAttendance(String eventId) async {}

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {}

  @override
  bool isEventConfirmed(String eventId) => false;
}

InviteModel _buildInvite(String id) {
  return InviteModel.fromPrimitives(
    id: id,
    eventId: 'event-$id',
    eventName: 'Event $id',
    eventDateTime: DateTime(2025, 1, 1, 18),
    eventImageUrl: 'https://example.com/$id.jpg',
    location: 'Guarapari',
    hostName: 'Host $id',
    message: 'Invite $id',
    tags: const ['music'],
  );
}

void main() {
  test('invite_opened fires when the top invite changes', () async {
    final telemetry = _FakeTelemetryRepository();
    final invites = [_buildInvite('1'), _buildInvite('2')];
    final repository = _FakeInvitesRepository(initialInvites: invites);
    final userEventsRepository = _FakeUserEventsRepository();
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: userEventsRepository,
      telemetryRepository: telemetry,
    );

    await controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(telemetry.startedEvents.length, 1);
    expect(telemetry.startedEvents.first.eventName, 'invite_opened');
    expect(
      telemetry.startedEvents.first.properties?['event_id'],
      'event-1',
    );

    controller.removeInvite();
    await Future<void>.delayed(Duration.zero);

    expect(telemetry.startedEvents.length, 2);
    expect(
      telemetry.startedEvents[1].properties?['event_id'],
      'event-2',
    );

    await controller.onDispose();
  });
}
