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
}
