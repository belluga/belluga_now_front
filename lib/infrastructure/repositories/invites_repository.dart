import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_invites_database.dart';
import 'package:get_it/get_it.dart';

class InvitesRepository extends InvitesRepositoryContract {
  InvitesRepository({
    MockInvitesDatabase? database,
    FriendsRepositoryContract? friendsRepository,
  })  : _database = database ?? MockInvitesDatabase(),
        _friendsRepository =
            friendsRepository ?? GetIt.I.get<FriendsRepositoryContract>();

  final MockInvitesDatabase _database;
  final FriendsRepositoryContract _friendsRepository;

  @override
  Future<List<InviteModel>> fetchInvites() async {
    final dtos = _database.invites;
    return dtos.map((dto) => InviteModel.fromDto(dto)).toList();
  }

  @override
  Future<void> sendInvites(String eventSlug, List<String> friendIds) async {
    // Fetch friends from FriendsRepository
    final allFriends = await _friendsRepository.fetchFriends();
    final now = DateTime.now();

    for (final friendId in friendIds) {
      final friend = allFriends.firstWhere(
        (f) => f.idValue.value == friendId,
        orElse: () => throw Exception('Friend not found: $friendId'),
      );

      final friendResume = _friendToEventFriendResume(friend);
      final inviteData = {
        'friend': friendResume.toJson(),
        'status': InviteStatus.pending.name,
        'sent_at': now.toIso8601String(),
      };

      _database.addSentInvite(eventSlug, inviteData);
    }

    // Update the stream to notify listeners
    final currentMap = Map<String, List<SentInviteStatus>>.from(
      sentInvitesByEventStreamValue.value,
    );
    currentMap[eventSlug] = await getSentInvitesForEvent(eventSlug);
    sentInvitesByEventStreamValue.addValue(currentMap);
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      String eventSlug) async {
    final invitesData = _database.getSentInvitesForEvent(eventSlug);
    return invitesData
        .map((data) => SentInviteStatus.fromDto(data))
        .toList(growable: false);
  }

  /// Helper to convert Friend to EventFriendResume for event context
  EventFriendResume _friendToEventFriendResume(Friend friend) {
    return EventFriendResume(
      idValue: UserIdValue()..parse(friend.idValue.value),
      displayNameValue: UserDisplayNameValue()..parse(friend.nameValue.value),
      avatarUrlValue: UserAvatarValue()
        ..parse(friend.avatarValue.value?.toString() ?? ''),
    );
  }
}
