import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses agenda occurrence payload shape without throwing', () {
    final dto = EventDTO.fromJson({
      'event_id': 'evt-1',
      'occurrence_id': 'occ-1',
      'slug': 'rock-night-occ-1',
      'title': 'Rock Night',
      'content': 'Live concert',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type',
        'icon': null,
        'color': '#112233',
      },
      'location': {
        'mode': 'physical',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.1, -20.2],
        },
      },
      'venue': {
        'id': 'venue-1',
        'display_name': 'Arena Central',
        'slug': 'arena-central',
      },
      'latitude': -20.2,
      'longitude': -40.1,
      'date_time_start': '2026-03-03T20:00:00+00:00',
      'date_time_end': '2026-03-03T22:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'artist-1',
          'display_name': 'The Band',
          'slug': 'the-band',
          'profile_type': 'artist',
        },
      ],
      'tags': ['music'],
    });

    expect(dto.id, 'evt-1');
    expect(dto.slug, 'rock-night-occ-1');
    expect(dto.title, 'Rock Night');
    expect(dto.location, 'Arena Central');
    expect(dto.dateTimeStart, '2026-03-03T20:00:00+00:00');
    expect(dto.dateTimeEnd, '2026-03-03T22:00:00+00:00');
    expect(dto.linkedAccountProfiles, hasLength(1));
    expect(dto.type.id, 'type-1');
  });

  test('uses occurrence_id as fallback id when event_id is missing', () {
    final dto = EventDTO.fromJson({
      'occurrence_id': 'occ-42',
      'slug': 'event-occ-42',
      'type': {
        'id': 'type-1',
        'name': 'Workshop',
        'slug': 'workshop',
        'description': '',
      },
      'title': 'Occurrence only',
      'content': '',
      'location': 'Remote',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': const [],
    });

    expect(dto.id, 'occ-42');
  });

  test(
      'derives latitude and longitude from location.geo when root keys are absent',
      () {
    final dto = EventDTO.fromJson({
      'event_id': 'evt-geo',
      'slug': 'evt-geo',
      'type': {
        'id': 'music-show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Geo Event',
      'content': 'Geo Content',
      'location': {
        'mode': 'physical',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': const [],
    });

    expect(dto.latitude, closeTo(-20.671339, 0.000001));
    expect(dto.longitude, closeTo(-40.495395, 0.000001));
  });

  test('maps live_now agenda payload shape from production-compatible contract',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909080f',
      'occurrence_id': '69a77aa3680219d569090810',
      'slug': 'karaoke',
      'type': {
        'id': '69aac4ddd37046e0fe017c86',
        'name': 'Feira',
        'slug': 'feira',
        'description': 'Feira comercial',
        'icon': null,
        'color': null,
        'icon_color': null,
      },
      'title': 'Karaokê',
      'content': 'Evento de karaokê pra você cantar.',
      'location': {
        'mode': 'physical',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.498859, -20.673704],
        },
      },
      'place_ref': {
        'type': 'account_profile',
        'metadata': {'display_name': 'Carvoeiro'},
        'id': '69c558629b497835b900ac86',
      },
      'venue': {
        'id': '69c558629b497835b900ac86',
        'display_name': 'Carvoeiro',
        'slug': 'carvoeiro',
        'tagline': null,
        'hero_image_url': null,
        'logo_url': null,
      },
      'latitude': -20.673704,
      'longitude': -40.498859,
      'thumb': null,
      'date_time_start': '2026-03-29T01:00:00+00:00',
      'date_time_end': null,
      'linked_account_profiles': [
        {
          'id': '69949486be6cd999250a2507',
          'display_name': 'Ananda Torres',
          'slug': 'ananda-torres',
          'profile_type': 'artist',
          'avatar_url':
              'https://guarappari.belluga.space/account-profiles/69949486be6cd999250a2507/avatar?v=1771359996',
          'highlight': false,
          'genres': ['brasilidades', 'samba'],
        },
      ],
      'tags': const [],
      'taxonomy_terms': [
        {'type': 'genre', 'value': 'brasilidades'},
        {'type': 'genre', 'value': 'rock'},
      ],
    });

    final domain = dto.toDomain();

    expect(dto.id, '69a77aa3680219d56909080f');
    expect(dto.location, 'Carvoeiro');
    expect(dto.latitude, closeTo(-20.673704, 0.000001));
    expect(dto.longitude, closeTo(-40.498859, 0.000001));
    expect(dto.linkedAccountProfiles, hasLength(1));
    expect(domain.slug, 'karaoke');
    expect(domain.title.value, 'Karaokê');
    expect(domain.location.value, 'Carvoeiro');
    expect(domain.coordinate, isNotNull);
    expect(
      domain.linkedAccountProfiles.first.displayName,
      'Ananda Torres',
    );
  });

  test('parses linked account profiles with taxonomy names for dynamic tabs',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909080f',
      'slug': 'evt-linked',
      'type': {
        'id': '69a77aa3680219d569090810',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento com perfis',
      'content': 'Descricao',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'artist-1',
          'display_name': 'Ananda Torres',
          'slug': 'ananda-torres',
          'profile_type': 'artist',
          'avatar_url': 'https://tenant.test/artist-avatar.png',
          'cover_url': 'https://tenant.test/artist-cover.png',
          'taxonomy_terms': [
            {'type': 'genre', 'value': 'samba', 'name': 'Samba'},
          ],
        },
      ],
    });

    final domain = dto.toDomain();

    expect(domain.linkedAccountProfiles, hasLength(1));
    expect(domain.linkedAccountProfiles.first.profileType, 'artist');
    expect(domain.linkedAccountProfiles.first.slug, 'ananda-torres');
    expect(
      domain.linkedAccountProfiles.first.taxonomyTerms.first.labelValue.value,
      'Samba',
    );
  });

  test('does not synthesize linked account profiles from artists or venue', () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909080f',
      'slug': 'evt-linked-cutover',
      'type': {
        'id': '69a77aa3680219d569090810',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento canônico',
      'content': 'Descricao',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'venue': {
        'id': '69c558629b497835b900ac86',
        'display_name': 'Carvoeiro',
        'slug': 'carvoeiro',
      },
      'linked_account_profiles': const [],
    });

    final domain = dto.toDomain();

    expect(domain.linkedAccountProfiles, isEmpty);
  });

  test('accepts account-profile slug aliases in linked account profiles', () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909081a',
      'slug': 'evt-aliased-slug',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento com alias',
      'content': 'Descricao',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'artist-1',
          'display_name': 'Ananda Torres',
          'profile_type': 'artist',
          'account_profile_slug': 'ananda-torres',
        },
      ],
    });

    final domain = dto.toDomain();

    expect(domain.linkedAccountProfiles, hasLength(1));
    expect(domain.linkedAccountProfiles.first.slug, 'ananda-torres');
  });

  test('throws when linked account profile slug is missing after enrichment',
      () {
    expect(
      () => EventDTO.fromJson({
        'event_id': '69a77aa3680219d56909081b',
        'slug': 'evt-missing-linked-slug',
        'type': {
          'id': 'show',
          'name': 'Show',
          'slug': 'show',
          'description': '',
        },
        'title': 'Evento inconsistente',
        'content': 'Descricao',
        'location': 'Carvoeiro',
        'date_time_start': '2026-03-03T10:00:00+00:00',
        'linked_account_profiles': [
          {
            'id': 'artist-1',
            'display_name': 'Ananda Torres',
            'profile_type': 'artist',
          },
        ],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('linked_account_profiles[artist-1].slug'),
        ),
      ),
    );
  });
}
