import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_invites_database.dart';

class InvitesRepository extends InvitesRepositoryContract {
  InvitesRepository({
    MockInvitesDatabase? database,
  }) : _database = database ?? const MockInvitesDatabase();

  final MockInvitesDatabase _database;

  @override
  Future<List<InviteModel>> fetchInvites() async {
    return _database.invites;
  }

  @override
  Future<List<Friend>> fetchFriends() async {
    return _database.friends;
  }

  @override
  Future<List<FriendResume>> fetchFriendResumes() async {
    final friends = await fetchFriends();
    return friends
        .map(FriendResume.fromFriend)
        .toList(growable: false);
  }
}
