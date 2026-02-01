import 'package:belluga_now/domain/invites/invite_inviter_principal.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_id_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';

mixin InviteDtoMapper {
  InviteModel mapInviteDto(InviteDto dto) {
    final inviterPrincipal = _parseInviterPrincipal(
      inviterKind: dto.inviterPrincipalKind,
      inviterId: dto.inviterPrincipalId,
    );

    final eventDate = DateTime.parse(dto.eventDate);

    return InviteModel.fromPrimitives(
      id: dto.id,
      eventId: dto.eventId,
      eventName: dto.eventName,
      eventDateTime: eventDate,
      eventImageUrl: dto.eventImageUrl,
      location: dto.location,
      hostName: dto.hostName,
      message: dto.message,
      tags: dto.tags,
      inviterName: dto.inviterName,
      inviterAvatarUrl: dto.inviterAvatarUrl,
      inviterPrincipal: inviterPrincipal,
      additionalInviters: dto.additionalInviters,
    );
  }

  InviteInviterPrincipal? _parseInviterPrincipal({
    required String? inviterKind,
    required String? inviterId,
  }) {
    final normalizedKind = inviterKind?.trim().toLowerCase();
    final normalizedId = inviterId?.trim();
    if (normalizedKind == null || normalizedKind.isEmpty) return null;
    if (normalizedId == null || normalizedId.isEmpty) return null;

    if (normalizedKind != 'user' && normalizedKind != 'partner') return null;

    return InviteInviterPrincipal(
      type: normalizedKind == 'partner'
          ? InviteInviterType.partner
          : InviteInviterType.user,
      idValue: InviteInviterIdValue()..parse(normalizedId),
    );
  }
}
