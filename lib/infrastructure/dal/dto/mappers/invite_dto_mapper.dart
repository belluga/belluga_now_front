import 'package:belluga_now/domain/invites/invite_inviter_principal.dart';
import 'package:belluga_now/domain/invites/invite_inviter.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_id_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';

mixin InviteDtoMapper {
  InviteDto parseInviteDtoJson(Map<String, dynamic> json) {
    return InviteDto.fromJson(json);
  }

  InviteDto? tryParseInviteDtoJson(Map<String, dynamic> json) {
    try {
      return parseInviteDtoJson(json);
    } catch (_) {
      return null;
    }
  }

  InviteModel mapInviteDto(InviteDto dto) {
    final inviterPrincipal = _parseInviterPrincipal(
      inviterKind: dto.inviterPrincipalKind,
      inviterId: dto.inviterPrincipalId,
    );
    final inviters = dto.inviterCandidates
        .where((candidate) => candidate.inviteId.trim().isNotEmpty)
        .map(
          (candidate) => InviteInviter(
            inviteId: candidate.inviteId,
            type:
                InviteInviterTypeApiMapper.tryParse(candidate.principalKind) ??
                    InviteInviterType.user,
            name: candidate.displayName,
            principal: _parseInviterPrincipal(
              inviterKind: candidate.principalKind,
              inviterId: candidate.principalId,
            ),
            avatarUrl: candidate.avatarUrl,
            status: candidate.status,
          ),
        )
        .toList(growable: false);

    final eventDate = DateTime.parse(dto.eventDate);

    return InviteModel.fromPrimitives(
      id: dto.id,
      eventId: dto.eventId,
      occurrenceId: dto.occurrenceId,
      eventName: dto.eventName,
      eventDateTime: eventDate,
      eventImageUrl: dto.eventImageUrl,
      location: dto.location,
      hostName: dto.hostName,
      message: dto.message,
      tags: dto.tags,
      attendancePolicy: dto.attendancePolicy,
      inviterName: dto.inviterName,
      inviterAvatarUrl: dto.inviterAvatarUrl,
      inviterPrincipal: inviterPrincipal,
      additionalInviters: dto.additionalInviters,
      inviters: inviters,
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

    final parsedType = InviteInviterTypeApiMapper.tryParse(normalizedKind);
    if (parsedType == null) return null;

    return InviteInviterPrincipal(
      type: parsedType,
      idValue: InviteInviterIdValue()..parse(normalizedId),
    );
  }
}
