import 'package:belluga_now/domain/invites/invite_next_step.dart';

class InviteAcceptResult {
  const InviteAcceptResult({
    required this.inviteId,
    required this.status,
    required this.creditedAcceptance,
    required this.attendancePolicy,
    required this.nextStep,
    required this.supersededInviteIds,
    this.acceptedAt,
  });

  final String inviteId;
  final String status;
  final bool creditedAcceptance;
  final String attendancePolicy;
  final InviteNextStep nextStep;
  final List<String> supersededInviteIds;
  final DateTime? acceptedAt;

  bool get isAccepted => status == 'accepted' || status == 'already_accepted';
}
