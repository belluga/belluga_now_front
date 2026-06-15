import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/services/timezone_service_contract.dart';
import 'package:belluga_now/domain/services/value_objects/timezone_service_contract_values.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<TimezoneServiceContract>(
      _FakeTimezoneService(hoursOffset: -3),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('VenueEventResume.resolvePreferredImageUri', () {
    test('prefers event cover before artist/host/settings', () {
      final event = _buildEvent(
        thumb: ThumbModel(
          thumbUri: ThumbUriValue(
            defaultValue: Uri.parse('https://cdn.test/event-cover.png'),
          )..parse('https://cdn.test/event-cover.png'),
          thumbType: ThumbTypeValue(defaultValue: ThumbTypes.image)
            ..parse(ThumbTypes.image.name),
        ),
        linkedAccountProfiles: [
          _buildLinkedProfile(
            id: 'profile-1',
            displayName: 'Profile One',
            profileType: 'artist',
            coverUrl: 'https://cdn.test/profile-cover.png',
          ),
        ],
        venue: _buildVenue(heroUrl: 'https://cdn.test/host-cover.png'),
      );

      final resolved = VenueEventResume.resolvePreferredImageUri(
        event,
        settingsDefaultImageValue: ThumbUriValue(
          defaultValue: Uri.parse('https://cdn.test/settings.png'),
        )..parse('https://cdn.test/settings.png'),
      );

      expect(resolved.toString(), 'https://cdn.test/event-cover.png');
    });

    test(
        'applies fallback chain related accounts by order -> venue -> settings -> local',
        () {
      final orderedRelatedEvent = _buildEvent(
        linkedAccountProfiles: [
          _buildLinkedProfile(
            id: 'profile-1',
            displayName: 'Profile One',
            profileType: 'producer',
            avatarUrl: 'https://cdn.test/profile-one-avatar.png',
          ),
          _buildLinkedProfile(
            id: 'profile-2',
            displayName: 'Profile Two',
            profileType: 'band',
            coverUrl: 'https://cdn.test/profile-two-cover.png',
          ),
        ],
      );
      final hostEvent = _buildEvent(
        venue: _buildVenue(heroUrl: 'https://cdn.test/host-cover.png'),
      );
      final settingsEvent = _buildEvent();

      final relatedResolved =
          VenueEventResume.resolvePreferredImageUri(orderedRelatedEvent);
      final hostResolved = VenueEventResume.resolvePreferredImageUri(hostEvent);
      final settingsResolved = VenueEventResume.resolvePreferredImageUri(
        settingsEvent,
        settingsDefaultImageValue: ThumbUriValue(
          defaultValue: Uri.parse('https://cdn.test/settings.png'),
        )..parse('https://cdn.test/settings.png'),
      );
      final localResolved =
          VenueEventResume.resolvePreferredImageUri(settingsEvent);

      expect(
        relatedResolved.toString(),
        'https://cdn.test/profile-one-avatar.png',
      );
      expect(hostResolved.toString(), 'https://cdn.test/host-cover.png');
      expect(settingsResolved.toString(), 'https://cdn.test/settings.png');
      expect(localResolved.toString(), 'asset://event-placeholder');
    });

    test('ignores venue entries inside related account ordering', () {
      final event = _buildEvent(
        linkedAccountProfiles: [
          _buildLinkedProfile(
            id: 'profile-venue',
            displayName: 'Venue Mirror',
            profileType: 'venue',
            partyType: 'venue',
            coverUrl: 'https://cdn.test/linked-venue-cover.png',
          ),
          _buildLinkedProfile(
            id: 'profile-artist',
            displayName: 'Profile Artist',
            profileType: 'artist',
            avatarUrl: 'https://cdn.test/profile-artist-avatar.png',
          ),
        ],
        venue: _buildVenue(heroUrl: 'https://cdn.test/host-cover.png'),
      );

      final resolved = VenueEventResume.resolvePreferredImageUri(event);

      expect(
        resolved.toString(),
        'https://cdn.test/profile-artist-avatar.png',
      );
    });

    test('uses venue fallback after skipping venue entries in related accounts',
        () {
      final event = _buildEvent(
        linkedAccountProfiles: [
          _buildLinkedProfile(
            id: 'profile-venue',
            displayName: 'Venue Mirror',
            profileType: 'venue',
            partyType: 'venue',
            coverUrl: 'https://cdn.test/linked-venue-cover.png',
          ),
        ],
        venue: _buildVenue(heroUrl: 'https://cdn.test/host-cover.png'),
      );

      final resolved = VenueEventResume.resolvePreferredImageUri(event);

      expect(resolved.toString(), 'https://cdn.test/host-cover.png');
    });
  });

  test('fromScheduleEvent preserves event type label and venue title', () {
    final event = _buildEvent(
      venue: _buildVenue(),
    );
    final fallbackThumb = ThumbUriValue(
      defaultValue: Uri.parse('https://cdn.test/settings.png'),
      isRequired: true,
    )..parse('https://cdn.test/settings.png');

    final projection = VenueEventResume.fromScheduleEvent(event, fallbackThumb);

    expect(projection.eventTypeLabel, 'Show');
    expect(projection.venueTitle, 'Host Venue');
  });

  group('human ready schedule labels', () {
    test('same day range uses one date context and whole-hour h labels', () {
      final resume = _buildResume(
        start: DateTime.utc(2026, 4, 1, 10),
        end: DateTime.utc(2026, 4, 1, 13),
      );

      expect(resume.detailScheduleLabel, 'Qua, 1 abr · 7h às 10h');
      expect(resume.agendaScheduleLabel, '7h às 10h');
      expect(resume.flyerScheduleLabel, 'Qua, 1 abr · 7h');
    });

    test('nonzero minutes use hMM labels', () {
      final resume = _buildResume(
        start: DateTime.utc(2026, 4, 1, 10, 30),
        end: DateTime.utc(2026, 4, 1, 12, 45),
      );

      expect(resume.detailScheduleLabel, 'Qua, 1 abr · 7h30 às 9h45');
      expect(resume.agendaScheduleLabel, '7h30 às 9h45');
      expect(resume.flyerScheduleLabel, 'Qua, 1 abr · 7h30');
    });

    test('cross day range includes both date contexts', () {
      final resume = _buildResume(
        start: DateTime.utc(2026, 4, 2, 1),
        end: DateTime.utc(2026, 4, 2, 5),
      );

      expect(
        resume.detailScheduleLabel,
        'Qua, 1 abr · 22h até Qui, 2 abr · 2h',
      );
      expect(
        resume.agendaScheduleLabel,
        'Qua, 1 abr · 22h até Qui, 2 abr · 2h',
      );
      expect(resume.flyerScheduleLabel, 'Qua, 1 abr · 22h');
    });

    test('start only range omits dangling separator', () {
      final resume = _buildResume(
        start: DateTime.utc(2026, 4, 1, 10),
      );

      expect(resume.detailScheduleLabel, 'Qua, 1 abr · 7h');
      expect(resume.agendaScheduleLabel, '7h');
      expect(resume.flyerScheduleLabel, 'Qua, 1 abr · 7h');
    });
  });

  test('EventModel exposes selected occurrence human ready schedule labels',
      () {
    final event = _buildEvent(
      occurrenceStart: DateTime.utc(2026, 4, 1, 10, 30),
      occurrenceEnd: DateTime.utc(2026, 4, 1, 12),
    );

    expect(event.detailScheduleLabel, 'Qua, 1 abr · 7h30 às 9h');
    expect(event.agendaScheduleLabel, '7h30 às 9h');
    expect(event.flyerScheduleLabel, 'Qua, 1 abr · 7h30');
  });
}

VenueEventResume _buildResume({
  required DateTime start,
  DateTime? end,
}) {
  return VenueEventResume(
    idValue: MongoIDValue()..parse('507f1f77bcf86cd799439099'),
    slugValue: SlugValue()..parse('sample-event'),
    titleValue: TitleValue(minLenght: 1)..parse('Sample Event'),
    imageUriValue: ThumbUriValue(
      defaultValue: Uri.parse('https://cdn.test/event.png'),
      isRequired: true,
    )..parse('https://cdn.test/event.png'),
    startDateTimeValue: DateTimeValue(isRequired: true)
      ..parse(start.toIso8601String()),
    endDateTimeValue: end == null
        ? null
        : (DateTimeValue(isRequired: true)..parse(end.toIso8601String())),
    locationValue: DescriptionValue(minLenght: 1)..parse('Main Hall'),
    linkedAccountProfiles: const [],
    tagValues: const [],
  );
}

EventModel _buildEvent({
  ThumbModel? thumb,
  List<ArtistResume> artists = const [],
  List<EventLinkedAccountProfile> linkedAccountProfiles = const [],
  PartnerResume? venue,
  DateTime? occurrenceStart,
  DateTime? occurrenceEnd,
}) {
  final occurrences = occurrenceStart == null
      ? const <EventOccurrenceOption>[]
      : <EventOccurrenceOption>[
          EventOccurrenceOption(
            occurrenceIdValue: EventLinkedAccountProfileTextValue(
              'occurrence-1',
            ),
            occurrenceSlugValue: EventLinkedAccountProfileTextValue(
              'occurrence-1',
            ),
            dateTimeStartValue: DateTimeValue(isRequired: true)
              ..parse(occurrenceStart.toIso8601String()),
            dateTimeEndValue: DomainOptionalDateTimeValue()
              ..parse(occurrenceEnd?.toIso8601String()),
            isSelectedValue: EventOccurrenceFlagValue()..parse('true'),
            hasLocationOverrideValue: EventOccurrenceFlagValue()
              ..parse('false'),
            programmingCountValue: EventProgrammingCountValue()..parse('0'),
          ),
        ];

  return eventModelFromRaw(
    id: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
    slugValue: SlugValue()..parse('sample-event'),
    type: EventTypeModel(
      id: EventTypeIdValue()..parse('concert'),
      name: TitleValue(minLenght: 1)..parse('Show'),
      slug: SlugValue()..parse('concert'),
      description: DescriptionValue(minLenght: 1)..parse('Description'),
      icon: SlugValue()..parse('music'),
      color: ColorValue(defaultValue: const Color(0xFF000000))
        ..parse('#123456'),
    ),
    title: TitleValue(minLenght: 1)..parse('Sample Event'),
    content: HTMLContentValue()..parse('<p>Sample content</p>'),
    location: DescriptionValue(minLenght: 1)..parse('Main Hall'),
    venue: venue,
    thumb: thumb,
    dateTimeStart: DateTimeValue()..parse('2026-03-21T10:00:00Z'),
    dateTimeEnd: null,
    artists: artists,
    linkedAccountProfiles: linkedAccountProfiles,
    occurrences: occurrences,
    coordinate: null,
    tags: const [],
    isConfirmedValue: EventIsConfirmedValue()..parse('false'),
    totalConfirmedValue: EventTotalConfirmedValue()..parse('0'),
  );
}

class _FakeTimezoneService implements TimezoneServiceContract {
  _FakeTimezoneService({required this.hoursOffset});

  final int hoursOffset;

  @override
  TimezoneServiceContractDateTimeValue utcToLocal(
    TimezoneServiceContractDateTimeValue value,
  ) {
    final raw = value.value;
    final baseUtc = raw.isUtc ? raw : raw.toUtc();
    final shifted = baseUtc.add(Duration(hours: hoursOffset));
    return timezoneServiceDateTime(
      DateTime(
        shifted.year,
        shifted.month,
        shifted.day,
        shifted.hour,
        shifted.minute,
        shifted.second,
        shifted.millisecond,
        shifted.microsecond,
      ),
      defaultValue: shifted,
    );
  }

  @override
  TimezoneServiceContractDateTimeValue localToUtc(
    TimezoneServiceContractDateTimeValue value,
  ) {
    final raw = value.value;
    final normalized = DateTime(
      raw.year,
      raw.month,
      raw.day,
      raw.hour - hoursOffset,
      raw.minute,
      raw.second,
      raw.millisecond,
      raw.microsecond,
    );
    return timezoneServiceDateTime(normalized.toUtc(), defaultValue: raw);
  }
}

EventLinkedAccountProfile _buildLinkedProfile({
  required String id,
  required String displayName,
  required String profileType,
  String? partyType,
  String? avatarUrl,
  String? coverUrl,
}) {
  return EventLinkedAccountProfile(
    idValue: EventLinkedAccountProfileTextValue(id),
    displayNameValue: EventLinkedAccountProfileTextValue(displayName),
    profileTypeValue: AccountProfileTypeValue(profileType),
    slugValue: SlugValue()..parse('$id-slug'),
    avatarUrlValue: avatarUrl == null
        ? null
        : (ThumbUriValue(
            defaultValue: Uri.parse(avatarUrl),
            isRequired: true,
          )..parse(avatarUrl)),
    coverUrlValue: coverUrl == null
        ? null
        : (ThumbUriValue(
            defaultValue: Uri.parse(coverUrl),
            isRequired: true,
          )..parse(coverUrl)),
    partyTypeValue: partyType == null
        ? null
        : EventLinkedAccountProfileTextValue(partyType),
  );
}

PartnerResume _buildVenue({
  String? heroUrl,
  String? logoUrl,
}) {
  InvitePartnerHeroImageValue? heroValue;
  if (heroUrl != null && heroUrl.isNotEmpty) {
    heroValue = InvitePartnerHeroImageValue()..parse(heroUrl);
  }
  InvitePartnerLogoImageValue? logoValue;
  if (logoUrl != null && logoUrl.isNotEmpty) {
    logoValue = InvitePartnerLogoImageValue()..parse(logoUrl);
  }

  return PartnerResume(
    idValue: MongoIDValue()..parse('507f1f77bcf86cd799439012'),
    nameValue: InvitePartnerNameValue()..parse('Host Venue'),
    type: InviteAccountProfileType.mercadoProducer,
    heroImageValue: heroValue,
    logoImageValue: logoValue,
  );
}
