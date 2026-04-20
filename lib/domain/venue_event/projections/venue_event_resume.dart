import 'package:belluga_now/domain/gamification/mission_resume.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_optional_text_value.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_tag_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

typedef VenueEventResumePrimString = String;
typedef VenueEventResumePrimInt = int;
typedef VenueEventResumePrimBool = bool;
typedef VenueEventResumePrimDouble = double;
typedef VenueEventResumePrimDateTime = DateTime;
typedef VenueEventResumePrimDynamic = dynamic;

class VenueEventResume {
  VenueEventResume({
    required this.idValue,
    required this.slugValue,
    required this.titleValue,
    required this.imageUriValue,
    required this.startDateTimeValue,
    this.endDateTimeValue,
    required this.locationValue,
    VenueEventOptionalTextValue? eventTypeLabelValue,
    VenueEventOptionalTextValue? venueTitleValue,
    required this.linkedAccountProfiles,
    required this.tagValues,
    this.coordinate,
    this.mission,
  })  : eventTypeLabelValue =
            eventTypeLabelValue ?? VenueEventOptionalTextValue(),
        venueTitleValue = venueTitleValue ?? VenueEventOptionalTextValue();

  final MongoIDValue idValue;
  final SlugValue slugValue;
  final TitleValue titleValue;
  final ThumbUriValue imageUriValue;
  final DateTimeValue startDateTimeValue;
  final DateTimeValue? endDateTimeValue;
  final DescriptionValue locationValue;
  final VenueEventOptionalTextValue eventTypeLabelValue;
  final VenueEventOptionalTextValue venueTitleValue;
  final List<EventLinkedAccountProfile> linkedAccountProfiles;
  final List<VenueEventTagValue> tagValues;
  final CityCoordinate? coordinate;
  final MissionResume? mission;
  static final Uri _localPlaceholderUri =
      Uri.parse('asset://event-placeholder');

  VenueEventResumePrimString get id => idValue.value;
  VenueEventResumePrimString get slug => slugValue.value;
  VenueEventResumePrimString get title => titleValue.value;
  Uri get imageUri => imageUriValue.value;
  VenueEventResumePrimDateTime get startDateTime {
    final date = startDateTimeValue.value;
    if (date == null) {
      throw StateError('startDateTime should not be null');
    }
    return TimezoneConverter.utcToLocal(date);
  }

  VenueEventResumePrimDateTime? get endDateTime {
    final date = endDateTimeValue?.value;
    if (date == null) {
      return null;
    }
    return TimezoneConverter.utcToLocal(date);
  }

  VenueEventResumePrimString get location => locationValue.value;
  VenueEventResumePrimString? get eventTypeLabel {
    final value = eventTypeLabelValue.value.trim();
    return value.isEmpty ? null : value;
  }

  VenueEventResumePrimString? get venueTitle {
    final value = venueTitleValue.value.trim();
    return value.isEmpty ? null : value;
  }

  CityCoordinate? get coordinateValue => coordinate;
  List<EventLinkedAccountProfile> get counterpartProfiles =>
      List<EventLinkedAccountProfile>.unmodifiable(
        linkedAccountProfiles.where((profile) {
          final partyType = profile.partyType?.trim().toLowerCase();
          final profileType = profile.profileType.trim().toLowerCase();
          return partyType != 'venue' && profileType != 'venue';
        }),
      );
  VenueEventResumePrimBool get hasCounterparts =>
      counterpartProfiles.isNotEmpty;
  EventLinkedAccountProfile? get primaryCounterpart =>
      hasCounterparts ? counterpartProfiles.first : null;
  List<VenueEventTagValue> get tags =>
      List<VenueEventTagValue>.unmodifiable(tagValues);
  VenueEventResumePrimString get counterpartNamesLabel => counterpartProfiles
      .map((profile) => profile.displayName.trim())
      .where((name) => name.isNotEmpty)
      .join(', ');

  static VenueEventResumePrimString slugify(TitleValue value) {
    final rawValue = value.value;
    final slug = rawValue.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static Uri resolvePreferredImageUri(
    EventModel event, {
    ThumbUriValue? settingsDefaultImageValue,
  }) {
    final eventCover = event.thumb?.thumbUri.value;
    if (eventCover != null) {
      return eventCover;
    }

    for (final profile in event.linkedAccountProfiles) {
      if (_isVenueRelatedProfile(profile)) {
        continue;
      }

      final relatedCover = profile.coverUrl?.trim();
      if (relatedCover != null && relatedCover.isNotEmpty) {
        return Uri.parse(relatedCover);
      }

      final relatedAvatar = profile.avatarUrl?.trim();
      if (relatedAvatar != null && relatedAvatar.isNotEmpty) {
        return Uri.parse(relatedAvatar);
      }
    }

    final hostCover = event.venue?.heroImageUri ?? event.venue?.logoImageUri;
    if (hostCover != null) {
      return hostCover;
    }

    if (settingsDefaultImageValue != null &&
        settingsDefaultImageValue.value.toString().trim().isNotEmpty) {
      return settingsDefaultImageValue.value;
    }

    return _localPlaceholderUri;
  }

  static bool _isVenueRelatedProfile(EventLinkedAccountProfile profile) {
    final partyType = profile.partyType?.trim().toLowerCase();
    if (partyType == 'venue') {
      return true;
    }

    final profileType = profile.profileType.trim().toLowerCase();
    return profileType == 'venue';
  }

  factory VenueEventResume.fromScheduleEvent(
    EventModel event,
    ThumbUriValue fallbackImageValue,
  ) {
    final slugSource = event.slug;
    final slug = SlugValue()
      ..parse(
        slugSource.isNotEmpty
            ? slugSource
            : VenueEventResume.slugify(event.title),
      );

    final preferredImageUri = resolvePreferredImageUri(
      event,
      settingsDefaultImageValue: fallbackImageValue,
    );
    final thumb =
        ThumbUriValue(defaultValue: preferredImageUri, isRequired: true)
          ..parse(preferredImageUri.toString());

    final startDateTime = event.dateTimeStart.value;
    if (startDateTime == null) {
      throw StateError('EventModel.dateTimeStart must be defined');
    }

    final startValue = DateTimeValue(isRequired: true)
      ..parse(startDateTime.toIso8601String());
    final endDateTime = event.dateTimeEnd?.value;
    final endValue = endDateTime == null
        ? null
        : (DateTimeValue(isRequired: true)
          ..parse(endDateTime.toIso8601String()));

    return VenueEventResume(
      idValue: event.id,
      slugValue: slug,
      titleValue: event.title,
      imageUriValue: thumb,
      startDateTimeValue: startValue,
      endDateTimeValue: endValue,
      locationValue: event.location,
      eventTypeLabelValue: VenueEventOptionalTextValue()
        ..parse(event.type.name.value),
      venueTitleValue: VenueEventOptionalTextValue()
        ..parse(event.venue?.displayName ?? ''),
      linkedAccountProfiles: event.linkedAccountProfiles,
      tagValues: event.taxonomyTags,
      coordinate: event.coordinate,
      mission: null, // TODO: Map from EventModel when available
    );
  }
}
