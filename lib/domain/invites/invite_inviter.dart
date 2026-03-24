import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_inviter_principal.dart';
import 'package:belluga_now/domain/invites/invite_partner_summary.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_acceptance_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_avatar_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';

class InviteInviter {
  InviteInviter({
    required this.inviteIdValue,
    required this.type,
    required this.nameValue,
    this.principal,
    InviteInviterAvatarValue? avatarValue,
    InviteAcceptanceStatusValue? statusValue,
    this.partner,
  })  : avatarValue = avatarValue ?? InviteInviterAvatarValue(),
        statusValue = statusValue ??
            (InviteAcceptanceStatusValue(
              defaultValue: 'pending',
              isRequired: false,
            )..parse('pending'));

  final InviteInviterIdValue inviteIdValue;
  final InviteInviterType type;
  final InviteInviterNameValue nameValue;
  final InviteInviterPrincipal? principal;
  final InviteInviterAvatarValue avatarValue;
  final InviteAcceptanceStatusValue statusValue;
  final InvitePartnerSummary? partner;

  String get inviteId => inviteIdValue.value;
  String get name => nameValue.value;
  String? get avatarUrl => avatarValue.value?.toString();
  String get status => statusValue.value;
}
