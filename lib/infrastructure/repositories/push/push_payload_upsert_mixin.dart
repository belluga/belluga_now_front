import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/push/invite_push_payload_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_dto_mapper.dart';

abstract class PushInvitePayloadAware {
  void applyInvitePushPayload(Object? payload);
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
  final InvitePushPayloadDecoder _payloadDecoder =
      const InvitePushPayloadDecoder();

  List<InviteModel> mergeInvitePayload({
    required List<InviteModel> current,
    required Object? payload,
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

  List<InviteModel> _resolveInvitesFromPayload(Object? payload) {
    final dtos = _payloadDecoder.decodeInviteDtos(payload);
    if (dtos.isEmpty) {
      return const <InviteModel>[];
    }

    final invites = <InviteModel>[];
    for (final dto in dtos) {
      try {
        invites.add(mapInviteDto(dto));
      } catch (_) {
        // Skip invalid payload entries.
      }
    }
    return invites;
  }
}
