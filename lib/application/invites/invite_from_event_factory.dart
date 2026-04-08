import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_date_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_host_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_location_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_occurrence_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_tag_value.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';

final class InviteFromEventFactory {
  InviteFromEventFactory._();

  static InviteModel build({
    required EventModel event,
    required Uri fallbackImageUri,
  }) {
    final eventName = event.title.value;
    final rawEventDate = event.dateTimeStart.value;
    final eventDate = rawEventDate == null
        ? DateTime.now()
        : TimezoneConverter.utcToLocal(rawEventDate);
    final fallbackImageValue = ThumbUriValue(
      defaultValue: fallbackImageUri,
      isRequired: true,
    )..parse(fallbackImageUri.toString());
    final imageUrl = VenueEventResume.resolvePreferredImageUri(
      event,
      settingsDefaultImageValue: fallbackImageValue,
    ).toString();
    final locationLabel = event.location.value;
    final hostName = event.primaryLinkedArtist?.displayName ??
        event.venue?.displayName ??
        'Belluga Now';
    final description = stripHtml(event.content.value ?? '').trim();
    final tags = event.taxonomyTags;
    final eventId = event.id.value;
    final inviteId = eventId.isNotEmpty ? eventId : eventName;
    final parsedTags = tags.isEmpty
        ? <InviteTagValue>[InviteTagValue()..parse('belluga')]
        : tags
            .map((tag) => InviteTagValue()..parse(tag.value))
            .toList(growable: false);

    return InviteModel(
      idValue: InviteIdValue()..parse(inviteId),
      eventIdValue: InviteEventIdValue()..parse(eventId),
      eventNameValue: TitleValue()..parse(eventName),
      eventDateValue: InviteEventDateValue(isRequired: true)
        ..parse(eventDate.toIso8601String()),
      eventImageValue: ThumbUriValue(
        defaultValue: Uri.parse(imageUrl),
        isRequired: true,
      )..parse(imageUrl),
      locationValue: InviteLocationValue()..parse(locationLabel),
      hostNameValue: InviteHostNameValue()..parse(hostName),
      messageValue: InviteMessageValue()
        ..parse(description.isEmpty ? 'Partiu $eventName?' : description),
      tagValues: parsedTags,
      attendancePolicyValue: InviteAttendancePolicyValue(
        defaultValue: 'free_confirmation_only',
      )..parse('free_confirmation_only'),
      occurrenceIdValue: InviteOccurrenceIdValue()
        ..parse(event.dateTimeStart.value?.toIso8601String() ?? eventId),
    );
  }

  static String stripHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
