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

InviteModel buildInviteModelFromPrimitives({
  required String id,
  required String eventId,
  required String eventName,
  required DateTime eventDateTime,
  required String eventImageUrl,
  required String location,
  required String hostName,
  required String message,
  required List<String> tags,
  String? occurrenceId,
  String attendancePolicy = 'free_confirmation_only',
  String? inviterName,
  String? inviterAvatarUrl,
  InviteInviterPrincipal? inviterPrincipal,
  List<String> additionalInviters = const [],
  List<InviteInviter> inviters = const [],
}) {
  final eventImageUri = Uri.parse(eventImageUrl);
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
                  type:
                      resolvedInviterPrincipal?.type ?? InviteInviterType.user,
                  nameValue: InviteInviterNameValue()
                    ..parse(resolvedInviterName),
                  principal: resolvedInviterPrincipal,
                  avatarValue: avatarValue,
                  statusValue: InviteAcceptanceStatusValue(
                    defaultValue: 'pending',
                    isRequired: false,
                  )..parse('pending'),
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
  )..parse(
      attendancePolicy.trim().isEmpty
          ? 'free_confirmation_only'
          : attendancePolicy.trim(),
    );

  return InviteModel(
    idValue: InviteIdValue()..parse(id),
    eventIdValue: InviteEventIdValue()..parse(eventId),
    eventNameValue: TitleValue()..parse(eventName),
    eventDateValue: InviteEventDateValue(isRequired: true)
      ..parse(eventDateTime.toIso8601String()),
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
