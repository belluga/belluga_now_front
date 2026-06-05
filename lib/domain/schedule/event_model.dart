export 'value_objects/event_model_values.dart';

import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/event_schedule_display.dart';
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
  final SlugValue slugValue;
  final EventTypeModel type;
  final TitleValue title;
  final HTMLContentValue content;
  final DescriptionValue location;
  final PartnerResume? venue;
  final ThumbModel? thumb;
  final DateTimeValue dateTimeStart;
  final DateTimeValue? dateTimeEnd;
  final List<EventLinkedAccountProfile> linkedAccountProfiles;
  final List<EventProfileGroup> profileGroups;
  final List<EventOccurrenceOption> occurrences;
  final List<EventProgrammingItem> programmingItems;
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
  EventModelPrimString get slug => slugValue.value;
  DateTime? get confirmedAt => confirmedAtValue.value;
  List<VenueEventTagValue> get tags =>
      List<VenueEventTagValue>.unmodifiable(tagValues);
  EventOccurrenceOption? get selectedOccurrence {
    for (final occurrence in occurrences) {
      if (occurrence.isSelected) {
        return occurrence;
      }
    }
    return occurrences.isEmpty ? null : occurrences.first;
  }

  EventModelPrimString? get selectedOccurrenceId {
    final occurrenceId = selectedOccurrence?.occurrenceId.trim();
    return occurrenceId == null || occurrenceId.isEmpty ? null : occurrenceId;
  }

  EventModelPrimBool get hasMultipleOccurrences => occurrences.length > 1;
  EventScheduleDisplay get scheduleDisplay {
    final selected = selectedOccurrence;
    if (selected != null) {
      return selected.scheduleDisplay;
    }
    return EventScheduleDisplay(
      startValue: dateTimeStart,
      endValue: dateTimeEnd,
    );
  }

  EventModelPrimString get detailScheduleLabel => scheduleDisplay.detailLabel;
  EventModelPrimString get agendaScheduleLabel => scheduleDisplay.agendaLabel;
  EventModelPrimString get flyerScheduleLabel => scheduleDisplay.flyerLabel;

  EventModelPrimBool get hasProgrammingItems => programmingItems.isNotEmpty;
  EventModelPrimBool get hasAnyProgrammingItems =>
      hasProgrammingItems ||
      occurrences.any(
        (occurrence) =>
            occurrence.programmingCount > 0 ||
            occurrence.programmingItems.isNotEmpty,
      );

  List<EventProgrammingItem> get allProgrammingItems {
    final items = <EventProgrammingItem>[
      ...programmingItems,
      for (final occurrence in occurrences) ...occurrence.programmingItems,
    ];
    return List<EventProgrammingItem>.unmodifiable(items);
  }

  List<EventLinkedAccountProfile> get counterpartProfiles {
    return List<EventLinkedAccountProfile>.unmodifiable(
      linkedAccountProfiles.where((profile) {
        final normalizedPartyType = profile.partyType?.trim().toLowerCase();
        final normalizedProfileType = profile.profileType.trim().toLowerCase();
        return normalizedPartyType != 'venue' &&
            normalizedProfileType != 'venue';
      }),
    );
  }

  bool get hasCounterparts => counterpartProfiles.isNotEmpty;

  EventLinkedAccountProfile? get primaryCounterpart =>
      hasCounterparts ? counterpartProfiles.first : null;

  EventModelPrimString get counterpartNamesLabel => counterpartProfiles
      .map((profile) => profile.displayName.trim())
      .where((name) => name.isNotEmpty)
      .join(', ');

  List<VenueEventTagValue> get taxonomyTags {
    final cleaned =
        tags.map((tag) => tag.value.trim()).where((t) => t.isNotEmpty).toSet();
    return List<VenueEventTagValue>.unmodifiable(
      cleaned.map(VenueEventTagValue.new),
    );
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
    List<EventLinkedAccountProfile> linkedAccountProfiles = const [],
    List<EventProfileGroup> profileGroups = const [],
    List<EventOccurrenceOption> occurrences = const [],
    List<EventProgrammingItem> programmingItems = const [],
    required this.coordinate,
    required List<VenueEventTagValue> tags,
    required this.isConfirmedValue,
    DomainOptionalDateTimeValue? confirmedAtValue,
    this.receivedInvites,
    this.sentInvites,
    this.friendsGoing,
    required this.totalConfirmedValue,
  })  : linkedAccountProfiles =
            List<EventLinkedAccountProfile>.unmodifiable(linkedAccountProfiles),
        profileGroups = List<EventProfileGroup>.unmodifiable(profileGroups),
        occurrences = List<EventOccurrenceOption>.unmodifiable(occurrences),
        programmingItems =
            List<EventProgrammingItem>.unmodifiable(programmingItems),
        tagValues = List<VenueEventTagValue>.unmodifiable(tags),
        confirmedAtValue = confirmedAtValue ?? DomainOptionalDateTimeValue();
}
