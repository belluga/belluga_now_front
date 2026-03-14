import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_dto_mapper.dart';

abstract class PushInvitePayloadAware {
  void applyInvitePushPayload(Map<String, Object?> payload);
}

mixin PushPayloadUpsertMixin<T> {
  List<T> upsertItems({
    required List<T> current,
    required List<T> updates,
    required String Function(T item) idResolver,
  }) {
    if (updates.isEmpty) {
      return current;
    }
    final seen = <String>{};
    final orderedUpdates = <T>[];
    for (final item in updates) {
      final id = idResolver(item);
      if (id.isEmpty || seen.contains(id)) {
        continue;
      }
      seen.add(id);
      orderedUpdates.add(item);
    }
    if (orderedUpdates.isEmpty) {
      return current;
    }
    final remaining = current.where((item) {
      final id = idResolver(item);
      return id.isNotEmpty && !seen.contains(id);
    }).toList(growable: false);
    return [
      ...orderedUpdates,
      ...remaining,
    ];
  }
}

mixin PushInvitePayloadMixin
    on PushPayloadUpsertMixin<InviteModel>, InviteDtoMapper {
  List<InviteModel> mergeInvitePayload({
    required List<InviteModel> current,
    required Map<String, Object?> payload,
  }) {
    final invites = _resolveInvitesFromPayload(payload);
    if (invites.isEmpty) {
      return current;
    }
    return upsertItems(
      current: current,
      updates: invites,
      idResolver: (invite) => invite.idValue.value,
    );
  }

  List<InviteModel> _resolveInvitesFromPayload(Map<String, Object?> payload) {
    final resolvedPayload = _resolvePayloadRoot(payload);
    final invitesRaw = resolvedPayload['invites'];
    final inviteRaw = resolvedPayload['invite'];
    final entries = <Map<String, Object?>>[];
    if (invitesRaw is List) {
      for (final item in invitesRaw) {
        if (item is Map<String, Object?>) {
          entries.add(Map<String, Object?>.from(item));
        }
      }
    }
    if (inviteRaw is Map<String, Object?>) {
      entries.add(Map<String, Object?>.from(inviteRaw));
    }
    if (entries.isEmpty) {
      return const [];
    }
    final invites = <InviteModel>[];
    for (final entry in entries) {
      final dto = _tryParseInviteDto(entry);
      if (dto == null) {
        continue;
      }
      try {
        invites.add(mapInviteDto(dto));
      } catch (_) {
        // Skip invalid payload entries.
      }
    }
    return invites;
  }

  Map<String, Object?> _resolvePayloadRoot(Map<String, Object?> payload) {
    final nested = payload['data'];
    if (nested is Map<String, Object?>) {
      return Map<String, Object?>.from(nested);
    }
    return payload;
  }

  InviteDto? _tryParseInviteDto(Map<String, Object?> entry) {
    return tryParseInviteDtoJson(entry);
  }
}
