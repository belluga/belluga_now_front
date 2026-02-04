import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';

import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';

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
  final List<String> tags;

  // Confirmation state
  final EventIsConfirmedValue isConfirmedValue;
  final DateTime? confirmedAt;

  // Received invites (who invited me)
  final List<InviteModel>? receivedInvites;

  // Sent invites with status tracking
  final List<SentInviteStatus>? sentInvites;

  // Social proof
  final List<EventFriendResume>? friendsGoing;
  final EventTotalConfirmedValue totalConfirmedValue;

  bool get isConfirmed => isConfirmedValue.value;
  int get totalConfirmed => totalConfirmedValue.value;
  String get slug => slugValue.value; // Added getter
  List<String> get taxonomyTags {
    final cleaned = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
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
    required this.tags,
    required this.isConfirmedValue,
    this.confirmedAt,
    this.receivedInvites,
    this.sentInvites,
    this.friendsGoing,
    required this.totalConfirmedValue,
  });

}
