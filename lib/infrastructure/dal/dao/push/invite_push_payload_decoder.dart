import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';

class InvitePushPayloadDecoder {
  const InvitePushPayloadDecoder();

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
}
