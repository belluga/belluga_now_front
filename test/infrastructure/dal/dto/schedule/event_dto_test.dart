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
      },
      'latitude': -20.2,
      'longitude': -40.1,
      'date_time_start': '2026-03-03T20:00:00+00:00',
      'date_time_end': '2026-03-03T22:00:00+00:00',
      'artists': [
        {
          'id': 'artist-1',
          'display_name': 'The Band',
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
    expect(dto.artists, hasLength(1));
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
      'artists': const [],
    });

    expect(dto.id, 'occ-42');
  });

  test('derives latitude and longitude from location.geo when root keys are absent', () {
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
      'artists': const [],
    });

    expect(dto.latitude, closeTo(-20.671339, 0.000001));
    expect(dto.longitude, closeTo(-40.495395, 0.000001));
  });
}
