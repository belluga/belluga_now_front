import 'package:belluga_now/domain/gamification/mission_resume.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/event_schedule_display.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_counterpart_count_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_optional_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_tag_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

typedef UpcomingOcurrenceResumePrimString = String;
typedef UpcomingOcurrenceResumePrimInt = int;
typedef UpcomingOcurrenceResumePrimBool = bool;
typedef UpcomingOcurrenceResumePrimDouble = double;
typedef UpcomingOcurrenceResumePrimDateTime = DateTime;
typedef UpcomingOcurrenceResumePrimDynamic = dynamic;

class UpcomingOcurrenceResume {
  UpcomingOcurrenceResume({
    required this.idValue,
    required this.slugValue,
    required this.titleValue,
    required this.imageUriValue,
    required this.startDateTimeValue,
    this.endDateTimeValue,
    required this.locationValue,
    EventOptionalTextValue? eventTypeLabelValue,
    EventOptionalTextValue? venueTitleValue,
    EventOptionalTextValue? selectedOccurrenceIdValue,
    this.counterpartCountValue,
    this.venueIdValue,
    required this.linkedAccountProfiles,
    required this.tagValues,
    this.coordinate,
    this.mission,
  }) : eventTypeLabelValue = eventTypeLabelValue ?? EventOptionalTextValue(),
       venueTitleValue = venueTitleValue ?? EventOptionalTextValue(),
       selectedOccurrenceIdValue =
           selectedOccurrenceIdValue ?? EventOptionalTextValue();

  final MongoIDValue idValue;
  final SlugValue slugValue;
  final TitleValue titleValue;
  final ThumbUriValue imageUriValue;
  final DateTimeValue startDateTimeValue;
  final DateTimeValue? endDateTimeValue;
  final DescriptionValue locationValue;
  final EventOptionalTextValue eventTypeLabelValue;
  final EventOptionalTextValue venueTitleValue;
  final EventOptionalTextValue selectedOccurrenceIdValue;
  final EventCounterpartCountValue? counterpartCountValue;
  final MongoIDValue? venueIdValue;
  final List<EventLinkedAccountProfile> linkedAccountProfiles;
  final List<EventTagValue> tagValues;
  final CityCoordinate? coordinate;
  final MissionResume? mission;
  static final Uri _localPlaceholderUri = Uri.parse(
    'asset://event-placeholder',
  );

  UpcomingOcurrenceResumePrimString get id => idValue.value;
  UpcomingOcurrenceResumePrimString get slug => slugValue.value;
  UpcomingOcurrenceResumePrimString get title => titleValue.value;
  Uri get imageUri => imageUriValue.value;
  UpcomingOcurrenceResumePrimDateTime get startDateTime {
    final date = startDateTimeValue.value;
    if (date == null) {
      throw StateError('startDateTime should not be null');
    }
    return TimezoneConverter.utcToLocal(date);
  }

  UpcomingOcurrenceResumePrimDateTime? get endDateTime {
    final date = endDateTimeValue?.value;
    if (date == null) {
      return null;
    }
    return TimezoneConverter.utcToLocal(date);
  }

  EventScheduleDisplay get scheduleDisplay => EventScheduleDisplay(
    startValue: startDateTimeValue,
    endValue: endDateTimeValue,
  );

  UpcomingOcurrenceResumePrimString get detailScheduleLabel =>
      scheduleDisplay.detailLabel;

  UpcomingOcurrenceResumePrimString get agendaScheduleLabel =>
      scheduleDisplay.agendaLabel;

  UpcomingOcurrenceResumePrimString get compactScheduleLabel =>
      scheduleDisplay.compactRangeLabel;

  UpcomingOcurrenceResumePrimString get flyerScheduleLabel =>
      scheduleDisplay.flyerLabel;

  UpcomingOcurrenceResumePrimString get location => locationValue.value;
  UpcomingOcurrenceResumePrimString? get eventTypeLabel {
    final value = eventTypeLabelValue.value.trim();
    return value.isEmpty ? null : value;
  }

  UpcomingOcurrenceResumePrimString? get venueTitle {
    final value = venueTitleValue.value.trim();
    return value.isEmpty ? null : value;
  }

  UpcomingOcurrenceResumePrimString? get selectedOccurrenceId {
    final value = selectedOccurrenceIdValue.value.trim();
    return value.isEmpty ? null : value;
  }

  String? get venueId {
    final value = venueIdValue?.value.trim();
    return value == null || value.isEmpty ? null : value;
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
  UpcomingOcurrenceResumePrimInt get counterpartCount {
    final previewCount = counterpartProfiles.length;
    final canonicalCount = counterpartCountValue?.value ?? previewCount;
    return canonicalCount < previewCount ? previewCount : canonicalCount;
  }

  UpcomingOcurrenceResumePrimBool get hasCounterparts =>
      counterpartProfiles.isNotEmpty;
  EventLinkedAccountProfile? get primaryCounterpart =>
      hasCounterparts ? counterpartProfiles.first : null;
  List<EventTagValue> get tags => List<EventTagValue>.unmodifiable(tagValues);
  UpcomingOcurrenceResumePrimString get counterpartNamesLabel =>
      counterpartProfiles
          .map((profile) => profile.displayName.trim())
          .where((name) => name.isNotEmpty)
          .join(', ');

  static UpcomingOcurrenceResumePrimString slugify(TitleValue value) {
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

    if (settingsDefaultImageValue != null &&
        settingsDefaultImageValue.value.toString().trim().isNotEmpty) {
      return settingsDefaultImageValue.value;
    }

    return _localPlaceholderUri;
  }

  factory UpcomingOcurrenceResume.fromScheduleEvent(
    EventModel event,
    ThumbUriValue fallbackImageValue,
  ) {
    final slugSource = event.slug;
    final slug = SlugValue()
      ..parse(
        slugSource.isNotEmpty
            ? slugSource
            : UpcomingOcurrenceResume.slugify(event.title),
      );

    final preferredImageUri = resolvePreferredImageUri(
      event,
      settingsDefaultImageValue: fallbackImageValue,
    );
    final thumb = ThumbUriValue(
      defaultValue: preferredImageUri,
      isRequired: true,
    )..parse(preferredImageUri.toString());

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

    return UpcomingOcurrenceResume(
      idValue: event.id,
      slugValue: slug,
      titleValue: event.title,
      imageUriValue: thumb,
      startDateTimeValue: startValue,
      endDateTimeValue: endValue,
      locationValue: event.location,
      eventTypeLabelValue: EventOptionalTextValue()
        ..parse(event.type.name.value),
      venueTitleValue: EventOptionalTextValue()
        ..parse(event.venue?.displayName ?? ''),
      selectedOccurrenceIdValue: EventOptionalTextValue()
        ..parse(event.selectedOccurrenceId ?? ''),
      counterpartCountValue: event.counterpartCountValue,
      venueIdValue: event.venue?.id.isNotEmpty == true
          ? (MongoIDValue()..parse(event.venue!.id))
          : null,
      linkedAccountProfiles: event.counterpartProfiles,
      tagValues: event.taxonomyTags,
      coordinate: event.coordinate,
      mission: null, // TODO: Map from EventModel when available
    );
  }

  factory UpcomingOcurrenceResume.fromPartnerEventView(
    PartnerEventView event, {
    required MongoIDValue viewedProfileId,
    required TitleValue viewedProfileName,
  }) {
    final imageUri = event.imageUri ?? _localPlaceholderUri;
    final imageValue = ThumbUriValue(defaultValue: imageUri, isRequired: true)
      ..parse(imageUri.toString());
    final titleValue = TitleValue(minLenght: 1)..parse(event.title);
    final slugValue = SlugValue()
      ..parse(
        event.slug.trim().isNotEmpty
            ? event.slug
            : UpcomingOcurrenceResume.slugify(titleValue),
      );
    final venueId = event.venueId;

    return UpcomingOcurrenceResume(
      idValue: event.eventIdValue,
      slugValue: slugValue,
      titleValue: titleValue,
      imageUriValue: imageValue,
      startDateTimeValue: event.startDateTimeValue,
      endDateTimeValue: event.endDateTimeValue,
      locationValue: DescriptionValue(minLenght: 0)..parse(event.location),
      eventTypeLabelValue: EventOptionalTextValue()
        ..parse(event.eventTypeLabel ?? ''),
      venueTitleValue: EventOptionalTextValue()..parse(event.venueTitle ?? ''),
      selectedOccurrenceIdValue: EventOptionalTextValue()
        ..parse(event.occurrenceId),
      counterpartCountValue: event.counterpartCountValue,
      venueIdValue: venueId == null ? null : (MongoIDValue()..parse(venueId)),
      linkedAccountProfiles: _partnerCounterpartsToEventProfiles(
        event,
        viewedProfileId: viewedProfileId,
        viewedProfileName: viewedProfileName,
      ),
      tagValues: const [],
      mission: null,
    );
  }

  static List<EventLinkedAccountProfile> _partnerCounterpartsToEventProfiles(
    PartnerEventView event, {
    required MongoIDValue viewedProfileId,
    required TitleValue viewedProfileName,
  }) {
    final normalizedViewedId = viewedProfileId.value.trim();
    final normalizedViewedName = viewedProfileName.value.trim().toLowerCase();
    final normalizedVenueId = event.venueId?.trim();
    final profiles = <EventLinkedAccountProfile>[];

    for (final profile in event.counterpartProfiles) {
      final profileId = profile.id?.trim() ?? '';
      final profileName = profile.title.trim();
      final normalizedProfileType = profile.profileType?.trim().toLowerCase();
      final normalizedPartyType = profile.partyType?.trim().toLowerCase();
      if (profileId == normalizedViewedId ||
          profileName.toLowerCase() == normalizedViewedName ||
          (normalizedVenueId != null && profileId == normalizedVenueId) ||
          normalizedProfileType == 'venue' ||
          normalizedPartyType == 'venue' ||
          profileName.isEmpty) {
        continue;
      }

      final avatarUrl = profile.thumb?.trim();
      profiles.add(
        EventLinkedAccountProfile(
          idValue: EventLinkedAccountProfileTextValue(
            profileId.isEmpty ? 'name:$profileName' : profileId,
          ),
          displayNameValue: EventLinkedAccountProfileTextValue(profileName),
          profileTypeValue: AccountProfileTypeValue(
            profile.profileType?.trim() ?? 'profile',
          ),
          avatarUrlValue: avatarUrl == null || avatarUrl.isEmpty
              ? null
              : (ThumbUriValue(
                  defaultValue: Uri.parse(avatarUrl),
                  isRequired: true,
                )..parse(avatarUrl)),
          partyTypeValue: profile.partyType == null
              ? null
              : EventLinkedAccountProfileTextValue(profile.partyType!),
        ),
      );
    }

    return List<EventLinkedAccountProfile>.unmodifiable(profiles);
  }
}
