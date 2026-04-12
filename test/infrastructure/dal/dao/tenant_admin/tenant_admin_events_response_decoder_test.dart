import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_events_response_decoder.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = TenantAdminEventsResponseDecoder();

  test('decodes canonical visual payload for event types', () {
    final eventType = decoder.decodeEventTypeItem({
      'data': {
        'id': 'type-1',
        'name': 'Festival',
        'slug': 'festival',
        'description': 'Tipo com imagem canônica',
        'visual': {
          'mode': 'image',
          'image_source': 'type_asset',
          'image_url':
              'https://tenant.test/api/v1/media/event-types/type-1/type_asset?v=9',
        },
      },
    });

    expect(eventType.visual, isNotNull);
    expect(eventType.visual?.mode, TenantAdminPoiVisualMode.image);
    expect(
      eventType.visual?.imageSource,
      TenantAdminPoiVisualImageSource.typeAsset,
    );
    expect(
      eventType.visual?.imageUrl,
      'https://tenant.test/api/v1/media/event-types/type-1/type_asset?v=9',
    );
  });

  test('prefers related account profile ids from event_parties when available',
      () {
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
        'linked_account_profiles': [
          {
            'id': 'artist-1',
            'account_id': 'artist-1',
            'display_name': 'DJ One',
            'profile_type': 'artist',
          },
          {
            'id': 'producer-1',
            'account_id': 'producer-1',
            'display_name': 'Producer One',
            'profile_type': 'producer',
          },
        ],
      },
    });

    expect(
      event.relatedAccountProfileIds
          .map((entry) => entry.value)
          .toList(growable: false),
      ['artist-1', 'producer-1'],
    );
    expect(
      event.eventParties
          .map((entry) => entry.partyRefId)
          .toList(growable: false),
      ['artist-1', 'producer-1'],
    );
    expect(
      event.relatedAccountProfiles
          .map((entry) => entry.displayName)
          .toList(growable: false),
      ['DJ One', 'Producer One'],
    );
  });

  test('does not synthesize related profiles from legacy artists payload', () {
    final event = decoder.decodeEventItem({
      'data': {
        'event_id': 'evt-legacy-artists-only',
        'slug': 'evento-legacy',
        'title': 'Evento legado',
        'content': 'Conteudo',
        'type': {
          'id': 'type-1',
          'name': 'Show',
          'slug': 'show',
          'description': '',
        },
        'date_time_start': '2026-04-05T20:00:00+00:00',
        'publication': {'status': 'draft'},
        'artists': [
          {
            'id': 'artist-legacy-1',
            'display_name': 'Legacy Artist',
            'avatar_url': 'https://tenant.test/artist.png',
            'highlight': false,
            'genres': ['house'],
          },
        ],
      },
    });

    expect(event.relatedAccountProfileIds, isEmpty);
    expect(event.relatedAccountProfiles, isEmpty);
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

  test('rejects structured title payload instead of stringifying object values',
      () {
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
