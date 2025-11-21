import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

/// Controller for EventDetailScreen
/// Manages event state and user actions (confirm, invite, accept/decline)
class EventDetailController implements Disposable {
  EventDetailController({
    ScheduleRepositoryContract? repository,
    UserEventsRepositoryContract? userEventsRepository,
  })  : _repository = repository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>();

  final ScheduleRepositoryContract _repository;
  final UserEventsRepositoryContract _userEventsRepository;

  // Reactive state
  final eventStreamValue = StreamValue<EventModel?>();
  final isConfirmedStreamValue = StreamValue<bool>(defaultValue: false);
  final receivedInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const []);
  final sentInvitesStreamValue =
      StreamValue<List<SentInviteStatus>>(defaultValue: const []);
  final friendsGoingStreamValue =
      StreamValue<List<FriendResume>>(defaultValue: const []);
  final totalConfirmedStreamValue = StreamValue<int>(defaultValue: 0);
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);

  /// Load event by slug and initialize state
  Future<void> loadEventBySlug(String slug) async {
    isLoadingStreamValue.addValue(true);

    try {
      final event = await _repository.getEventBySlug(slug);

      if (event != null) {
        eventStreamValue.addValue(event);
        isConfirmedStreamValue.addValue(event.isConfirmedValue.value);
        receivedInvitesStreamValue.addValue(event.receivedInvites ?? const []);
        sentInvitesStreamValue.addValue(event.sentInvites ?? const []);
        friendsGoingStreamValue.addValue(event.friendsGoing ?? const []);
        totalConfirmedStreamValue.addValue(event.totalConfirmedValue.value);
      }
    } finally {
      isLoadingStreamValue.addValue(false);
    }
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
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  /// Accept a received invite
  /// TODO: Wire to real repository when backend is ready
  Future<void> acceptInvite(String inviteId) async {
    isLoadingStreamValue.addValue(true);

    try {
      // TODO: await _inviteRepository.acceptInvite(inviteId);

      // Optimistic update: remove from received invites and confirm
      receivedInvitesStreamValue.addValue(const []);
      isConfirmedStreamValue.addValue(true);

      final newTotal = totalConfirmedStreamValue.value + 1;
      totalConfirmedStreamValue.addValue(newTotal);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  /// Decline a received invite
  /// TODO: Wire to real repository when backend is ready
  Future<void> declineInvite(String inviteId) async {
    isLoadingStreamValue.addValue(true);

    try {
      // TODO: await _inviteRepository.declineInvite(inviteId);

      // Optimistic update: remove from received invites
      receivedInvitesStreamValue.addValue(const []);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  /// Send invites to friends
  /// TODO: Wire to real repository when backend is ready
  Future<void> inviteFriends(List<FriendResume> friends) async {
    if (friends.isEmpty) return;

    isLoadingStreamValue.addValue(true);

    try {
      // TODO: await _inviteRepository.sendInvites(
      //   eventStreamValue.value!.id.value,
      //   friends.map((f) => f.id.value).toList(),
      // );

      // Optimistic update: add to sent invites with pending status
      final now = DateTime.now();
      final newInvites = friends
          .map(
            (friend) => SentInviteStatus(
              friend: friend,
              status: InviteStatus.pending,
              sentAt: now,
            ),
          )
          .toList();

      final currentInvites = sentInvitesStreamValue.value;
      sentInvitesStreamValue.addValue([...currentInvites, ...newInvites]);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  @override
  void onDispose() {
    eventStreamValue.dispose();
    isConfirmedStreamValue.dispose();
    receivedInvitesStreamValue.dispose();
    sentInvitesStreamValue.dispose();
    friendsGoingStreamValue.dispose();
    totalConfirmedStreamValue.dispose();
    isLoadingStreamValue.dispose();
  }
}
