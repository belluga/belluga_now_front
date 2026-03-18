import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_accepted_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_credited_acceptance_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_materialization_status_value.dart';

InviteMaterializeResult buildInviteMaterializeResult({
  required String inviteId,
  required String status,
  required bool creditedAcceptance,
  required String attendancePolicy,
  DateTime? acceptedAt,
}) {
  return InviteMaterializeResult(
    inviteIdValue: _buildInviteIdValue(inviteId),
    statusValue: _buildMaterializationStatusValue(status),
    creditedAcceptanceValue: _buildCreditedAcceptanceValue(creditedAcceptance),
    attendancePolicyValue: _buildAttendancePolicyValue(attendancePolicy),
    acceptedAtValue: _buildAcceptedAtValue(acceptedAt),
  );
}

InviteIdValue _buildInviteIdValue(String value) {
  final inviteIdValue = InviteIdValue()..parse(value);
  return inviteIdValue;
}

InviteMaterializationStatusValue _buildMaterializationStatusValue(
  String value,
) {
  final statusValue = InviteMaterializationStatusValue()..parse(value);
  return statusValue;
}

InviteCreditedAcceptanceValue _buildCreditedAcceptanceValue(bool value) {
  final creditedAcceptanceValue = InviteCreditedAcceptanceValue()
    ..parse(value.toString());
  return creditedAcceptanceValue;
}

InviteAttendancePolicyValue _buildAttendancePolicyValue(String value) {
  final attendancePolicyValue = InviteAttendancePolicyValue()..parse(value);
  return attendancePolicyValue;
}

InviteAcceptedAtValue _buildAcceptedAtValue(DateTime? value) {
  final acceptedAtValue = InviteAcceptedAtValue()
    ..parse(value?.toIso8601String());
  return acceptedAtValue;
}
