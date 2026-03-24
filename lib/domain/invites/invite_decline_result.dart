import 'package:belluga_now/domain/invites/value_objects/invite_decline_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_declined_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_has_other_pending_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';

class InviteDeclineResult {
  const InviteDeclineResult({
    required this.inviteIdValue,
    required this.statusValue,
    required this.groupHasOtherPendingValue,
    this.declinedAtValue = const InviteDeclinedAtValue(),
  });

  final InviteIdValue inviteIdValue;
  final InviteDeclineStatusValue statusValue;
  final InviteHasOtherPendingValue groupHasOtherPendingValue;
  final InviteDeclinedAtValue declinedAtValue;

  String get inviteId => inviteIdValue.value;
  String get status => statusValue.value;
  bool get groupHasOtherPending => groupHasOtherPendingValue.value;
  DateTime? get declinedAt => declinedAtValue.value;

  bool get isDeclined => status == 'declined' || status == 'already_declined';
}
