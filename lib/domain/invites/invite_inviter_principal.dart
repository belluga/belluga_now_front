import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_id_value.dart';

class InviteInviterPrincipal {
  InviteInviterPrincipal({
    required this.type,
    required this.idValue,
  });

  final InviteInviterType type;
  final InviteInviterIdValue idValue;

  String get id => idValue.value;
}
