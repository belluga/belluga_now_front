import 'dart:async';

import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InviteShareScreenController with Disposable {
  InviteShareScreenController({
    FriendsRepositoryContract? friendsRepository,
    InvitesRepositoryContract? invitesRepository,
  })  : _friendsRepository =
            friendsRepository ?? GetIt.I.get<FriendsRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>();

  final FriendsRepositoryContract _friendsRepository;
  final InvitesRepositoryContract _invitesRepository;

  // Store event ID for refresh functionality
  String? _currentEventId;

  final friendsSuggestionsStreamValue =
      StreamValue<List<InviteFriendResumeWithStatus>?>();
  final selectedFriendsSuggestionsStreamValue =
      StreamValue<List<InviteFriendResume>>(defaultValue: []);

  /// Initialize controller with event ID to fetch friends and their invite status
  /// eventId should be the ID of the event (not the invite ID)
  Future<void> init(String eventId) async {
    _currentEventId = eventId;
    await _loadFriendsWithStatus();
  }

  void toggleFriend(InviteFriendResume friend) {
    final _selectedFriends = List<InviteFriendResume>.from(
        selectedFriendsSuggestionsStreamValue.value);
    if (_selectedFriends.contains(friend)) {
      _selectedFriends.remove(friend);
    } else {
      _selectedFriends.add(friend);
    }
    selectedFriendsSuggestionsStreamValue.addValue(_selectedFriends);
  }

  /// Refresh friends list from server
  Future<void> refreshFriends() async {
    if (_currentEventId == null) return;
    await _friendsRepository.fetchAndCacheFriends(forceRefresh: true);
    await _loadFriendsWithStatus();
  }

  /// Send invites to selected friends
  Future<void> sendInvites() async {
    if (_currentEventId == null) return;

    final selectedFriends = selectedFriendsSuggestionsStreamValue.value;
    if (selectedFriends.isEmpty) return;

    final friendIds = selectedFriends.map((f) => f.id).toList();

    // Send invites via repository
    await _invitesRepository.sendInvites(_currentEventId!, friendIds);

    // Clear selection
    selectedFriendsSuggestionsStreamValue.addValue([]);

    // Refresh list to show new status
    await _loadFriendsWithStatus();
  }

  /// Load friends and merge with event-specific invite status
  Future<void> _loadFriendsWithStatus() async {
    if (_currentEventId == null) return;

    // 1. Ensure friends are cached
    await _friendsRepository.fetchAndCacheFriends();

    // 2. Fetch sent invites for this specific event
    final sentInvites =
        await _invitesRepository.getSentInvitesForEvent(_currentEventId!);

    // 3. Merge friends with invite status
    final friendsWithStatus = _mergeFriendsWithStatus(
      _friendsRepository.friendsStreamValue.value,
      sentInvites,
    );

    friendsSuggestionsStreamValue.addValue(friendsWithStatus);
  }

  /// Merge friends list with invite status for the current event
  List<InviteFriendResumeWithStatus> _mergeFriendsWithStatus(
    List<InviteFriendResume> friends,
    List<SentInviteStatus> sentInvites,
  ) {
    // Create a map of friend ID -> invite status
    final inviteStatusMap = <String, SentInviteStatus>{};
    for (final invite in sentInvites) {
      inviteStatusMap[invite.friend.id] = invite;
    }

    // Map each friend to FriendResumeWithStatus
    return friends.map((friend) {
      final sentInvite = inviteStatusMap[friend.id];
      return InviteFriendResumeWithStatus(
        friend: friend,
        inviteStatus: sentInvite?.status, // null if not invited yet
      );
    }).toList();
  }

  @override
  FutureOr<void> onDispose() async {
    friendsSuggestionsStreamValue.dispose();
    selectedFriendsSuggestionsStreamValue.dispose();
  }
}
