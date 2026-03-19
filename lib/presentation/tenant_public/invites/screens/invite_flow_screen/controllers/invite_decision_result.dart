import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';

class InviteDecisionResult {
  const InviteDecisionResult({
    required this.invite,
    required this.queued,
    this.nextStep = InviteNextStep.none,
  });

  final InviteModel? invite;
  final bool queued;
  final InviteNextStep nextStep;
}
