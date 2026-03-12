import 'package:belluga_now/domain/invites/invite_model.dart';

class InviteDecisionResult {
  const InviteDecisionResult({
    required this.invite,
    required this.queued,
  });

  final InviteModel? invite;
  final bool queued;
}
