import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_inviter_principal.dart';
import 'package:belluga_now/domain/invites/invite_partner_summary.dart';

class InviteInviter {
  const InviteInviter({
    required this.inviteId,
    required this.type,
    required this.name,
    this.principal,
    this.avatarUrl,
    this.status = 'pending',
    this.partner,
  });

  final String inviteId;
  final InviteInviterType type;
  final String name;
  final InviteInviterPrincipal? principal;
  final String? avatarUrl;
  final String status;
  final InvitePartnerSummary? partner;
}
