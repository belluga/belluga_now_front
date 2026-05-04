import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_share_code_value.dart';

class InviteShareSessionContext {
  const InviteShareSessionContext({
    required this.shareCodeValue,
    required this.invite,
  });

  final InviteShareCodeValue shareCodeValue;
  final InviteModel invite;

  String get shareCode => shareCodeValue.value;
  String get eventId => invite.eventId;
  String? get occurrenceId => invite.occurrenceId;

  bool matchesInviteId(InviteIdValue inviteIdValue) {
    if (invite.idValue.value == inviteIdValue.value ||
        invite.primaryInviteId == inviteIdValue.value) {
      return true;
    }
    return invite.containsInviteId(inviteIdValue);
  }
}
