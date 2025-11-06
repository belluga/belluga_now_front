import 'package:belluga_now/domain/invites/invite_friend_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
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
  Future<List<InviteFriendModel>> fetchFriendSuggestions() async {
    return _database.friends;
  }
}
