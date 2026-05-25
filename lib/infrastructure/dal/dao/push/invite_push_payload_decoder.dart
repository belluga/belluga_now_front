import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';
import 'package:belluga_now/infrastructure/dal/dao/push/invite_accepted_push_payload.dart';

class InvitePushPayloadDecoder {
  const InvitePushPayloadDecoder();

  InviteAcceptedPushPayload? decodeAcceptedSentInvite(Object? rawPayload) {
    final payloadRoot = _resolvePayloadRoot(rawPayload);
    final pushType = _string(payloadRoot['push_type']) ??
        _string(payloadRoot['event']);
    if (pushType != 'invite_accepted') {
      return null;
    }

    final occurrenceId = _string(payloadRoot['occurrence_id']);
    if (occurrenceId == null) {
      return null;
    }

    final accountProfileId =
        _string(payloadRoot['accepted_by_account_profile_id']) ??
            _string(payloadRoot['receiver_account_profile_id']);
    final userId = _string(payloadRoot['accepted_by_user_id']) ??
        _string(payloadRoot['receiver_user_id']);
    if (accountProfileId == null && userId == null) {
      return null;
    }

    return InviteAcceptedPushPayload(
      occurrenceId: occurrenceId,
      eventId: _string(payloadRoot['event_id']),
      accountProfileId: accountProfileId,
      userId: userId,
      displayName: _string(payloadRoot['accepted_by_display_name']) ??
          _string(payloadRoot['display_name']),
      avatarUrl: _string(payloadRoot['accepted_by_avatar_url']) ??
          _string(payloadRoot['avatar_url']),
    );
  }

  List<InviteDto> decodeInviteDtos(Object? rawPayload) {
    final payloadRoot = _resolvePayloadRoot(rawPayload);
    final invitesRaw = payloadRoot['invites'];
    final inviteRaw = payloadRoot['invite'];

    final entries = <Map<String, dynamic>>[];
    if (invitesRaw is List) {
      for (final item in invitesRaw) {
        if (item is Map) {
          entries.add(Map<String, dynamic>.from(item));
        }
      }
    }
    if (inviteRaw is Map) {
      entries.add(Map<String, dynamic>.from(inviteRaw));
    }
    if (entries.isEmpty) {
      return const <InviteDto>[];
    }

    final dtos = <InviteDto>[];
    for (final entry in entries) {
      try {
        final dto = InviteDto.fromJson(entry);
        if (dto.eventId.trim().isEmpty || dto.occurrenceId.trim().isEmpty) {
          continue;
        }
        dtos.add(dto);
      } catch (_) {
        // Ignore malformed invite entries from push payloads.
      }
    }
    return dtos;
  }

  Map<String, dynamic> _resolvePayloadRoot(Object? rawPayload) {
    if (rawPayload is! Map) {
      return const <String, dynamic>{};
    }
    final payload = Map<String, dynamic>.from(rawPayload);
    final nested = payload['data'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return payload;
  }

  String? _string(Object? value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}
