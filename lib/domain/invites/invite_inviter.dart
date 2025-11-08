import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_partner_summary.dart';

class InviteInviter {
  const InviteInviter({
    required this.type,
    required this.name,
    this.avatarUrl,
    this.partner,
  });

  final InviteInviterType type;
  final String name;
  final String? avatarUrl;
  final InvitePartnerSummary? partner;
}
