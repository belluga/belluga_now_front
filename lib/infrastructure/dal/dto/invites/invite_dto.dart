import 'package:belluga_now/domain/invites/invite_inviter.dart';
import 'package:belluga_now/domain/invites/invite_inviter_principal.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_acceptance_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_additional_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_date_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_host_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_avatar_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_location_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_occurrence_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_tag_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_inviter_candidate_dto.dart';

class InviteDto {
  InviteDto({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.eventImageUrl,
    required this.location,
    required this.hostName,
    required this.message,
    required this.tags,
    required this.attendancePolicy,
    required this.additionalInviters,
    required this.inviterCandidates,
    this.occurrenceId,
    this.inviterName,
    this.inviterAvatarUrl,
    this.inviterPrincipalKind,
    this.inviterPrincipalId,
  });

  final String id;
  final String eventId;
  final String? occurrenceId;
  final String eventName;
  final String eventDate;
  final String eventImageUrl;
  final String location;
  final String hostName;
  final String message;
  final List<String> tags;
  final String attendancePolicy;
  final String? inviterName;
  final String? inviterAvatarUrl;
  final List<String> additionalInviters;
  final String? inviterPrincipalKind;
  final String? inviterPrincipalId;
  final List<InviteInviterCandidateDto> inviterCandidates;

  factory InviteDto.fromJson(Map<String, dynamic> json) {
    final targetRef = json['target_ref'];
    final targetRefMap = targetRef is Map<String, dynamic> ? targetRef : null;
    final inviterPrincipal = json['inviter_principal'];
    final inviterPrincipalMap =
        inviterPrincipal is Map<String, dynamic> ? inviterPrincipal : null;
    final candidatesRaw = json['inviter_candidates'];
    final candidates = <InviteInviterCandidateDto>[];

    if (candidatesRaw is List) {
      for (final item in candidatesRaw) {
        if (item is Map<String, dynamic>) {
          candidates.add(InviteInviterCandidateDto.fromJson(item));
        }
      }
    }

    final legacyInviteId = (json['id'] ?? '').toString();
    final legacyInviterName = json['inviter_name']?.toString();
    if (candidates.isEmpty &&
        legacyInviteId.isNotEmpty &&
        legacyInviterName != null &&
        legacyInviterName.trim().isNotEmpty) {
      candidates.add(
        InviteInviterCandidateDto(
          inviteId: legacyInviteId,
          displayName: legacyInviterName,
          avatarUrl: json['inviter_avatar_url']?.toString(),
          status: (json['status'] ?? 'pending').toString(),
          principalKind: inviterPrincipalMap?['kind']?.toString(),
          principalId: inviterPrincipalMap?['id']?.toString(),
        ),
      );
    }

    final eventId =
        (json['event_id'] ?? targetRefMap?['event_id'] ?? '').toString();
    final occurrenceId =
        (json['occurrence_id'] ?? targetRefMap?['occurrence_id'])?.toString();
    final id = legacyInviteId.isNotEmpty
        ? legacyInviteId
        : _groupKey(eventId, occurrenceId);

    return InviteDto(
      id: id,
      eventId: eventId,
      occurrenceId:
          occurrenceId?.trim().isEmpty == true ? null : occurrenceId?.trim(),
      eventName: (json['event_name'] ?? '').toString(),
      eventDate: (json['event_date'] ?? '').toString(),
      eventImageUrl: (json['event_image_url'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      hostName: (json['host_name'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
      attendancePolicy:
          (json['attendance_policy'] ?? 'free_confirmation_only').toString(),
      inviterName: legacyInviterName,
      inviterAvatarUrl: json['inviter_avatar_url']?.toString(),
      additionalInviters: (json['additional_inviters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
      inviterPrincipalKind: inviterPrincipalMap?['kind']?.toString(),
      inviterPrincipalId: inviterPrincipalMap?['id']?.toString(),
      inviterCandidates: candidates,
    );
  }

  Map<String, dynamic> toJson() {
    final inviterPrincipal = inviterPrincipalId == null
        ? null
        : {
            'kind': inviterPrincipalKind,
            'id': inviterPrincipalId,
          };

    return {
      'id': id,
      'target_ref': {
        'event_id': eventId,
        'occurrence_id': occurrenceId,
      },
      'event_id': eventId,
      'occurrence_id': occurrenceId,
      'event_name': eventName,
      'event_date': eventDate,
      'event_image_url': eventImageUrl,
      'location': location,
      'host_name': hostName,
      'message': message,
      'tags': tags,
      'attendance_policy': attendancePolicy,
      'inviter_name': inviterName,
      'inviter_avatar_url': inviterAvatarUrl,
      'additional_inviters': additionalInviters,
      'inviter_candidates':
          inviterCandidates.map((candidate) => candidate.toJson()).toList(),
      if (inviterPrincipal != null) 'inviter_principal': inviterPrincipal,
    };
  }

  InviteModel toDomain() {
    final inviterPrincipal = _parseInviterPrincipal(
      inviterKind: inviterPrincipalKind,
      inviterId: inviterPrincipalId,
    );
    final inviters = inviterCandidates
        .where((candidate) => candidate.inviteId.trim().isNotEmpty)
        .map((candidate) {
      final avatarValue = InviteInviterAvatarValue();
      final normalizedAvatarUrl = candidate.avatarUrl?.trim();
      if (normalizedAvatarUrl != null && normalizedAvatarUrl.isNotEmpty) {
        avatarValue.parse(normalizedAvatarUrl);
      }

      final statusValue = InviteAcceptanceStatusValue(
        defaultValue: 'pending',
        isRequired: false,
      )..parse(
          candidate.status.trim().isEmpty ? 'pending' : candidate.status,
        );

      return InviteInviter(
        inviteIdValue: InviteInviterIdValue()..parse(candidate.inviteId),
        type: InviteInviterTypeApiMapper.tryParse(candidate.principalKind) ??
            InviteInviterType.user,
        nameValue: InviteInviterNameValue()..parse(candidate.displayName),
        principal: _parseInviterPrincipal(
          inviterKind: candidate.principalKind,
          inviterId: candidate.principalId,
        ),
        avatarValue: avatarValue,
        statusValue: statusValue,
      );
    }).toList(growable: false);

    final parsedEventDate = DateTime.parse(eventDate);
    final parsedTags = tags
        .where((tag) => tag.trim().isNotEmpty)
        .map((tag) => InviteTagValue()..parse(tag))
        .toList(growable: false);
    final resolvedInviterName =
        inviterName ?? (inviters.isNotEmpty ? inviters.first.name : null);
    final resolvedInviterAvatarUrl = inviterAvatarUrl ??
        (inviters.isNotEmpty ? inviters.first.avatarUrl : null);
    final resolvedInviterPrincipal = inviterPrincipal ??
        (inviters.isNotEmpty ? inviters.first.principal : null);
    final resolvedInviters = inviters.isNotEmpty
        ? inviters
        : (resolvedInviterName != null && resolvedInviterName.trim().isNotEmpty
            ? <InviteInviter>[
                (() {
                  final avatarValue = InviteInviterAvatarValue();
                  final normalizedAvatarUrl = resolvedInviterAvatarUrl?.trim();
                  if (normalizedAvatarUrl != null &&
                      normalizedAvatarUrl.isNotEmpty) {
                    avatarValue.parse(normalizedAvatarUrl);
                  }

                  return InviteInviter(
                    inviteIdValue: InviteInviterIdValue()..parse(id),
                    type: resolvedInviterPrincipal?.type ??
                        InviteInviterType.user,
                    nameValue: InviteInviterNameValue()
                      ..parse(resolvedInviterName),
                    principal: resolvedInviterPrincipal,
                    avatarValue: avatarValue,
                  );
                })(),
              ]
            : const <InviteInviter>[]);
    final resolvedAdditionalInviters = additionalInviters.isNotEmpty
        ? additionalInviters
        : resolvedInviters
            .skip(1)
            .map((inviter) => inviter.name)
            .toList(growable: false);

    InviteInviterNameValue? inviterNameVo;
    if (resolvedInviterName != null && resolvedInviterName.trim().isNotEmpty) {
      inviterNameVo = InviteInviterNameValue()..parse(resolvedInviterName);
    }

    InviteInviterAvatarValue? inviterAvatarVo;
    if (resolvedInviterAvatarUrl != null &&
        resolvedInviterAvatarUrl.trim().isNotEmpty) {
      inviterAvatarVo = InviteInviterAvatarValue()
        ..parse(resolvedInviterAvatarUrl);
    }

    final occurrenceIdValue = InviteOccurrenceIdValue()..parse(occurrenceId);
    final attendancePolicyValue = InviteAttendancePolicyValue(
      defaultValue: 'free_confirmation_only',
    )..parse(attendancePolicy.trim().isEmpty
        ? 'free_confirmation_only'
        : attendancePolicy.trim());
    final eventImageUri = Uri.parse(eventImageUrl);

    return InviteModel(
      idValue: InviteIdValue()..parse(id),
      eventIdValue: InviteEventIdValue()..parse(eventId),
      eventNameValue: TitleValue()..parse(eventName),
      eventDateValue: InviteEventDateValue(isRequired: true)
        ..parse(parsedEventDate.toIso8601String()),
      eventImageValue: ThumbUriValue(
        defaultValue: eventImageUri,
        isRequired: true,
      )..parse(eventImageUrl),
      locationValue: InviteLocationValue()..parse(location),
      hostNameValue: InviteHostNameValue()..parse(hostName),
      messageValue: InviteMessageValue()..parse(message),
      tagValues: parsedTags,
      occurrenceIdValue: occurrenceIdValue,
      attendancePolicyValue: attendancePolicyValue,
      inviterNameValue: inviterNameVo,
      inviterAvatarValue: inviterAvatarVo,
      inviterPrincipal: resolvedInviterPrincipal,
      additionalInviterValues: resolvedAdditionalInviters
          .where((inviter) => inviter.trim().isNotEmpty)
          .map((inviter) => InviteAdditionalInviterNameValue()..parse(inviter))
          .toList(growable: false),
      inviters: resolvedInviters,
    );
  }

  static String _groupKey(String eventId, String? occurrenceId) {
    return '$eventId::${occurrenceId ?? 'event'}';
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
