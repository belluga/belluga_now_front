import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

void main() {
  group('VenueEventResume.resolvePreferredImageUri', () {
    test('prefers event cover before artist/host/settings', () {
      final event = _buildEvent(
        thumb:
            ThumbModel.fromPrimitives(url: 'https://cdn.test/event-cover.png'),
        artists: [
          ArtistResume.fromPrimitives(
            id: 'artist-1',
            name: 'Artist One',
            avatarUrl: 'https://cdn.test/artist-cover.png',
          ),
        ],
        venue: _buildVenue(heroUrl: 'https://cdn.test/host-cover.png'),
      );

      final resolved = VenueEventResume.resolvePreferredImageUri(
        event,
        settingsDefaultImageUri: Uri.parse('https://cdn.test/settings.png'),
      );

      expect(resolved.toString(), 'https://cdn.test/event-cover.png');
    });

    test('applies fallback chain artist -> host -> settings -> local', () {
      final artistEvent = _buildEvent(
        artists: [
          ArtistResume.fromPrimitives(
            id: 'artist-1',
            name: 'Artist One',
            avatarUrl: 'https://cdn.test/artist-cover.png',
          ),
        ],
      );
      final hostEvent = _buildEvent(
        venue: _buildVenue(heroUrl: 'https://cdn.test/host-cover.png'),
      );
      final settingsEvent = _buildEvent();

      final artistResolved =
          VenueEventResume.resolvePreferredImageUri(artistEvent);
      final hostResolved = VenueEventResume.resolvePreferredImageUri(hostEvent);
      final settingsResolved = VenueEventResume.resolvePreferredImageUri(
        settingsEvent,
        settingsDefaultImageUri: Uri.parse('https://cdn.test/settings.png'),
      );
      final localResolved =
          VenueEventResume.resolvePreferredImageUri(settingsEvent);

      expect(artistResolved.toString(), 'https://cdn.test/artist-cover.png');
      expect(hostResolved.toString(), 'https://cdn.test/host-cover.png');
      expect(settingsResolved.toString(), 'https://cdn.test/settings.png');
      expect(localResolved.toString(), 'asset://event-placeholder');
    });
  });
}

EventModel _buildEvent({
  ThumbModel? thumb,
  List<ArtistResume> artists = const [],
  PartnerResume? venue,
}) {
  return EventModel(
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
    coordinate: null,
    tags: const [],
    isConfirmedValue: EventIsConfirmedValue()..parse('false'),
    totalConfirmedValue: EventTotalConfirmedValue()..parse('0'),
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
