import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_accepted_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_acceptance_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_credited_acceptance_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';

class InviteAcceptResult {
  InviteAcceptResult({
    required String inviteId,
    required String status,
    required bool creditedAcceptance,
    required String attendancePolicy,
    required this.nextStep,
    required List<String> supersededInviteIds,
    DateTime? acceptedAt,
  })  : inviteIdValue = _buildInviteIdValue(inviteId),
        statusValue = _buildStatusValue(status),
        creditedAcceptanceValue =
            _buildCreditedAcceptanceValue(creditedAcceptance),
        attendancePolicyValue = _buildAttendancePolicyValue(attendancePolicy),
        supersededInviteIdValues =
            _buildSupersededInviteIdValues(supersededInviteIds),
        acceptedAtValue = _buildAcceptedAtValue(acceptedAt);

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
  List<String> get supersededInviteIds => supersededInviteIdValues
      .map((inviteIdValue) => inviteIdValue.value)
      .toList(growable: false);
  DateTime? get acceptedAt => acceptedAtValue.value;

  bool get isAccepted => status == 'accepted' || status == 'already_accepted';

  static InviteIdValue _buildInviteIdValue(String rawValue) {
    final value = InviteIdValue()..parse(rawValue);
    return value;
  }

  static InviteAcceptanceStatusValue _buildStatusValue(String rawValue) {
    final value = InviteAcceptanceStatusValue()..parse(rawValue);
    return value;
  }

  static InviteCreditedAcceptanceValue _buildCreditedAcceptanceValue(
    bool rawValue,
  ) {
    final value = InviteCreditedAcceptanceValue()..parse(rawValue.toString());
    return value;
  }

  static InviteAttendancePolicyValue _buildAttendancePolicyValue(
    String rawValue,
  ) {
    final value = InviteAttendancePolicyValue()..parse(rawValue);
    return value;
  }

  static List<InviteIdValue> _buildSupersededInviteIdValues(
    List<String> rawValues,
  ) {
    return List<InviteIdValue>.unmodifiable(
      rawValues.map(_buildInviteIdValue),
    );
  }

  static InviteAcceptedAtValue _buildAcceptedAtValue(DateTime? rawValue) {
    final value = InviteAcceptedAtValue()
      ..parse(rawValue == null ? null : rawValue.toIso8601String());
    return value;
  }
}
