import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_accepted_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_acceptance_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_credited_acceptance_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';

InviteAcceptResult buildInviteAcceptResult({
  required String inviteId,
  required String status,
  required bool creditedAcceptance,
  required String attendancePolicy,
  required InviteNextStep nextStep,
  required List<String> supersededInviteIds,
  DateTime? acceptedAt,
}) {
  return InviteAcceptResult(
    inviteIdValue: _buildInviteIdValue(inviteId),
    statusValue: _buildAcceptanceStatusValue(status),
    creditedAcceptanceValue: _buildCreditedAcceptanceValue(creditedAcceptance),
    attendancePolicyValue: _buildAttendancePolicyValue(attendancePolicy),
    nextStep: nextStep,
    supersededInviteIdValues:
        supersededInviteIds.map(_buildInviteIdValue).toList(growable: false),
    acceptedAtValue: _buildAcceptedAtValue(acceptedAt),
  );
}

InviteIdValue _buildInviteIdValue(String value) {
  final inviteIdValue = InviteIdValue()..parse(value);
  return inviteIdValue;
}

InviteAcceptanceStatusValue _buildAcceptanceStatusValue(String value) {
  final statusValue = InviteAcceptanceStatusValue()..parse(value);
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
