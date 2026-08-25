import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/presentation/shared/discovery_filters/public_discovery_filter_empty_state_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses catalog order, effective group labels, and term order', () {
    final message = publicDiscoveryFilterEmptyStateMessage(
      catalog: _catalog,
      selection: const DiscoveryFilterSelection(
        primaryKeys: <String>{'profiles', 'events'},
        taxonomyTermKeys: <String, Set<String>>{
          'styles': <String>{'jazz', 'rock'},
          'regions': <String>{'south'},
        },
      ),
    );

    expect(
      message,
      'Nenhum resultado para os filtros selecionados: Eventos · Perfis · Estilos: Rock, Jazz · Região: Sul.',
    );
  });

  test('does not expose stale keys or taxonomy without a resolved primary', () {
    expect(
      publicDiscoveryFilterEmptyStateMessage(
        catalog: _catalog,
        selection: const DiscoveryFilterSelection(
          primaryKeys: <String>{'missing'},
          taxonomyTermKeys: <String, Set<String>>{
            'styles': <String>{'unknown'},
          },
        ),
      ),
      isNull,
    );
  });

  test('does not expose catalog items that the filter bar cannot render', () {
    const catalog = DiscoveryFilterCatalog(
      surface: 'home.events',
      filters: <DiscoveryFilterCatalogItem>[
        DiscoveryFilterCatalogItem(
          key: 'hidden',
          label: 'Hidden label',
          entities: <String>{},
          taxonomyConfigs: <String, DiscoveryFilterTaxonomyConfig>{
            'styles': DiscoveryFilterTaxonomyConfig(taxonomyKey: 'styles'),
          },
        ),
      ],
      taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
        'styles': DiscoveryFilterTaxonomyGroupOption(
          key: 'styles',
          label: 'Styles',
          terms: <DiscoveryFilterTaxonomyTermOption>[
            DiscoveryFilterTaxonomyTermOption(value: 'rock', label: 'Rock'),
          ],
        ),
      },
    );

    expect(
      publicDiscoveryFilterEmptyStateMessage(
        catalog: catalog,
        selection: const DiscoveryFilterSelection(
          primaryKeys: <String>{'hidden'},
          taxonomyTermKeys: <String, Set<String>>{
            'styles': <String>{'rock'},
          },
        ),
      ),
      isNull,
    );
  });

  test('formats a primary-only selection and omits stale terms', () {
    expect(
      publicDiscoveryFilterEmptyStateMessage(
        catalog: _catalog,
        selection: const DiscoveryFilterSelection(
          primaryKeys: <String>{'events'},
          taxonomyTermKeys: <String, Set<String>>{
            'styles': <String>{'missing'},
          },
        ),
      ),
      'Nenhum resultado para os filtros selecionados: Eventos.',
    );
  });

  test('uses the last selected catalog config for shared taxonomy labels', () {
    const catalog = DiscoveryFilterCatalog(
      surface: 'home.events',
      filters: <DiscoveryFilterCatalogItem>[
        DiscoveryFilterCatalogItem(
          key: 'first',
          label: 'First',
          entities: <String>{'event'},
          taxonomyConfigs: <String, DiscoveryFilterTaxonomyConfig>{
            'shared': DiscoveryFilterTaxonomyConfig(
              taxonomyKey: 'shared',
              labelOverride: 'First label',
            ),
          },
        ),
        DiscoveryFilterCatalogItem(
          key: 'last',
          label: 'Last',
          entities: <String>{'event'},
          taxonomyConfigs: <String, DiscoveryFilterTaxonomyConfig>{
            'shared': DiscoveryFilterTaxonomyConfig(
              taxonomyKey: 'shared',
              labelOverride: 'Last label',
            ),
          },
        ),
      ],
      taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
        'shared': DiscoveryFilterTaxonomyGroupOption(
          key: 'shared',
          label: 'Fallback',
          terms: <DiscoveryFilterTaxonomyTermOption>[
            DiscoveryFilterTaxonomyTermOption(value: 'x', label: 'X'),
          ],
        ),
      },
    );

    expect(
      publicDiscoveryFilterEmptyStateMessage(
        catalog: catalog,
        selection: const DiscoveryFilterSelection(
          primaryKeys: <String>{'last', 'first'},
          taxonomyTermKeys: <String, Set<String>>{
            'shared': <String>{'x'},
          },
        ),
      ),
      'Nenhum resultado para os filtros selecionados: First · Last · Last label: X.',
    );
  });

  test('uses the group label when a taxonomy override is whitespace', () {
    const catalog = DiscoveryFilterCatalog(
      surface: 'home.events',
      filters: <DiscoveryFilterCatalogItem>[
        DiscoveryFilterCatalogItem(
          key: 'events',
          label: 'Eventos',
          entities: <String>{'event'},
          taxonomyConfigs: <String, DiscoveryFilterTaxonomyConfig>{
            'styles': DiscoveryFilterTaxonomyConfig(
              taxonomyKey: 'styles',
              labelOverride: '   ',
            ),
          },
        ),
      ],
      taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
        'styles': DiscoveryFilterTaxonomyGroupOption(
          key: 'styles',
          label: 'Gêneros',
          terms: <DiscoveryFilterTaxonomyTermOption>[
            DiscoveryFilterTaxonomyTermOption(value: 'rock', label: 'Rock'),
          ],
        ),
      },
    );

    expect(
      publicDiscoveryFilterEmptyStateMessage(
        catalog: catalog,
        selection: const DiscoveryFilterSelection(
          primaryKeys: <String>{'events'},
          taxonomyTermKeys: <String, Set<String>>{
            'styles': <String>{'rock'},
          },
        ),
      ),
      'Nenhum resultado para os filtros selecionados: Eventos · Gêneros: Rock.',
    );
  });
}

const _catalog = DiscoveryFilterCatalog(
  surface: 'home.events',
  filters: <DiscoveryFilterCatalogItem>[
    DiscoveryFilterCatalogItem(
      key: 'events',
      label: 'Eventos',
      entities: <String>{'event'},
      taxonomyConfigs: <String, DiscoveryFilterTaxonomyConfig>{
        'styles': DiscoveryFilterTaxonomyConfig(
          taxonomyKey: 'styles',
          labelOverride: 'Estilos',
        ),
        'regions': DiscoveryFilterTaxonomyConfig(taxonomyKey: 'regions'),
      },
    ),
    DiscoveryFilterCatalogItem(
      key: 'profiles',
      label: 'Perfis',
      entities: <String>{'account_profile'},
    ),
  ],
  taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
    'styles': DiscoveryFilterTaxonomyGroupOption(
      key: 'styles',
      label: 'Gêneros',
      terms: <DiscoveryFilterTaxonomyTermOption>[
        DiscoveryFilterTaxonomyTermOption(value: 'rock', label: 'Rock'),
        DiscoveryFilterTaxonomyTermOption(value: 'jazz', label: 'Jazz'),
      ],
    ),
    'regions': DiscoveryFilterTaxonomyGroupOption(
      key: 'regions',
      label: 'Região',
      terms: <DiscoveryFilterTaxonomyTermOption>[
        DiscoveryFilterTaxonomyTermOption(value: 'south', label: 'Sul'),
      ],
    ),
  },
);
