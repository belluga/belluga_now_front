import 'dart:async';

import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

/// Controller for EventDetailScreen
/// Manages event state and user actions (confirm, invite, accept/decline)
class EventDetailController implements Disposable {
  EventDetailController({
    ScheduleRepositoryContract? repository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
    TelemetryRepositoryContract? telemetryRepository,
  })  : _repository = repository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  final ScheduleRepositoryContract _repository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;
  final TelemetryRepositoryContract _telemetryRepository;
  Future<EventTrackerTimedEventHandle?>? _eventOpenedHandleFuture;
  String? _telemetryEventId;
  StreamSubscription<List<InviteModel>>? _pendingInvitesSubscription;

  // Reactive state
  final eventStreamValue = StreamValue<EventModel?>();
  final isConfirmedStreamValue = StreamValue<bool>(defaultValue: false);
  final receivedInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const []);
  final inviteDeckIndexStreamValue = StreamValue<int>(defaultValue: 0);

  // Delegate to repository for single source of truth
  StreamValue<Map<String, List<SentInviteStatus>>>
      get sentInvitesByEventStreamValue =>
          _invitesRepository.sentInvitesByEventStreamValue;

  final friendsGoingStreamValue =
      StreamValue<List<EventFriendResume>>(defaultValue: const []);
  final totalConfirmedStreamValue = StreamValue<int>(defaultValue: 0);
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);

  /// Load event by slug and initialize state
  Future<void> loadEventBySlug(String slug) async {
    isLoadingStreamValue.addValue(true);

    try {
      final event = await _repository.getEventBySlug(slug);

      if (event != null) {
        eventStreamValue.addValue(event);
        unawaited(startEventTelemetry(event));

        // Check local confirmation state first, then fallback to backend value
        final isConfirmedLocally =
            _userEventsRepository.isEventConfirmed(event.id.value);

        isConfirmedStreamValue
            .addValue(isConfirmedLocally || event.isConfirmedValue.value);

        // Load received invites from repository (same source as swipe screen)
        _bindPendingInvites(event.id.value);

        // Populate repository with initial data from event model if missing
        // This ensures we have data even before a refresh
        final currentMap = Map<String, List<SentInviteStatus>>.from(
            _invitesRepository.sentInvitesByEventStreamValue.value);

        if (!currentMap.containsKey(event.id.value) &&
            event.sentInvites != null &&
            event.sentInvites!.isNotEmpty) {
          currentMap[event.id.value] = event.sentInvites!;
          _invitesRepository.sentInvitesByEventStreamValue.addValue(currentMap);
        }

        friendsGoingStreamValue.addValue(event.friendsGoing ?? const []);
        totalConfirmedStreamValue.addValue(event.totalConfirmedValue.value);
      }
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  Future<void> startEventTelemetry(EventModel event) async {
    final eventId = event.id.value;
    if (_telemetryEventId == eventId) {
      return;
    }
    if (_eventOpenedHandleFuture != null) {
      await finishEventTelemetry();
    }
    _telemetryEventId = eventId;
    _eventOpenedHandleFuture = _telemetryRepository.startTimedEvent(
      EventTrackerEvents.eventOpened,
      eventName: 'event_opened',
      properties: {
        'event_id': eventId,
      },
    );
  }

  Future<void> finishEventTelemetry() async {
    final handleFuture = _eventOpenedHandleFuture;
    if (handleFuture == null) {
      _telemetryEventId = null;
      return;
    }
    _eventOpenedHandleFuture = null;
    final handle = await handleFuture;
    if (handle != null) {
      await _telemetryRepository.finishTimedEvent(handle);
    }
    _telemetryEventId = null;
  }

  /// Confirm attendance at this event
  Future<void> confirmAttendance() async {
    final event = eventStreamValue.value;
    if (event == null) return;

    isLoadingStreamValue.addValue(true);

    try {
      // Call repository to persist confirmation
      await _userEventsRepository.confirmEventAttendance(event.id.value);

      // Optimistic update
      isConfirmedStreamValue.addValue(true);

      // Update total confirmed count
      final newTotal = totalConfirmedStreamValue.value + 1;
      totalConfirmedStreamValue.addValue(newTotal);

      // Clear received invites (since we're now confirmed)
      receivedInvitesStreamValue.addValue(const []);
      _syncInviteDeckIndex(0);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  /// Accept a received invite
  Future<InviteAcceptResult> acceptInvite(String inviteId) async {
    isLoadingStreamValue.addValue(true);

    try {
      final result = await _invitesRepository.acceptInvite(inviteId);
      final autoConfirmed =
          result.nextStep == InviteNextStep.freeConfirmationCreated;
      if (result.status == 'accepted' && autoConfirmed) {
        isConfirmedStreamValue.addValue(true);
        final newTotal = totalConfirmedStreamValue.value + 1;
        totalConfirmedStreamValue.addValue(newTotal);
      }
      _syncInviteDeckIndex(receivedInvitesStreamValue.value.length);
      return result;
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  /// Decline a received invite
  Future<InviteDeclineResult> declineInvite(String inviteId) async {
    isLoadingStreamValue.addValue(true);

    try {
      final result = await _invitesRepository.declineInvite(inviteId);
      _applyDeclineDeckState(result);
      return result;
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  /// Send invites to friends
  Future<void> inviteFriends(List<EventFriendResume> friends) async {
    if (friends.isEmpty) return;
    final event = eventStreamValue.value;
    if (event == null) return;

    isLoadingStreamValue.addValue(true);

    try {
      await _invitesRepository.sendInvites(event.id.value, friends);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  void setInviteDeckIndex(int index) {
    if (index != inviteDeckIndexStreamValue.value) {
      inviteDeckIndexStreamValue.addValue(index);
    }
  }

  void _syncInviteDeckIndex(int invitesLength) {
    if (invitesLength <= 0) {
      setInviteDeckIndex(0);
      return;
    }
    final clamped =
        inviteDeckIndexStreamValue.value.clamp(0, invitesLength - 1);
    setInviteDeckIndex(clamped);
  }

  void _bindPendingInvites(String eventId) {
    _pendingInvitesSubscription?.cancel();
    _pendingInvitesSubscription = _invitesRepository
        .pendingInvitesStreamValue.stream
        .listen((invites) => _syncReceivedInvitesForEvent(invites, eventId));
    _syncReceivedInvitesForEvent(
      _invitesRepository.pendingInvitesStreamValue.value,
      eventId,
    );
  }

  void _syncReceivedInvitesForEvent(List<InviteModel> invites, String eventId) {
    final eventInvites = invites
        .where((invite) => invite.eventIdValue.value == eventId)
        .toList();
    receivedInvitesStreamValue.addValue(eventInvites);
    _syncInviteDeckIndex(eventInvites.length);
  }

  void _applyDeclineDeckState(InviteDeclineResult result) {
    if (result.groupHasOtherPending) {
      _syncInviteDeckIndex(receivedInvitesStreamValue.value.length);
      return;
    }

    final remaining = receivedInvitesStreamValue.value;
    _syncInviteDeckIndex(remaining.length);
  }

  @override
  void onDispose() {
    _pendingInvitesSubscription?.cancel();
    eventStreamValue.dispose();
    isConfirmedStreamValue.dispose();
    receivedInvitesStreamValue.dispose();
    inviteDeckIndexStreamValue.dispose();
    // sentInvitesByEventStreamValue is owned by repository, do not dispose
    friendsGoingStreamValue.dispose();
    totalConfirmedStreamValue.dispose();
    isLoadingStreamValue.dispose();
  }
}
