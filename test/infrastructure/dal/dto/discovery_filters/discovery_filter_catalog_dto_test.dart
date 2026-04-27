import 'package:belluga_now/infrastructure/dal/dto/discovery_filters/discovery_filter_catalog_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps public discovery filter catalog payload to package domain', () {
    final dto = DiscoveryFilterCatalogDTO.fromJson(
      <String, dynamic>{
        'surface': 'public_map.primary',
        'filters': <Object?>[
          <String, Object?>{
            'key': 'events',
            'label': 'Eventos',
            'target': 'map_poi',
            'query': <String, Object?>{
              'entities': <String>['event'],
              'types_by_entity': <String, Object?>{
                'event': <String>['show'],
              },
              'taxonomy': <String, Object?>{
                'music_styles': <String>['rock'],
              },
            },
          },
        ],
        'type_options': <String, Object?>{
          'event': <Object?>[
            <String, Object?>{
              'value': 'show',
              'label': 'Show',
              'visual': <String, Object?>{
                'mode': 'image',
                'image_source': 'type_asset',
                'image_url': 'https://tenant.test/types/show.png',
                'color': '#D81B60',
              },
              'allowed_taxonomies': <String>['music_styles'],
            },
          ],
        },
        'taxonomy_options': <String, Object?>{
          'music_styles': <String, Object?>{
            'key': 'music_styles',
            'label': 'Estilos musicais',
            'terms': <Object?>[
              <String, Object?>{
                'value': 'rock',
                'label': 'Rock',
              },
            ],
          },
        },
      },
    );

    final catalog = dto.toDomain();

    expect(catalog.surface, 'public_map.primary');
    expect(catalog.filters.single.key, 'events');
    expect(catalog.filters.single.typesByEntity, <String, Set<String>>{
      'event': <String>{'show'},
    });
    expect(
        catalog.filters.single.imageUri, 'https://tenant.test/types/show.png');
    expect(catalog.filters.single.colorHex, '#D81B60');
    expect(catalog.filters.single.taxonomyValuesByGroup, <String, Set<String>>{
      'music_styles': <String>{'rock'},
    });
    expect(catalog.typeOptionsByEntity['event']?.single.label, 'Show');
    expect(catalog.taxonomyOptionsByKey['music_styles']?.label,
        'Estilos musicais');
    expect(
      catalog.taxonomyOptionsByKey['music_styles']?.terms.single.value,
      'rock',
    );
  });
}
