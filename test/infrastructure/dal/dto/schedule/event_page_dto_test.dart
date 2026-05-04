import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses live_now agenda page payload with items + has_more', () {
    final page = EventPageDTO.fromJson({
      'tenant_id': '695c1809fee8b3839804dc85',
      'items': [
        {
          'event_id': '69a77aa3680219d56909080f',
          'occurrence_id': '69a77aa3680219d569090810',
          'slug': 'karaoke',
          'type': {
            'id': '69aac4ddd37046e0fe017c86',
            'name': 'Feira',
            'slug': 'feira',
            'description': 'Feira comercial',
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
          'venue': {
            'id': '69c558629b497835b900ac86',
            'display_name': 'Carvoeiro',
          },
          'latitude': -20.673704,
          'longitude': -40.498859,
          'date_time_start': '2026-03-29T01:00:00+00:00',
          'date_time_end': null,
          'artists': [
            {
              'id': '69949486be6cd999250a2507',
              'slug': 'ananda-torres',
              'display_name': 'Ananda Torres',
              'avatar_url':
                  'https://guarappari.belluga.space/account-profiles/69949486be6cd999250a2507/avatar?v=1771359996',
              'highlight': false,
            },
          ],
        },
      ],
      'has_more': false,
    });

    expect(page.hasMore, isFalse);
    expect(page.events, hasLength(1));
    expect(page.events.first.id, '69a77aa3680219d56909080f');
    expect(page.events.first.slug, 'karaoke');
    expect(page.events.first.location, 'Carvoeiro');
  });

  test('skips malformed event items and keeps remaining agenda events', () {
    final page = EventPageDTO.fromJson({
      'items': [
        {
          'event_id': '507f1f77bcf86cd799439021',
          'occurrence_id': '507f1f77bcf86cd799439022',
          'slug': 'evento-quebrado',
          'title': 'Evento quebrado',
          'content': 'Payload com occurrence invalida.',
          'location': 'Guarapari, ES',
          'date_time_start': '2099-01-01T20:00:00+00:00',
          'type': {
            'id': 'type-1',
            'name': 'Show',
            'slug': 'show',
            'description': 'Show ao vivo',
          },
          'occurrences': [
            {
              'occurrence_id': '507f1f77bcf86cd799439022',
              'date_time_start': 'not-a-date',
            },
          ],
        },
        {
          'event_id': '507f1f77bcf86cd799439031',
          'occurrence_id': '507f1f77bcf86cd799439032',
          'slug': 'evento-valido',
          'type': {
            'id': '69aac4ddd37046e0fe017c86',
            'name': 'Feira',
            'slug': 'feira',
            'description': 'Feira comercial',
          },
          'title': 'Evento valido',
          'content': 'Evento que deve sobreviver ao parse.',
          'location': 'Carvoeiro',
          'date_time_start': '2099-01-02T20:00:00+00:00',
        },
      ],
      'has_more': 1,
    });

    expect(page.hasMore, isTrue);
    expect(page.events, hasLength(1));
    expect(page.events.single.id, '507f1f77bcf86cd799439031');
    expect(page.events.single.slug, 'evento-valido');
  });
}
