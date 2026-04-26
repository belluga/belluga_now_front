import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_discovery_filters_settings_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_settings_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_settings_response_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = TenantAdminSettingsResponseDecoder();
  const encoder = TenantAdminSettingsRequestEncoder();

  test('decoder extracts discovery_filters and backfills legacy map filters',
      () {
    final settings = decoder.decodeDiscoveryFiltersSettings(
      {
        'data': {
          'map_ui': {
            'filters': [
              {
                'key': 'events',
                'label': 'Eventos',
                'query': {
                  'source': 'event',
                  'types': ['show'],
                  'taxonomy': ['music_genre:rock'],
                },
              },
            ],
          },
          'discovery_filters': const <String, dynamic>{},
        },
      },
      tenantOrigin: Uri.parse('https://tenant.test'),
    );

    final surfaces = settings.rawDiscoveryFilters.value['surfaces'] as Map;
    final publicMap = surfaces['public_map.primary'] as Map;
    expect(publicMap['target'], 'map_poi');
    final filter = (publicMap['filters'] as List).single as Map;
    expect(filter['query']['entities'], <String>['event']);
    expect(filter['query']['types_by_entity']['event'], <String>['show']);
    expect(filter['query']['taxonomy']['music_genre'], <String>['rock']);
  });

  test('decoder preserves explicit empty canonical map filters', () {
    final settings = decoder.decodeDiscoveryFiltersSettings(
      {
        'data': {
          'map_ui': {
            'filters': [
              {'key': 'legacy', 'label': 'Legacy'},
            ],
          },
          'discovery_filters': {
            'surfaces': {
              'public_map.primary': {
                'target': 'map_poi',
                'filters': const [],
              },
            },
          },
        },
      },
      tenantOrigin: Uri.parse('https://tenant.test'),
    );

    final surfaces = settings.rawDiscoveryFilters.value['surfaces'] as Map;
    final publicMap = surfaces['public_map.primary'] as Map;
    expect(publicMap['filters'], isEmpty);
  });

  test('decoder canonicalizes flat discovery filter surface response', () {
    final settings = decoder.decodeDiscoveryFiltersSettings(
      {
        'data': {
          'surfaces.public_map.primary.target': 'map_poi',
          'surfaces.public_map.primary.primary_selection_mode': 'single',
          'surfaces.public_map.primary.filters': [
            {
              'key': 'assets',
              'label': 'Assets',
              'image_uri': 'https://tenant.test/filter.png',
              'query': {
                'entities': ['static_asset'],
              },
            },
          ],
        },
      },
      tenantOrigin: Uri.parse('https://tenant.test'),
    );

    final surfaces = settings.rawDiscoveryFilters.value['surfaces'] as Map;
    final publicMap = surfaces['public_map.primary'] as Map;
    final filter = (publicMap['filters'] as List).single as Map;
    expect(publicMap['target'], 'map_poi');
    expect(filter['image_uri'], 'https://tenant.test/filter.png');
  });

  test('decoder canonicalizes nested discovery filter surface response', () {
    final settings = decoder.decodeDiscoveryFiltersSettings(
      {
        'data': {
          'surfaces': {
            'public_map': {
              'primary': {
                'target': 'map_poi',
                'filters': [
                  {
                    'key': 'assets',
                    'label': 'Assets',
                    'image_uri': 'https://tenant.test/filter.png',
                  },
                ],
              },
            },
          },
        },
      },
      tenantOrigin: Uri.parse('https://tenant.test'),
    );

    final surfaces = settings.rawDiscoveryFilters.value['surfaces'] as Map;
    final publicMap = surfaces['public_map.primary'] as Map;
    final filter = (publicMap['filters'] as List).single as Map;
    expect(publicMap['target'], 'map_poi');
    expect(filter['image_uri'], 'https://tenant.test/filter.png');
  });

  test('encoder preserves canonical discovery filter surfaces object', () {
    final payload = encoder.encodeDiscoveryFiltersSettingsPatch(
      TenantAdminDiscoveryFiltersSettingsValue(
        TenantAdminDynamicMapValue({
          'surfaces': {
            'home.events': {
              'target': 'event_occurrence',
              'filters': [
                {
                  'key': 'events',
                  'target': 'event_occurrence',
                  'label': 'Eventos',
                  'image_uri': 'https://tenant.test/filter.png',
                },
              ],
            },
          },
        }),
      ),
    );

    final surfaces = payload['surfaces'] as Map<String, dynamic>;
    final homeEvents = surfaces['home.events'] as Map<String, dynamic>;
    expect(homeEvents['target'], 'event_occurrence');
    expect(homeEvents['filters'], isA<List>());
    expect(
      (homeEvents['filters'] as List).single['image_uri'],
      'https://tenant.test/filter.png',
    );
    expect(payload.containsKey('surfaces.home.events.target'), isFalse);
  });
}
