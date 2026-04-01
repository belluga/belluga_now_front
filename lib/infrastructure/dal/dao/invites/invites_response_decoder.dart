import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_accepted_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_acceptance_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_hash_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_type_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_credited_acceptance_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_avatar_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_next_step_raw_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_share_code_target_ref.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class InvitesResponseDecoder {
  const InvitesResponseDecoder();

  InviteDto decodeRequiredInviteDto(
    Object? rawInvite, {
    required String context,
  }) {
    if (rawInvite is! Map) {
      throw FormatException(
        'Malformed invite payload for $context: expected object.',
      );
    }

    try {
      final dto = InviteDto.fromJson(Map<String, dynamic>.from(rawInvite));
      _assertRequiredInviteFields(dto, context: context);
      return dto;
    } catch (error) {
      if (error is FormatException) {
        rethrow;
      }
      throw FormatException(
        'Malformed invite payload for $context: $error',
      );
    }
  }

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

  InviteAcceptResult decodeAcceptResult(Object? rawResponse) {
    final response = _asMap(rawResponse);
    return InviteAcceptResult(
      inviteIdValue: _buildInviteIdValue(_stringOrEmpty(response['invite_id'])),
      statusValue: _buildAcceptanceStatusValue(
        _stringOrEmpty(response['status']),
      ),
      creditedAcceptanceValue: _buildCreditedAcceptanceValue(
        response['credited_acceptance'] == true,
      ),
      attendancePolicyValue: _buildAttendancePolicyValue(
        _resolveAttendancePolicy(response['attendance_policy']),
      ),
      nextStep: InviteNextStepApiMapper.parse(
        InviteNextStepRawValue()..parse(response['next_step']?.toString()),
      ),
      supersededInviteIdValues: _buildInviteIdValues(
        _parseStringList(response['superseded_invite_ids']),
      ),
      acceptedAtValue: _buildAcceptedAtValue(
        _parseDateTime(response['accepted_at']),
      ),
    );
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

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
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

    final avatarValue = InviteInviterAvatarValue();
    final normalizedAvatarUrl = _stringOrNull(map['avatar_url']);
    if (normalizedAvatarUrl != null && normalizedAvatarUrl.isNotEmpty) {
      avatarValue.parse(normalizedAvatarUrl);
    }

    final contactHashValue = InviteContactHashValue();
    final contactHashRaw = _stringOrEmpty(map['contact_hash']);
    if (contactHashRaw.isNotEmpty) {
      contactHashValue.parse(contactHashRaw);
    }

    final contactTypeValue = InviteContactTypeValue();
    final contactTypeRaw = _stringOrEmpty(map['type']);
    if (contactTypeRaw.isNotEmpty) {
      contactTypeValue.parse(contactTypeRaw);
    }

    return InviteContactMatch(
      contactHashValue: contactHashValue,
      typeValue: contactTypeValue,
      userIdValue: UserIdValue()..parse(userId),
      displayNameValue: InviteInviterNameValue()..parse(displayName),
      avatarValue: avatarValue,
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

  DateTime? _parseDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    final value = raw.toString().trim();
    if (value.isEmpty) {
      return null;
    }
    return DateTimeValue().doParse(value);
  }

  String _resolveAttendancePolicy(Object? raw) {
    final value = _stringOrNull(raw);
    if (value == null || value.isEmpty) {
      return 'invite_required';
    }
    return value;
  }

  List<String> _parseStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  InviteIdValue _buildInviteIdValue(String value) {
    final inviteIdValue = InviteIdValue()..parse(value);
    return inviteIdValue;
  }

  InviteAcceptanceStatusValue _buildAcceptanceStatusValue(String value) {
    final statusValue = InviteAcceptanceStatusValue()..parse(value);
    return statusValue;
  }

  InviteCreditedAcceptanceValue _buildCreditedAcceptanceValue(bool value) {
    final creditedValue = InviteCreditedAcceptanceValue()
      ..parse(value.toString());
    return creditedValue;
  }

  InviteAttendancePolicyValue _buildAttendancePolicyValue(String value) {
    final attendancePolicyValue = InviteAttendancePolicyValue()..parse(value);
    return attendancePolicyValue;
  }

  InviteAcceptedAtValue _buildAcceptedAtValue(DateTime? value) {
    final acceptedAtValue = InviteAcceptedAtValue()
      ..parse(value?.toIso8601String());
    return acceptedAtValue;
  }

  List<InviteIdValue> _buildInviteIdValues(List<String> values) {
    return values
        .map(_buildInviteIdValue)
        .where((value) => value.value.isNotEmpty)
        .toList(growable: false);
  }

  void _assertRequiredInviteFields(
    InviteDto dto, {
    required String context,
  }) {
    if (dto.id.trim().isEmpty) {
      throw FormatException(
        'Malformed invite payload for $context: missing id.',
      );
    }
    if (dto.eventId.trim().isEmpty) {
      throw FormatException(
        'Malformed invite payload for $context: missing event_id.',
      );
    }
    if (dto.eventName.trim().isEmpty) {
      throw FormatException(
        'Malformed invite payload for $context: missing event_name.',
      );
    }
    if (dto.eventDate.trim().isEmpty) {
      throw FormatException(
        'Malformed invite payload for $context: missing event_date.',
      );
    }
    if (dto.location.trim().isEmpty) {
      throw FormatException(
        'Malformed invite payload for $context: missing location.',
      );
    }
    if (dto.hostName.trim().isEmpty) {
      throw FormatException(
        'Malformed invite payload for $context: missing host_name.',
      );
    }
    if (dto.attendancePolicy.trim().isEmpty) {
      throw FormatException(
        'Malformed invite payload for $context: missing attendance_policy.',
      );
    }
  }
}
