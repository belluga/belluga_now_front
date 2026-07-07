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
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_type_raw_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_location_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_occurrence_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_tag_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_inviter_candidate_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_public_profile_payload_decoder.dart';

class InviteDto {
  static final Uri _transparentPixelUri = Uri.parse(
    'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==',
  );

  InviteDto({
    required this.id,
    required this.eventId,
    required this.eventSlug,
    required this.eventName,
    required this.eventDate,
    required this.eventImageUrl,
    required this.location,
    required this.hostName,
    required this.message,
    required this.tags,
    this.taxonomyTerms = const [],
    required this.attendancePolicy,
    required this.additionalInviters,
    required this.inviterCandidates,
    required this.occurrenceId,
    this.linkedAccountProfiles = const [],
    this.profileGroups = const [],
    this.venueAccountProfileId,
    this.inviterName,
    this.inviterAvatarUrl,
    this.inviterPrincipalKind,
    this.inviterPrincipalId,
  });

  final String id;
  final String eventId;
  final String eventSlug;
  final String occurrenceId;
  final String eventName;
  final String eventDate;
  final String eventImageUrl;
  final String location;
  final String hostName;
  final String message;
  final List<String> tags;
  final List<Map<String, dynamic>> taxonomyTerms;
  final String attendancePolicy;
  final List<EventLinkedAccountProfile> linkedAccountProfiles;
  final List<EventProfileGroup> profileGroups;
  final String? venueAccountProfileId;
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
    final inviterPrincipalMap = inviterPrincipal is Map<String, dynamic>
        ? inviterPrincipal
        : null;
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

    final eventId = (json['event_id'] ?? targetRefMap?['event_id'] ?? '')
        .toString();
    final occurrenceId =
        (json['occurrence_id'] ?? targetRefMap?['occurrence_id'] ?? '')
            .toString()
            .trim();
    final linkedAccountProfiles =
        EventPublicProfilePayloadDecoder.resolveLinkedAccountProfiles(
          linkedProfilesRaw: json['linked_account_profiles'],
        );
    final profileGroups = EventPublicProfilePayloadDecoder.resolveProfileGroups(
      json['profile_groups'],
      linkedAccountProfiles: linkedAccountProfiles,
    );
    final id = legacyInviteId.isNotEmpty
        ? legacyInviteId
        : _groupKey(eventId, occurrenceId);

    final taxonomyTerms = _resolveCanonicalTaxonomyTerms(
      json['taxonomy_terms'],
    );

    return InviteDto(
      id: id,
      eventId: eventId,
      eventSlug: (json['event_slug'] ?? '').toString(),
      occurrenceId: occurrenceId,
      eventName: (json['event_name'] ?? '').toString(),
      eventDate: (json['event_date'] ?? '').toString(),
      eventImageUrl: (json['event_image_url'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      hostName: (json['host_name'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      tags: _resolveCanonicalTaxonomyLabels(taxonomyTerms),
      taxonomyTerms: taxonomyTerms,
      attendancePolicy: (json['attendance_policy'] ?? 'free_confirmation_only')
          .toString(),
      linkedAccountProfiles: linkedAccountProfiles,
      profileGroups: profileGroups,
      venueAccountProfileId: json['venue_account_profile_id']?.toString(),
      inviterName: legacyInviterName,
      inviterAvatarUrl: json['inviter_avatar_url']?.toString(),
      additionalInviters:
          (json['additional_inviters'] as List<dynamic>?)
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
        : {'kind': inviterPrincipalKind, 'id': inviterPrincipalId};

    return {
      'id': id,
      'target_ref': {'event_id': eventId, 'occurrence_id': occurrenceId},
      'event_id': eventId,
      'event_slug': eventSlug,
      'occurrence_id': occurrenceId,
      'event_name': eventName,
      'event_date': eventDate,
      'event_image_url': eventImageUrl,
      'location': location,
      'host_name': hostName,
      'message': message,
      'taxonomy_terms': taxonomyTerms
          .map((term) => Map<String, dynamic>.from(term))
          .toList(growable: false),
      'attendance_policy': attendancePolicy,
      'linked_account_profiles': linkedAccountProfiles
          .map(
            (profile) => <String, dynamic>{
              'id': profile.id,
              'display_name': profile.displayName,
              'profile_type': profile.profileType,
              'slug': profile.slug,
              'avatar_url': profile.avatarUrl,
              'cover_url': profile.coverUrl,
              'party_type': profile.partyType,
              'location_address': profile.locationAddress,
              'latitude': profile.locationLat,
              'longitude': profile.locationLng,
              'can_open_public_detail': profile.canOpenPublicDetail,
              'public_detail_path': profile.publicDetailPath,
              'taxonomy_terms': profile.taxonomyTerms.items
                  .map(
                    (term) => <String, dynamic>{
                      'type': term.typeValue.value,
                      'value': term.valueValue.value,
                      'name': term.nameValue.value,
                      'taxonomy_name': term.taxonomyNameValue.value,
                      'label': term.labelValue.value,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
      'profile_groups': profileGroups
          .map(
            (group) => <String, dynamic>{
              'id': group.id,
              'label': group.label,
              'order': group.order,
              'account_profile_ids': group.accountProfileIdValues
                  .map((id) => id.value)
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
      'venue_account_profile_id': venueAccountProfileId,
      'inviter_name': inviterName,
      'inviter_avatar_url': inviterAvatarUrl,
      'additional_inviters': additionalInviters,
      'inviter_candidates': inviterCandidates
          .map((candidate) => candidate.toJson())
          .toList(),
      'inviter_principal': ?inviterPrincipal,
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

          final statusValue =
              InviteAcceptanceStatusValue(
                defaultValue: 'pending',
                isRequired: false,
              )..parse(
                candidate.status.trim().isEmpty ? 'pending' : candidate.status,
              );

          return InviteInviter(
            inviteIdValue: InviteInviterIdValue()..parse(candidate.inviteId),
            type:
                InviteInviterTypeApiMapper.tryParse(
                  InviteInviterTypeRawValue()..parse(candidate.principalKind),
                ) ??
                InviteInviterType.user,
            nameValue: InviteInviterNameValue()..parse(candidate.displayName),
            principal: _parseInviterPrincipal(
              inviterKind: candidate.principalKind,
              inviterId: candidate.principalId,
            ),
            avatarValue: avatarValue,
            statusValue: statusValue,
          );
        })
        .toList(growable: false);

    final parsedEventDate = DateTime.parse(eventDate);
    final parsedTags = tags
        .where((tag) => tag.trim().isNotEmpty)
        .map((tag) => InviteTagValue()..parse(tag))
        .toList(growable: false);
    final resolvedInviterName =
        inviterName ?? (inviters.isNotEmpty ? inviters.first.name : null);
    final resolvedInviterAvatarUrl =
        inviterAvatarUrl ??
        (inviters.isNotEmpty ? inviters.first.avatarUrl : null);
    final resolvedInviterPrincipal =
        inviterPrincipal ??
        (inviters.isNotEmpty ? inviters.first.principal : null);
    final resolvedInviters = inviters.isNotEmpty
        ? inviters
        : (resolvedInviterName != null && resolvedInviterName.trim().isNotEmpty
              ? <InviteInviter>[
                  (() {
                    final avatarValue = InviteInviterAvatarValue();
                    final normalizedAvatarUrl = resolvedInviterAvatarUrl
                        ?.trim();
                    if (normalizedAvatarUrl != null &&
                        normalizedAvatarUrl.isNotEmpty) {
                      avatarValue.parse(normalizedAvatarUrl);
                    }

                    return InviteInviter(
                      inviteIdValue: InviteInviterIdValue()..parse(id),
                      type:
                          resolvedInviterPrincipal?.type ??
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
    final attendancePolicyValue =
        InviteAttendancePolicyValue(defaultValue: 'free_confirmation_only')
          ..parse(
            attendancePolicy.trim().isEmpty
                ? 'free_confirmation_only'
                : attendancePolicy.trim(),
          );
    final eventImageUri = _resolveEventImageUri(
      eventImageUrl: eventImageUrl,
      linkedAccountProfiles: linkedAccountProfiles,
    );

    return InviteModel(
      idValue: InviteIdValue()..parse(id),
      eventIdValue: InviteEventIdValue()..parse(eventId),
      eventSlugValue: _eventSlugValueOrNull(eventSlug),
      eventNameValue: TitleValue()..parse(eventName),
      eventDateValue: InviteEventDateValue(isRequired: true)
        ..parse(parsedEventDate.toIso8601String()),
      eventImageValue: ThumbUriValue(
        defaultValue: eventImageUri,
        isRequired: true,
      )..parse(eventImageUri.toString()),
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
      linkedAccountProfiles: linkedAccountProfiles,
      profileGroups: profileGroups,
      venueAccountProfileIdValue:
          venueAccountProfileId == null || venueAccountProfileId!.trim().isEmpty
          ? null
          : EventLinkedAccountProfileTextValue(venueAccountProfileId!.trim()),
    );
  }

  static String _groupKey(String eventId, String occurrenceId) {
    return '$eventId::$occurrenceId';
  }

  static List<String> _resolveCanonicalTaxonomyLabels(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }

    final labels = <String>{};
    for (final entry in raw) {
      if (entry is! Map) {
        continue;
      }
      final label = (entry['name'] ?? entry['label'] ?? entry['value'] ?? '')
          .toString()
          .trim();
      if (label.isEmpty) {
        continue;
      }
      labels.add(label);
    }

    return List<String>.unmodifiable(labels);
  }

  static List<Map<String, dynamic>> _resolveCanonicalTaxonomyTerms(
    Object? raw,
  ) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }

    final terms = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is Map<String, dynamic>) {
        terms.add(Map<String, dynamic>.unmodifiable(entry));
        continue;
      }

      if (entry is Map) {
        terms.add(
          Map<String, dynamic>.unmodifiable(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      }
    }

    return List<Map<String, dynamic>>.unmodifiable(terms);
  }

  static SlugValue? _eventSlugValueOrNull(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return SlugValue()..parse(normalized);
  }

  static Uri _resolveEventImageUri({
    required String eventImageUrl,
    required List<EventLinkedAccountProfile> linkedAccountProfiles,
  }) {
    final direct = _tryAbsoluteUri(eventImageUrl);
    if (direct != null) {
      return direct;
    }

    for (final profile in linkedAccountProfiles) {
      final cover = _tryAbsoluteUri(profile.coverUrl);
      if (cover != null) {
        return cover;
      }
      final avatar = _tryAbsoluteUri(profile.avatarUrl);
      if (avatar != null) {
        return avatar;
      }
    }

    return _transparentPixelUri;
  }

  static Uri? _tryAbsoluteUri(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(normalized);
    if (parsed == null || !parsed.isAbsolute) {
      return null;
    }
    return parsed;
  }

  InviteInviterPrincipal? _parseInviterPrincipal({
    required String? inviterKind,
    required String? inviterId,
  }) {
    final normalizedKind = inviterKind?.trim().toLowerCase();
    final normalizedId = inviterId?.trim();
    if (normalizedKind == null || normalizedKind.isEmpty) return null;
    if (normalizedId == null || normalizedId.isEmpty) return null;

    final parsedType = InviteInviterTypeApiMapper.tryParse(
      InviteInviterTypeRawValue()..parse(normalizedKind),
    );
    if (parsedType == null) return null;

    return InviteInviterPrincipal(
      type: parsedType,
      idValue: InviteInviterIdValue()..parse(normalizedId),
    );
  }
}
