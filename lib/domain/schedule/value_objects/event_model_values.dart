import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_counterpart_count_value.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_tag_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

EventModel eventModelFromRaw({
  required MongoIDValue id,
  required SlugValue slugValue,
  required EventTypeModel type,
  required TitleValue title,
  required HTMLContentValue content,
  required DescriptionValue location,
  PartnerResume? venue,
  required ThumbModel? thumb,
  required DateTimeValue dateTimeStart,
  required DateTimeValue? dateTimeEnd,
  List<EventLinkedAccountProfile> linkedAccountProfiles = const [],
  List<EventLinkedAccountProfile> counterpartPreviewProfiles =
      const <EventLinkedAccountProfile>[],
  EventCounterpartCountValue? counterpartCountValue,
  List<EventProfileGroup> profileGroups = const [],
  List<EventOccurrenceOption> occurrences = const [],
  List<EventProgrammingItem> programmingItems = const [],
  required CityCoordinate? coordinate,
  required Object tags,
  required EventIsConfirmedValue isConfirmedValue,
  Object? confirmedAt,
  List<InviteModel>? receivedInvites,
  List<SentInviteStatus>? sentInvites,
  List<EventFriendResume>? friendsGoing,
  required EventTotalConfirmedValue totalConfirmedValue,
}) {
  return EventModel(
    id: id,
    slugValue: slugValue,
    type: type,
    title: title,
    content: content,
    location: location,
    venue: venue,
    thumb: thumb,
    dateTimeStart: dateTimeStart,
    dateTimeEnd: dateTimeEnd,
    linkedAccountProfiles: linkedAccountProfiles,
    counterpartPreviewProfiles: counterpartPreviewProfiles,
    counterpartCountValue: counterpartCountValue,
    profileGroups: profileGroups,
    occurrences: occurrences,
    programmingItems: programmingItems,
    coordinate: coordinate,
    tags: _parseTags(tags),
    isConfirmedValue: isConfirmedValue,
    confirmedAtValue: _parseConfirmedAt(confirmedAt),
    receivedInvites: receivedInvites,
    sentInvites: sentInvites,
    friendsGoing: friendsGoing,
    totalConfirmedValue: totalConfirmedValue,
  );
}

List<EventTagValue> _parseTags(Object raw) {
  if (raw is List<EventTagValue>) {
    return List<EventTagValue>.unmodifiable(raw);
  }

  if (raw is Iterable) {
    return List<EventTagValue>.unmodifiable(
      raw.map((item) {
        if (item is EventTagValue) {
          return item;
        }
        return EventTagValue(item.toString());
      }),
    );
  }

  return List<EventTagValue>.unmodifiable(<EventTagValue>[
    EventTagValue(raw.toString()),
  ]);
}

DomainOptionalDateTimeValue _parseConfirmedAt(Object? raw) {
  if (raw is DomainOptionalDateTimeValue) {
    return raw;
  }
  final value = DomainOptionalDateTimeValue();
  if (raw is DateTime) {
    value.parse(raw.toIso8601String());
    return value;
  }
  value.parse(raw?.toString());
  return value;
}
