import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';

class InvitesResponseDecoder {
  const InvitesResponseDecoder();

  List<InviteDto> decodeInviteDtos(Object? rawInvites) {
    if (rawInvites is! List) {
      return const <InviteDto>[];
    }

    final dtos = <InviteDto>[];
    for (final item in rawInvites) {
      if (item is! Map) {
        continue;
      }
      try {
        dtos.add(InviteDto.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Ignore malformed invite payload entries.
      }
    }
    return dtos;
  }

  List<InviteContactMatch> decodeContactMatches(Object? rawMatches) {
    if (rawMatches is! List) {
      return const <InviteContactMatch>[];
    }

    final dedupedByUserId = <String, InviteContactMatch>{};
    for (final item in rawMatches) {
      if (item is! Map) {
        continue;
      }
      final match = _mapInviteContactMatch(Map<String, dynamic>.from(item));
      if (match == null) {
        continue;
      }
      dedupedByUserId.putIfAbsent(match.userId, () => match);
    }

    return dedupedByUserId.values.toList(growable: false);
  }

  InviteShareCodeTargetRef decodeShareCodeTargetRef(
    Object? rawTargetRef, {
    required String fallbackEventId,
  }) {
    if (rawTargetRef is! Map) {
      return InviteShareCodeTargetRef(
        eventId: fallbackEventId,
      );
    }

    final targetRefMap = Map<String, dynamic>.from(rawTargetRef);
    final mappedEventId = _stringOrEmpty(targetRefMap['event_id']);
    return InviteShareCodeTargetRef(
      eventId: mappedEventId.isEmpty ? fallbackEventId : mappedEventId,
      occurrenceId: _stringOrNull(targetRefMap['occurrence_id']),
    );
  }

  List<String> decodeRecipientIds(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .whereType<Map>()
        .map((item) => _stringOrEmpty(item['receiver_user_id']))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, int> decodeIntMap(Object? raw) {
    if (raw is! Map) {
      return const <String, int>{};
    }
    final result = <String, int>{};
    raw.forEach((key, value) {
      final normalizedKey = key?.toString();
      if (normalizedKey == null || normalizedKey.isEmpty) {
        return;
      }
      if (value is num) {
        result[normalizedKey] = value.toInt();
        return;
      }
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        result[normalizedKey] = parsed;
      }
    });
    return result;
  }

  InviteContactMatch? _mapInviteContactMatch(Map<String, dynamic> map) {
    final userId = _stringOrEmpty(map['user_id']);
    final displayName = _stringOrEmpty(map['display_name']);
    if (userId.isEmpty || displayName.isEmpty) {
      return null;
    }

    return InviteContactMatch(
      contactHash: _stringOrEmpty(map['contact_hash']),
      type: _stringOrEmpty(map['type']),
      userId: userId,
      displayName: displayName,
      avatarUrl: _stringOrNull(map['avatar_url']),
    );
  }

  String _stringOrEmpty(Object? raw) => raw?.toString() ?? '';

  String? _stringOrNull(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}

class InviteShareCodeTargetRef {
  const InviteShareCodeTargetRef({
    required this.eventId,
    this.occurrenceId,
  });

  final String eventId;
  final String? occurrenceId;
}
