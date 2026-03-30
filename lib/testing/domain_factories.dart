import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_avatar_bytes_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_display_name_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_email_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_id_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_phone_value.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_cooldowns_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_decline_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_declined_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_has_other_pending_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_occurrence_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_rate_limits_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_share_code_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_tag_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

InviteRuntimeSettings buildInviteRuntimeSettings({
  String? tenantId,
  Map<String, int> limits = const <String, int>{},
  Map<String, int> cooldowns = const <String, int>{},
  String? overQuotaMessage,
}) {
  TenantIdValue? tenantIdValue;
  if (tenantId != null && tenantId.trim().isNotEmpty) {
    tenantIdValue = TenantIdValue()..parse(tenantId);
  }

  InviteMessageValue? overQuotaMessageValue;
  if (overQuotaMessage != null && overQuotaMessage.trim().isNotEmpty) {
    overQuotaMessageValue = InviteMessageValue()..parse(overQuotaMessage);
  }

  return InviteRuntimeSettings(
    tenantIdValue: tenantIdValue,
    limitValues: InviteRateLimitsValue(limits),
    cooldownValues: InviteCooldownsValue(cooldowns),
    overQuotaMessageValue: overQuotaMessageValue,
  );
}

InviteDeclineResult buildInviteDeclineResult({
  required String inviteId,
  required String status,
  bool groupHasOtherPending = false,
  DateTime? declinedAt,
}) {
  final inviteIdValue = InviteIdValue()..parse(inviteId);
  return InviteDeclineResult(
    inviteIdValue: inviteIdValue,
    statusValue: InviteDeclineStatusValue(status),
    groupHasOtherPendingValue: InviteHasOtherPendingValue(groupHasOtherPending),
    declinedAtValue: InviteDeclinedAtValue(declinedAt),
  );
}

InviteShareCodeResult buildInviteShareCodeResult({
  required String code,
  required String eventId,
  String? occurrenceId,
}) {
  final eventIdValue = InviteEventIdValue()..parse(eventId);
  InviteOccurrenceIdValue? occurrenceIdValue;
  if (occurrenceId != null && occurrenceId.trim().isNotEmpty) {
    occurrenceIdValue = InviteOccurrenceIdValue()..parse(occurrenceId);
  }

  return InviteShareCodeResult(
    codeValue: InviteShareCodeValue(code),
    eventIdValue: eventIdValue,
    occurrenceIdValue: occurrenceIdValue,
  );
}

ContactModel buildContactModel({
  required String id,
  required String displayName,
  List<String> phones = const <String>[],
  List<String> emails = const <String>[],
  List<int>? avatar,
}) {
  return ContactModel(
    idValue: ContactIdValue(id),
    displayNameValue: ContactDisplayNameValue(displayName),
    phoneValues: phones
        .map((phone) => ContactPhoneValue(raw: phone))
        .toList(growable: false),
    emailValues: emails
        .map((email) => ContactEmailValue(raw: email))
        .toList(growable: false),
    avatarValue: ContactAvatarBytesValue(avatar),
  );
}

VenueEventResume buildVenueEventResume({
  required String id,
  String? slug,
  required String title,
  required Uri imageUri,
  required DateTime startDateTime,
  required String location,
  List<ArtistResume> artists = const <ArtistResume>[],
  List<String> tags = const <String>[],
  CityCoordinate? coordinate,
}) {
  final parsedId = _coerceMongoId(id);
  final idValue = MongoIDValue(defaultValue: parsedId, isRequired: true)
    ..parse(parsedId);
  final slugValue = SlugValue()
    ..parse(
      slug != null && slug.trim().isNotEmpty ? slug : id,
    );
  final titleValue = TitleValue(minLenght: 1)..parse(title);
  final imageValue = ThumbUriValue(defaultValue: imageUri, isRequired: true)
    ..parse(imageUri.toString());
  final startValue = DateTimeValue(isRequired: true)
    ..parse(startDateTime.toIso8601String());
  final locationValue = DescriptionValue(minLenght: 1)..parse(location);

  return VenueEventResume(
    idValue: idValue,
    slugValue: slugValue,
    titleValue: titleValue,
    imageUriValue: imageValue,
    startDateTimeValue: startValue,
    locationValue: locationValue,
    artists: List<ArtistResume>.unmodifiable(artists),
    tagValues:
        tags.map((tag) => VenueEventTagValue(tag)).toList(growable: false),
    coordinate: coordinate,
  );
}

String _coerceMongoId(String raw) {
  final normalized = raw.trim();
  if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(normalized)) {
    return normalized;
  }
  return '000000000000000000000000';
}
