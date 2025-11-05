import 'package:belluga_now/domain/invites/invite_friend_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class InvitesRepositoryContract {

  final pendingInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const []);

  bool get hasPendingInvites => pendingInvitesStreamValue.value.isNotEmpty;

  Future<void> init() async{
    final _invites = await fetchInvites();
    pendingInvitesStreamValue.addValue(_invites);
  }

  Future<List<InviteModel>> fetchInvites();
  Future<List<InviteFriendModel>> fetchFriendSuggestions();
}
