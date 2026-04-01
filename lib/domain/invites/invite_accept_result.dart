import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_accepted_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_acceptance_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_credited_acceptance_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';

class InviteAcceptResult {
  InviteAcceptResult({
    required this.inviteIdValue,
    required this.statusValue,
    required this.creditedAcceptanceValue,
    required this.attendancePolicyValue,
    required this.nextStep,
    required List<InviteIdValue> supersededInviteIdValues,
    required this.acceptedAtValue,
  }) : supersededInviteIdValues = List<InviteIdValue>.unmodifiable(
          supersededInviteIdValues,
        );

  final InviteIdValue inviteIdValue;
  final InviteAcceptanceStatusValue statusValue;
  final InviteCreditedAcceptanceValue creditedAcceptanceValue;
  final InviteAttendancePolicyValue attendancePolicyValue;
  final InviteNextStep nextStep;
  final List<InviteIdValue> supersededInviteIdValues;
  final InviteAcceptedAtValue acceptedAtValue;

  String get inviteId => inviteIdValue.value;
  String get status => statusValue.value;
  bool get creditedAcceptance => creditedAcceptanceValue.value;
  String get attendancePolicy => attendancePolicyValue.value;
  List<InviteIdValue> get supersededInviteIds =>
      List<InviteIdValue>.unmodifiable(supersededInviteIdValues);
  DateTime? get acceptedAt => acceptedAtValue.value;

  bool get isAccepted => status == 'accepted' || status == 'already_accepted';
}
