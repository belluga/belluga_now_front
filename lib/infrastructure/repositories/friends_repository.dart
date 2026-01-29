import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_invites_database.dart';
import 'package:stream_value/core/stream_value.dart';

/// Repository implementation for managing friends data with app-wide caching
class FriendsRepository extends FriendsRepositoryContract {
  FriendsRepository({
    MockInvitesDatabase? database,
  }) : _database = database ?? MockInvitesDatabase();

  final MockInvitesDatabase _database;

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
    // In production, this would call an API
    // For now, using mock database
    return _database.friends;
  }
}
