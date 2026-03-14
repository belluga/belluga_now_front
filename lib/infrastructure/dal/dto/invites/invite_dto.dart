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

  static String _groupKey(String eventId, String? occurrenceId) {
    return '$eventId::${occurrenceId ?? 'event'}';
  }
}
