import 'dart:async';

import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

/// Controller for EventDetailScreen
/// Manages event state and user actions (confirm, invite, accept/decline)
class EventDetailController implements Disposable {
  EventDetailController({
    ScheduleRepositoryContract? repository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
  })  : _repository = repository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository = userEventsRepository ??
            (() {
              if (!GetIt.I.isRegistered<UserEventsRepositoryContract>()) {
                GetIt.I.registerLazySingleton<UserEventsRepositoryContract>(
                  () => UserEventsRepository(),
                );
              }
              return GetIt.I.get<UserEventsRepositoryContract>();
            }()),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>();

  final ScheduleRepositoryContract _repository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;

  // Reactive state
  final eventStreamValue = StreamValue<EventModel?>();
  final isConfirmedStreamValue = StreamValue<bool>(defaultValue: false);
  final receivedInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const []);

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

        // Check local confirmation state first, then fallback to backend value
        final isConfirmedLocally =
            _userEventsRepository.isEventConfirmed(event.id.value);

        // DEBUG: Trace persistence
        // ignore: avoid_print
        print('EventDetailController: Loading event slug: "${event.slug}"');
        // ignore: avoid_print
        print(
            'EventDetailController: Repository confirmed IDs: ${_userEventsRepository.confirmedEventIdsStream.value}');
        // ignore: avoid_print
        print('EventDetailController: isConfirmedLocally: $isConfirmedLocally');

        isConfirmedStreamValue
            .addValue(isConfirmedLocally || event.isConfirmedValue.value);

        // Load received invites from repository (same source as swipe screen)
        final allInvites = _invitesRepository.pendingInvitesStreamValue.value;
        final eventInvites = allInvites
            .where((invite) => invite.eventIdValue.value == event.id.value)
            .toList();
        receivedInvitesStreamValue.addValue(eventInvites);

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
    final event = eventStreamValue.value;
    if (event == null) return;

    isLoadingStreamValue.addValue(true);

    try {
      // TODO: await _inviteRepository.acceptInvite(inviteId);

      // Persist confirmation
      await _userEventsRepository.confirmEventAttendance(event.id.value);

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
  Future<void> inviteFriends(List<EventFriendResume> friends) async {
    if (friends.isEmpty) return;
    final event = eventStreamValue.value;
    if (event == null) return;

    isLoadingStreamValue.addValue(true);

    try {
      // TODO: await _inviteRepository.sendInvites(
      //   event.id.value,
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

      final currentMap = Map<String, List<SentInviteStatus>>.from(
          _invitesRepository.sentInvitesByEventStreamValue.value);

      final currentList = currentMap[event.id.value] ?? [];
      currentMap[event.id.value] = [...currentList, ...newInvites];

      _invitesRepository.sentInvitesByEventStreamValue.addValue(currentMap);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  @override
  void onDispose() {
    eventStreamValue.dispose();
    isConfirmedStreamValue.dispose();
    receivedInvitesStreamValue.dispose();
    // sentInvitesByEventStreamValue is owned by repository, do not dispose
    friendsGoingStreamValue.dispose();
    totalConfirmedStreamValue.dispose();
    isLoadingStreamValue.dispose();
  }
}
