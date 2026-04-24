import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses canonical catalog item payload', () {
    final item = DiscoveryFilterCatalogItem.fromJson(
      <String, Object?>{
        'key': 'events',
        'label': 'Eventos',
        'icon_key': 'music',
        'color_hex': '#D71920',
        'target': 'map_poi',
        'query': <String, Object?>{
          'entity': 'event_occurrence',
          'types': <String>['show', 'fair'],
          'taxonomies': <String>['music_styles'],
        },
        'taxonomy_configs': <String, Object?>{
          'music_styles': <String, Object?>{
            'label_override': 'Estilos',
            'show_label': true,
            'selection_mode': 'multiple',
          },
        },
      },
    );

    expect(item.isValid, isTrue);
    expect(item.entities, <String>{'event_occurrence'});
    expect(item.types, <String>{'show', 'fair'});
    expect(item.taxonomyKeys, <String>{'music_styles'});
    expect(item.taxonomyConfigs['music_styles']?.labelOverride, 'Estilos');
    expect(
      item.taxonomyConfigs['music_styles']?.selectionMode,
      DiscoveryFilterSelectionMode.multiple,
    );
  });

  test('parses Laravel grouped entity type and taxonomy payload', () {
    final item = DiscoveryFilterCatalogItem.fromJson(
      <String, Object?>{
        'key': 'events',
        'label': 'Eventos',
        'target': 'map_poi',
        'query': <String, Object?>{
          'entities': <String>['event', 'event_occurrence'],
          'types_by_entity': <String, Object?>{
            'event': <String>['show'],
            'event_occurrence': <String>['fair'],
          },
          'taxonomy': <String, Object?>{
            'music_styles': <String>['rock', 'jazz'],
            'audience': <String>['family'],
          },
        },
      },
    );

    expect(item.entities, <String>{'event', 'event_occurrence'});
    expect(item.types, <String>{'show', 'fair'});
    expect(item.typesByEntity, <String, Set<String>>{
      'event': <String>{'show'},
      'event_occurrence': <String>{'fair'},
    });
    expect(item.taxonomyKeys, <String>{'music_styles', 'audience'});
    expect(item.taxonomyValuesByGroup, <String, Set<String>>{
      'music_styles': <String>{'rock', 'jazz'},
      'audience': <String>{'family'},
    });
    expect(item.toJson()['query'], <String, Object?>{
      'entities': <String>['event', 'event_occurrence'],
      'types_by_entity': <String, List<String>>{
        'event': <String>['show'],
        'event_occurrence': <String>['fair'],
      },
      'taxonomy': <String, List<String>>{
        'music_styles': <String>['rock', 'jazz'],
        'audience': <String>['family'],
      },
    });
  });

  test('parses canonical catalog envelope with entity type options', () {
    final catalog = DiscoveryFilterCatalog.fromJson(
      <String, Object?>{
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
            },
          },
        ],
        'type_options': <String, Object?>{
          'event': <Object?>[
            <String, Object?>{
              'value': 'show',
              'label': 'Show',
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

    expect(catalog.surface, 'public_map.primary');
    expect(catalog.filters.single.key, 'events');
    expect(catalog.typeOptionsByEntity.keys, <String>{'event'});
    expect(catalog.typeOptionsByEntity['event']?.single.value, 'show');
    expect(
      catalog.typeOptionsByEntity['event']?.single.allowedTaxonomyKeys,
      <String>{'music_styles'},
    );
    expect(catalog.taxonomyOptionsByKey['music_styles']?.label,
        'Estilos musicais');
    expect(
      catalog.taxonomyOptionsByKey['music_styles']?.terms.single.value,
      'rock',
    );
    expect(catalog.isEmpty, isFalse);
  });

  test('registry resolves entity-qualified type options', () {
    final registry = DiscoveryFilterEntityRegistry(
      providers: <DiscoveryFilterEntityProvider>[
        _StaticProvider(
          entity: 'event',
          options: const <DiscoveryFilterTypeOption>[
            DiscoveryFilterTypeOption(
              value: 'show',
              label: 'Show',
              allowedTaxonomyKeys: <String>{'music_styles'},
            ),
          ],
        ),
      ],
    );

    expect(registry.entities, <String>{'event'});
    final options = registry.typeOptionsForEntities(<String>['event', 'asset']);
    expect(options.keys, <String>{'event'});
    expect(options['event']?.single.value, 'show');
    expect(
      options['event']?.single.allowedTaxonomyKeys,
      <String>{'music_styles'},
    );
  });

  test('selection toggles single primary and multi taxonomy terms', () {
    final selection = const DiscoveryFilterSelection()
        .togglePrimary('events')
        .togglePrimary('profiles')
        .toggleTaxonomyTerm('music_styles', 'rock')
        .toggleTaxonomyTerm('music_styles', 'jazz');

    expect(selection.primaryKeys, <String>{'profiles'});
    expect(
        selection.taxonomyTermKeys['music_styles'], <String>{'rock', 'jazz'});
    expect(selection.activeCount, 3);
  });

  test('repair drops taxonomy selections when no primary is selected', () {
    const policy = DiscoveryFilterPolicy(
      primarySelectionMode: DiscoveryFilterSelectionMode.single,
      taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
    );
    const catalog = DiscoveryFilterCatalog(
      surface: 'home.events',
      filters: <DiscoveryFilterCatalogItem>[
        DiscoveryFilterCatalogItem(
          key: 'show',
          label: 'Show',
          entities: <String>{'event'},
          typesByEntity: <String, Set<String>>{
            'event': <String>{'show'},
          },
        ),
      ],
      taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
        'music_styles': DiscoveryFilterTaxonomyGroupOption(
          key: 'music_styles',
          label: 'Estilos',
          terms: <DiscoveryFilterTaxonomyTermOption>[
            DiscoveryFilterTaxonomyTermOption(value: 'rock', label: 'Rock'),
            DiscoveryFilterTaxonomyTermOption(value: 'samba', label: 'Samba'),
          ],
        ),
      },
    );

    final result = const DiscoveryFilterSelectionRepair().repair(
      selection: const DiscoveryFilterSelection(
        taxonomyTermKeys: <String, Set<String>>{
          'music_styles': <String>{'rock', 'pagode'},
        },
      ),
      catalog: catalog.filters,
      catalogEnvelope: catalog,
      policy: policy,
    );

    expect(result.changed, isTrue);
    expect(result.selection.primaryKeys, isEmpty);
    expect(result.selection.taxonomyTermKeys, isEmpty);
    expect(
      result.droppedTaxonomyTerms['music_styles'],
      <String>{'rock', 'pagode'},
    );
  });

  test('repair derives taxonomy allowance from selected type option catalog',
      () {
    const policy = DiscoveryFilterPolicy(
      primarySelectionMode: DiscoveryFilterSelectionMode.single,
      taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
    );
    const catalog = DiscoveryFilterCatalog(
      surface: 'discovery.account_profiles',
      filters: <DiscoveryFilterCatalogItem>[
        DiscoveryFilterCatalogItem(
          key: 'venues',
          label: 'Locais',
          entities: <String>{'account_profile'},
          typesByEntity: <String, Set<String>>{
            'account_profile': <String>{'venue'},
          },
        ),
      ],
      typeOptionsByEntity: <String, List<DiscoveryFilterTypeOption>>{
        'account_profile': <DiscoveryFilterTypeOption>[
          DiscoveryFilterTypeOption(
            value: 'venue',
            label: 'Local',
            allowedTaxonomyKeys: <String>{'cuisine'},
          ),
        ],
      },
      taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
        'cuisine': DiscoveryFilterTaxonomyGroupOption(
          key: 'cuisine',
          label: 'Cozinha',
          terms: <DiscoveryFilterTaxonomyTermOption>[
            DiscoveryFilterTaxonomyTermOption(
                value: 'japanese', label: 'Japonesa'),
          ],
        ),
      },
    );

    final result = const DiscoveryFilterSelectionRepair().repair(
      selection: const DiscoveryFilterSelection(
        primaryKeys: <String>{'venues'},
        taxonomyTermKeys: <String, Set<String>>{
          'cuisine': <String>{'japanese'},
        },
      ),
      catalog: catalog.filters,
      catalogEnvelope: catalog,
      policy: policy,
    );

    expect(result.changed, isFalse);
    expect(result.selection.taxonomyTermKeys, <String, Set<String>>{
      'cuisine': <String>{'japanese'},
    });
  });

  test(
      'repair drops taxonomy selections when selected primary has no allowed scope',
      () {
    const policy = DiscoveryFilterPolicy(
      primarySelectionMode: DiscoveryFilterSelectionMode.single,
      taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
    );
    const catalog = DiscoveryFilterCatalog(
      surface: 'home.events',
      filters: <DiscoveryFilterCatalogItem>[
        DiscoveryFilterCatalogItem(
          key: 'shows',
          label: 'Shows',
          entities: <String>{'event'},
          typesByEntity: <String, Set<String>>{
            'event': <String>{'show'},
          },
        ),
      ],
      taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
        'music_styles': DiscoveryFilterTaxonomyGroupOption(
          key: 'music_styles',
          label: 'Estilos',
          terms: <DiscoveryFilterTaxonomyTermOption>[
            DiscoveryFilterTaxonomyTermOption(value: 'rock', label: 'Rock'),
          ],
        ),
      },
    );

    final result = const DiscoveryFilterSelectionRepair().repair(
      selection: const DiscoveryFilterSelection(
        primaryKeys: <String>{'shows'},
        taxonomyTermKeys: <String, Set<String>>{
          'music_styles': <String>{'rock'},
        },
      ),
      catalog: catalog.filters,
      catalogEnvelope: catalog,
      policy: policy,
    );

    expect(result.changed, isTrue);
    expect(result.selection.taxonomyTermKeys, isEmpty);
    expect(result.droppedTaxonomyTerms['music_styles'], <String>{'rock'});
  });

  test('repair drops stale primary and taxonomy selections', () {
    const policy = DiscoveryFilterPolicy();
    const repair = DiscoveryFilterSelectionRepair();
    const catalog = <DiscoveryFilterCatalogItem>[
      DiscoveryFilterCatalogItem(
        key: 'events',
        label: 'Eventos',
        entities: <String>{'event_occurrence'},
        taxonomyKeys: <String>{'music_styles'},
      ),
    ];

    final result = repair.repair(
      selection: const DiscoveryFilterSelection(
        primaryKeys: <String>{'events', 'obsolete'},
        taxonomyTermKeys: <String, Set<String>>{
          'music_styles': <String>{'rock', 'jazz'},
          'obsolete_taxonomy': <String>{'old'},
        },
      ),
      catalog: catalog,
      policy: policy,
    );

    expect(result.changed, isTrue);
    expect(result.selection.primaryKeys, <String>{'events'});
    expect(result.selection.taxonomyTermKeys, <String, Set<String>>{
      'music_styles': <String>{'rock', 'jazz'},
    });
    expect(result.droppedPrimaryKeys, <String>{'obsolete'});
    expect(result.droppedTaxonomyTerms['obsolete_taxonomy'], <String>{'old'});
  });

  test('repair enforces single primary and single taxonomy policy', () {
    const policy = DiscoveryFilterPolicy(
      primarySelectionMode: DiscoveryFilterSelectionMode.single,
      taxonomySelectionMode: DiscoveryFilterSelectionMode.single,
    );
    const repair = DiscoveryFilterSelectionRepair();
    const catalog = <DiscoveryFilterCatalogItem>[
      DiscoveryFilterCatalogItem(
        key: 'events',
        label: 'Eventos',
        entities: <String>{'event_occurrence'},
        taxonomyKeys: <String>{'music_styles'},
      ),
      DiscoveryFilterCatalogItem(
        key: 'profiles',
        label: 'Perfis',
        entities: <String>{'account_profile'},
        taxonomyKeys: <String>{'music_styles'},
      ),
    ];

    final result = repair.repair(
      selection: const DiscoveryFilterSelection(
        primaryKeys: <String>{'events', 'profiles'},
        taxonomyTermKeys: <String, Set<String>>{
          'music_styles': <String>{'rock', 'jazz'},
        },
      ),
      catalog: catalog,
      policy: policy,
    );

    expect(result.changed, isTrue);
    expect(result.selection.primaryKeys, <String>{'events'});
    expect(result.selection.taxonomyTermKeys['music_styles'], <String>{'rock'});
    expect(result.droppedPrimaryKeys, <String>{'profiles'});
    expect(result.droppedTaxonomyTerms['music_styles'], <String>{'jazz'});
  });

  test('compiles canonical query payload from selected filters and taxonomy',
      () {
    final catalog = DiscoveryFilterCatalog.fromJson(
      <String, Object?>{
        'surface': 'home.events',
        'filters': <Object?>[
          <String, Object?>{
            'key': 'events',
            'label': 'Eventos',
            'target': 'event_occurrence',
            'query': <String, Object?>{
              'entities': <String>['event'],
              'types_by_entity': <String, Object?>{
                'event': <String>['show', 'fair'],
              },
              'taxonomy': <String, Object?>{
                'audience': <String>['family'],
              },
            },
          },
          <String, Object?>{
            'key': 'profiles',
            'label': 'Perfis',
            'target': 'account_profile',
            'query': <String, Object?>{
              'entity': 'account_profile',
              'types': <String>['venue'],
            },
          },
        ],
      },
    );

    final payload = DiscoveryFilterQueryPayload.compile(
      catalog: catalog,
      selection: const DiscoveryFilterSelection(
        primaryKeys: <String>{'events'},
        taxonomyTermKeys: <String, Set<String>>{
          'music_styles': <String>{'rock', 'jazz'},
        },
      ),
    );

    expect(payload.entities, <String>{'event'});
    expect(payload.typesForEntity('event'), <String>{'show', 'fair'});
    expect(payload.typesForEntity('account_profile'), isEmpty);
    expect(payload.taxonomyTermsByGroup, <String, Set<String>>{
      'audience': <String>{'family'},
      'music_styles': <String>{'rock', 'jazz'},
    });
    expect(
      payload.taxonomyEntries.map((entry) => entry.toJson()).toSet(),
      <Map<String, String>>{
        <String, String>{'type': 'audience', 'value': 'family'},
        <String, String>{'type': 'music_styles', 'value': 'rock'},
        <String, String>{'type': 'music_styles', 'value': 'jazz'},
      },
    );
  });

  test('compile ignores taxonomy-only selections when no primary is selected',
      () {
    final catalog = DiscoveryFilterCatalog.fromJson(
      <String, Object?>{
        'surface': 'home.events',
        'filters': <Object?>[
          <String, Object?>{
            'key': 'events',
            'label': 'Eventos',
            'target': 'event_occurrence',
            'query': <String, Object?>{
              'entities': <String>['event'],
              'types_by_entity': <String, Object?>{
                'event': <String>['show'],
              },
            },
          },
        ],
      },
    );

    final payload = DiscoveryFilterQueryPayload.compile(
      catalog: catalog,
      selection: const DiscoveryFilterSelection(
        taxonomyTermKeys: <String, Set<String>>{
          'music_styles': <String>{'rock'},
        },
      ),
    );

    expect(payload.entities, isEmpty);
    expect(payload.typesByEntity, isEmpty);
    expect(payload.taxonomyTermsByGroup, isEmpty);
    expect(payload.taxonomyEntries, isEmpty);
    expect(payload.isEmpty, isTrue);
  });
}

class _StaticProvider implements DiscoveryFilterEntityProvider {
  const _StaticProvider({
    required this.entity,
    required this.options,
  });

  @override
  final String entity;

  final List<DiscoveryFilterTypeOption> options;

  @override
  List<DiscoveryFilterTypeOption> typeOptions() => options;

  @override
  List<DiscoveryFilterTaxonomyOption> taxonomiesForTypes(Set<String> typeKeys) {
    return const <DiscoveryFilterTaxonomyOption>[
      DiscoveryFilterTaxonomyOption(
        key: 'music_styles',
        label: 'Estilos musicais',
      ),
    ];
  }
}
