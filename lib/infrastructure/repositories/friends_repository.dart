import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:stream_value/core/stream_value.dart';

/// Repository implementation for managing friends data with app-wide caching
class FriendsRepository extends FriendsRepositoryContract {
  FriendsRepository({
    List<Friend>? initialFriends,
  }) : _friends = List<Friend>.unmodifiable(initialFriends ?? const []);

  final List<Friend> _friends;

  @override
  final friendsStreamValue = StreamValue<List<InviteFriendResume>>(
    defaultValue: const [],
  );

  @override
  Future<void> fetchAndCacheFriends({bool forceRefresh = false}) async {
    // Skip if already cached and not forcing refresh
    if (!forceRefresh && friendsStreamValue.value.isNotEmpty) {
      return;
    }

    final friends = await fetchFriends();
    final friendResumes =
        friends.map(InviteFriendResume.fromFriend).toList(growable: false);

    friendsStreamValue.addValue(friendResumes);
  }

  @override
  Future<List<Friend>> fetchFriends() async {
    // Runtime uses backend-driven flows; until a dedicated friends API is added,
    // keep this repository deterministic with an empty/default list.
    return _friends;
  }
}
