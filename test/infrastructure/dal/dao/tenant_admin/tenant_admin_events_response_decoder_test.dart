import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_events_response_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = TenantAdminEventsResponseDecoder();

  test('prefers artist ids from event_parties when available', () {
    final event = decoder.decodeEventItem({
      'data': {
        'event_id': 'evt-1',
        'slug': 'evento',
        'title': 'Evento',
        'content': 'Conteudo',
        'type': {
          'id': 'type-1',
          'name': 'Show',
          'slug': 'show',
          'description': '',
        },
        'date_time_start': '2026-04-05T20:00:00+00:00',
        'publication': {'status': 'draft'},
        'event_parties': [
          {
            'party_type': 'artist',
            'party_ref_id': 'artist-1',
            'permissions': {'can_edit': true},
          },
          {
            'party_type': 'producer',
            'party_ref_id': 'producer-1',
            'permissions': {'can_edit': false},
          },
        ],
        'artist_ids': ['legacy-artist-id'],
      },
    });

    expect(
      event.artistIds.map((entry) => entry.value).toList(growable: false),
      ['artist-1'],
    );
    expect(
      event.eventParties.map((entry) => entry.partyRefId).toList(growable: false),
      ['artist-1', 'producer-1'],
    );
  });

  test('decodes legacy event parties summary payload', () {
    final summary = decoder.decodeLegacyEventPartiesSummary({
      'data': {
        'scanned': 9,
        'invalid': 3,
        'repaired': 2,
        'unchanged': 6,
        'failed': 1,
      },
    });

    expect(summary.scanned, 9);
    expect(summary.invalid, 3);
    expect(summary.repaired, 2);
    expect(summary.unchanged, 6);
    expect(summary.failed, 1);
  });

  test('decodes event place_ref from legacy _id payload', () {
    final event = decoder.decodeEventItem({
      'data': {
        'event_id': 'evt-legacy-place',
        'slug': 'evento-legado',
        'title': 'Evento legado',
        'content': 'Conteudo',
        'type': {
          'id': 'type-1',
          'name': 'Show',
          'slug': 'show',
        },
        'place_ref': {
          'type': 'account_profile',
          '_id': '507f1f77bcf86cd799439011',
        },
        'date_time_start': '2026-04-05T20:00:00+00:00',
        'publication': {'status': 'draft'},
        'occurrences': [
          {
            'date_time_start': '2026-04-05T20:00:00+00:00',
          },
        ],
      },
    });

    expect(event.placeRef, isNotNull);
    expect(event.placeRef!.type, 'account_profile');
    expect(event.placeRef!.id, '507f1f77bcf86cd799439011');
  });

  test('rejects structured title payload instead of stringifying object values', () {
    expect(
      () => decoder.decodeEventItem({
        'data': {
          'event_id': 'evt-bad-title',
          'slug': 'evento-legado',
          'title': {
            'raw': 'Evento legado',
          },
          'content': 'Conteudo',
          'type': {
            'id': 'type-1',
            'name': 'Show',
            'slug': 'show',
          },
          'date_time_start': '2026-04-05T20:00:00+00:00',
          'publication': {'status': 'draft'},
          'occurrences': [
            {
              'date_time_start': '2026-04-05T20:00:00+00:00',
            },
          ],
        },
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Invalid scalar text value'),
        ),
      ),
    );
  });

  test('accepts wrapped legacy date leaves inside nested dto payloads', () {
    final event = decoder.decodeEventItem({
      'data': {
        'event_id': 'evt-legacy-dates',
        'slug': 'evento-legado-datas',
        'title': 'Evento legado datas',
        'content': 'Conteudo',
        'type': {
          'id': 'type-1',
          'name': 'Show',
          'slug': 'show',
        },
        'thumb': {
          'type': 'image',
          'data': {
            'url': 'https://cdn.example.com/thumb.png',
          },
        },
        'date_time_start': {r'$date': '2026-04-05T20:00:00Z'},
        'date_time_end': {r'$date': '2026-04-05T22:00:00Z'},
        'publication': {
          'status': 'published',
          'publish_at': {r'$date': '2026-04-05T18:00:00Z'},
        },
        'occurrences': [
          {
            'occurrence_id': 'occ-1',
            'date_time_start': {r'$date': '2026-04-05T20:00:00Z'},
            'date_time_end': {r'$date': '2026-04-05T22:00:00Z'},
          },
        ],
      },
    });

    expect(event.publication.status, 'published');
    expect(event.publication.publishAt, isNotNull);
    expect(event.occurrences, hasLength(1));
    expect(event.occurrences.first.dateTimeStart, isA<DateTime>());
    expect(event.occurrences.first.dateTimeEnd, isNotNull);
    expect(event.thumbUrl, 'https://cdn.example.com/thumb.png');
  });
}
