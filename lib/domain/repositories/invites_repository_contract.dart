import 'package:belluga_now/domain/invites/invite_friend_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';

abstract class InvitesRepositoryContract {
  Future<List<InviteModel>> fetchInvites();
  Future<List<InviteFriendModel>> fetchFriendSuggestions();
}
