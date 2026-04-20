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
}
