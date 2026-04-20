import 'package:belluga_now/application/time/timezone_converter.dart';
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
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/partners/projections/value_objects/partner_projection_text_values.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_optional_text_value.dart';
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

PartnerEventView buildPartnerEventView({
  required String eventId,
  String? occurrenceId,
  String? slug,
  required String title,
  String? eventTypeLabel,
  DateTime? startDateTime,
  DateTime? endDateTime,
  required String location,
  String? venueId,
  String? venueTitle,
  Uri? imageUri,
  List<String> artistNames = const <String>[],
  List<String> artistIds = const <String>[],
}) {
  final normalizedEventId = _coerceMongoId(eventId);
  final normalizedOccurrenceId =
      _coerceMongoId(occurrenceId ?? normalizedEventId);
  final resolvedStart =
      startDateTime ?? TimezoneConverter.localToUtc(DateTime.now());
  final startValue = DateTimeValue(isRequired: true)
    ..parse(resolvedStart.toIso8601String());
  final endValue = endDateTime == null
      ? null
      : (DateTimeValue(isRequired: true)..parse(endDateTime.toIso8601String()));
  ThumbUriValue? imageValue;
  if (imageUri != null) {
    imageValue = ThumbUriValue(defaultValue: imageUri, isRequired: true)
      ..parse(imageUri.toString());
  }

  return PartnerEventView(
    eventIdValue:
        MongoIDValue(defaultValue: normalizedEventId, isRequired: true)
          ..parse(normalizedEventId),
    occurrenceIdValue:
        MongoIDValue(defaultValue: normalizedOccurrenceId, isRequired: true)
          ..parse(normalizedOccurrenceId),
    slugValue: SlugValue()..parse(slug ?? normalizedEventId),
    titleValue: partnerProjectionRequiredText(title),
    eventTypeLabelValue: eventTypeLabel == null
        ? null
        : partnerProjectionOptionalText(eventTypeLabel),
    startDateTimeValue: startValue,
    endDateTimeValue: endValue,
    locationValue: partnerProjectionRequiredText(location),
    venueIdValue: venueId == null
        ? null
        : (MongoIDValue(defaultValue: _coerceMongoId(venueId), isRequired: true)
          ..parse(_coerceMongoId(venueId))),
    venueTitleValue:
        venueTitle == null ? null : partnerProjectionOptionalText(venueTitle),
    imageUriValue: imageValue,
    linkedAccountProfiles: artistNames
        .asMap()
        .entries
        .map(
          (entry) => PartnerSupportedEntityView(
            idValue: entry.key < artistIds.length
                ? (MongoIDValue(
                    defaultValue: _coerceMongoId(artistIds[entry.key]),
                    isRequired: true,
                  )..parse(_coerceMongoId(artistIds[entry.key])))
                : null,
            titleValue: partnerProjectionRequiredText(entry.value),
          ),
        )
        .toList(growable: false),
  );
}

VenueEventResume buildVenueEventResume({
  required String id,
  String? slug,
  required String title,
  required Uri imageUri,
  required DateTime startDateTime,
  DateTime? endDateTime,
  required String location,
  String? eventTypeLabel,
  String? venueTitle,
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
  final endValue = endDateTime == null
      ? null
      : (DateTimeValue(isRequired: true)..parse(endDateTime.toIso8601String()));
  final locationValue = DescriptionValue(minLenght: 1)..parse(location);
  final eventTypeValue = VenueEventOptionalTextValue()
    ..parse(eventTypeLabel ?? '');
  final venueTitleValue = VenueEventOptionalTextValue()
    ..parse(venueTitle ?? '');
  final linkedAccountProfiles = _artistResumesToLinkedProfiles(artists);

  return VenueEventResume(
    idValue: idValue,
    slugValue: slugValue,
    titleValue: titleValue,
    imageUriValue: imageValue,
    startDateTimeValue: startValue,
    endDateTimeValue: endValue,
    locationValue: locationValue,
    eventTypeLabelValue: eventTypeValue,
    venueTitleValue: venueTitleValue,
    linkedAccountProfiles: linkedAccountProfiles,
    tagValues:
        tags.map((tag) => VenueEventTagValue(tag)).toList(growable: false),
    coordinate: coordinate,
  );
}

List<EventLinkedAccountProfile> _artistResumesToLinkedProfiles(
  List<ArtistResume> artists,
) {
  final linkedProfiles = <EventLinkedAccountProfile>[];
  for (final artist in artists) {
    final id = artist.id.trim();
    final displayName = artist.displayName.trim();
    if (id.isEmpty || displayName.isEmpty) {
      continue;
    }

    final taxonomyTerms = EventLinkedAccountProfileTaxonomyTerms();
    for (final genre in artist.genres) {
      final value = genre.value.trim();
      if (value.isEmpty) continue;
      taxonomyTerms.addTerm(
        typeValue: AccountProfileTagValue('genre'),
        valueValue: AccountProfileTagValue(value),
        nameValue: AccountProfileTagValue(value),
      );
    }

    final avatar = artist.avatarUri?.toString().trim();
    linkedProfiles.add(
      EventLinkedAccountProfile(
        idValue: EventLinkedAccountProfileTextValue(id),
        displayNameValue: EventLinkedAccountProfileTextValue(displayName),
        profileTypeValue: AccountProfileTypeValue('artist'),
        slugValue: SlugValue()..parse(id),
        avatarUrlValue: avatar == null || avatar.isEmpty
            ? null
            : (ThumbUriValue(defaultValue: Uri.parse(avatar), isRequired: true)
              ..parse(avatar)),
        taxonomyTerms: taxonomyTerms,
      ),
    );
  }

  return List<EventLinkedAccountProfile>.unmodifiable(linkedProfiles);
}

String _coerceMongoId(String raw) {
  final normalized = raw.trim();
  if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(normalized)) {
    return normalized;
  }
  return '000000000000000000000000';
}
