import 'package:belluga_now/domain/invites/value_objects/invite_accepted_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_credited_acceptance_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_materialization_status_value.dart';

class InviteMaterializeResult {
  InviteMaterializeResult({
    required this.inviteIdValue,
    required this.statusValue,
    required this.creditedAcceptanceValue,
    required this.attendancePolicyValue,
    required this.acceptedAtValue,
  });

  final InviteIdValue inviteIdValue;
  final InviteMaterializationStatusValue statusValue;
  final InviteCreditedAcceptanceValue creditedAcceptanceValue;
  final InviteAttendancePolicyValue attendancePolicyValue;
  final InviteAcceptedAtValue acceptedAtValue;

  String get inviteId => inviteIdValue.value;
  String get status => statusValue.value;
  bool get creditedAcceptance => creditedAcceptanceValue.value;
  String get attendancePolicy => attendancePolicyValue.value;
  DateTime? get acceptedAt => acceptedAtValue.value;

  bool get isPending => status == 'pending';
}
