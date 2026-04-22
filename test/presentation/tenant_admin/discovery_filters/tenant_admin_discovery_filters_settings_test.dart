import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_item.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_items.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_query.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filters_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads legacy map_ui filters as canonical public map surface', () {
    final settings = TenantAdminDiscoveryFiltersSettings.fromRaw(
      discoveryFilters: const <String, dynamic>{},
      legacyMapUi: const <String, dynamic>{
        'filters': [
          {
            'key': 'events',
            'label': 'Eventos',
            'image_uri': 'https://tenant.test/map-filters/events.png',
            'query': {
              'source': 'event',
              'types': ['show'],
              'taxonomy': ['music_genre:rock'],
            },
          },
        ],
      },
    );

    final filters = settings.filtersForSurface('public_map.primary');
    expect(filters, hasLength(1));
    final filter = filters.first;
    expect(filter.key, 'events');
    expect(filter.label, 'Eventos');
    expect(filter.query.entities, <String>['event']);
    expect(
      filter.query.typeValuesByEntity['event']!
          .map((entry) => entry.value)
          .toList(),
      <String>['show'],
    );
    expect(
      filter.query.taxonomyValuesByGroup['music_genre']!
          .map((entry) => entry.value)
          .toList(),
      <String>['rock'],
    );
  });

  test('applies surface filters with canonical target and query payload', () {
    final item = TenantAdminDiscoveryFilterCatalogItem(
      keyValue: TenantAdminLowercaseTokenValue.fromRaw('events'),
      labelValue: TenantAdminRequiredTextValue()..parse('Eventos'),
      query: TenantAdminDiscoveryFilterQuery(
        entityValues: [TenantAdminLowercaseTokenValue.fromRaw('event')],
        typeValuesByEntity: {
          'event': [TenantAdminLowercaseTokenValue.fromRaw('show')],
        },
        taxonomyValuesByGroup: {
          'music_genre': [TenantAdminLowercaseTokenValue.fromRaw('rock')],
        },
      ),
    );

    final settings = TenantAdminDiscoveryFiltersSettings.empty().applyFilters(
      surface: TenantAdminDiscoveryFilterSurfaceDefinition.homeEvents,
      filters: TenantAdminDiscoveryFilterCatalogItems([item]),
    );

    final raw = settings.rawDiscoveryFilters.value;
    final surface = (raw['surfaces'] as Map)['home.events'] as Map;
    expect(surface['target'], 'event_occurrence');
    expect(surface['primary_selection_mode'], 'single');
    expect(surface['filters'], hasLength(1));
    final filter = (surface['filters'] as List).single as Map;
    expect(filter['target'], 'event_occurrence');
    expect(filter['query']['entities'], <String>['event']);
    expect(filter['query']['types_by_entity']['event'], <String>['show']);
    expect(filter['query']['taxonomy']['music_genre'], <String>['rock']);
  });
}
