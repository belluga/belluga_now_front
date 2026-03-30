import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_tag_value.dart';
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
  required List<ArtistResume> artists,
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
    artists: artists,
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

List<VenueEventTagValue> _parseTags(Object raw) {
  if (raw is List<VenueEventTagValue>) {
    return List<VenueEventTagValue>.unmodifiable(raw);
  }

  if (raw is Iterable) {
    return List<VenueEventTagValue>.unmodifiable(
      raw.map((item) {
        if (item is VenueEventTagValue) {
          return item;
        }
        return VenueEventTagValue(item.toString());
      }),
    );
  }

  return List<VenueEventTagValue>.unmodifiable(
    <VenueEventTagValue>[VenueEventTagValue(raw.toString())],
  );
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
