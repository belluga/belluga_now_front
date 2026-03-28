import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_tag_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';

import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';

typedef EventModelPrimString = String;
typedef EventModelPrimInt = int;
typedef EventModelPrimBool = bool;
typedef EventModelPrimDouble = double;
typedef EventModelPrimDynamic = dynamic;

class EventModel {
  final MongoIDValue id;
  final SlugValue slugValue; // Added slugValue
  final EventTypeModel type;
  final TitleValue title;
  final HTMLContentValue content;
  final DescriptionValue location;
  final PartnerResume? venue; // Where the event happens
  final ThumbModel? thumb;
  final DateTimeValue dateTimeStart;
  final DateTimeValue? dateTimeEnd;
  final List<ArtistResume> artists; // Keep for backward compatibility
  final CityCoordinate? coordinate;
  final List<VenueEventTagValue> tagValues;

  // Confirmation state
  final EventIsConfirmedValue isConfirmedValue;
  final DomainOptionalDateTimeValue confirmedAtValue;

  // Received invites (who invited me)
  final List<InviteModel>? receivedInvites;

  // Sent invites with status tracking
  final List<SentInviteStatus>? sentInvites;

  // Social proof
  final List<EventFriendResume>? friendsGoing;
  final EventTotalConfirmedValue totalConfirmedValue;

  EventModelPrimBool get isConfirmed => isConfirmedValue.value;
  EventModelPrimInt get totalConfirmed => totalConfirmedValue.value;
  EventModelPrimString get slug => slugValue.value; // Added getter
  DateTime? get confirmedAt => confirmedAtValue.value;
  List<EventModelPrimString> get tags =>
      tagValues.map((tagValue) => tagValue.value).toList(growable: false);
  List<EventModelPrimString> get taxonomyTags {
    final cleaned =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().toList();
    if (cleaned.isNotEmpty) return cleaned;

    final artistGenres = artists
        .expand((artist) => artist.genres)
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    return artistGenres;
  }

  EventModel({
    required this.id,
    required this.slugValue,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    this.venue,
    required this.thumb,
    required this.dateTimeStart,
    required this.dateTimeEnd,
    required this.artists,
    required this.coordinate,
    required Object tags,
    required this.isConfirmedValue,
    Object? confirmedAt,
    this.receivedInvites,
    this.sentInvites,
    this.friendsGoing,
    required this.totalConfirmedValue,
  })  : tagValues = _parseTags(tags),
        confirmedAtValue = _parseConfirmedAt(confirmedAt);

  static List<VenueEventTagValue> _parseTags(Object raw) {
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

  static DomainOptionalDateTimeValue _parseConfirmedAt(Object? raw) {
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
}
