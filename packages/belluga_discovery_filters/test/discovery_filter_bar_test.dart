import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('single primary keeps inactive icon chips and selected label',
      (tester) async {
    DiscoveryFilterSelection? changedSelection;

    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _catalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
          ),
          policy: const DiscoveryFilterPolicy(
            primarySelectionMode: DiscoveryFilterSelectionMode.single,
          ),
          onSelectionChanged: (selection) {
            changedSelection = selection;
          },
        ),
      ),
    );

    expect(
        find.byKey(
            const ValueKey<String>('discoveryFilterSelectedPrimary_events')),
        findsOneWidget);
    expect(find.text('Eventos'), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('discoveryFilterPrimary_profiles')),
        findsOneWidget);
    expect(find.text('Perfis'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('discoveryFilterPrimaryClear_events')),
    );

    expect(changedSelection?.primaryKeys, isEmpty);
  });

  testWidgets('renders taxonomy groups from active primary type options',
      (tester) async {
    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _catalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
          ),
          policy: const DiscoveryFilterPolicy(),
          onSelectionChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('discoveryFilterTaxonomyDivider')),
      findsOneWidget,
    );
    expect(
      find.byKey(
          const ValueKey<String>('discoveryFilterTaxonomyTitle_music_styles')),
      findsOneWidget,
    );
    expect(find.text('Estilos'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>(
          'discoveryFilterTaxonomyChip_music_styles_rock')),
      findsOneWidget,
    );
    expect(find.text('Rock'), findsOneWidget);
  });

  testWidgets('renders taxonomy groups from full catalog before primary select',
      (tester) async {
    DiscoveryFilterSelection? changedSelection;

    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _catalog,
          selection: const DiscoveryFilterSelection(),
          policy: const DiscoveryFilterPolicy(
            primarySelectionMode: DiscoveryFilterSelectionMode.single,
            taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
          ),
          onSelectionChanged: (selection) {
            changedSelection = selection;
          },
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('discoveryFilterTaxonomyDivider')),
      findsOneWidget,
    );
    expect(
      find.byKey(
          const ValueKey<String>('discoveryFilterTaxonomyTitle_music_styles')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>(
          'discoveryFilterTaxonomyChip_music_styles_rock')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>(
          'discoveryFilterTaxonomyChip_music_styles_rock')),
    );

    expect(changedSelection?.primaryKeys, isEmpty);
    expect(
      changedSelection?.taxonomyTermKeys['music_styles'],
      <String>{'rock'},
    );
  });

  testWidgets(
      'renders full catalog taxonomy groups when selected primary has no restriction',
      (tester) async {
    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _unrestrictedPrimaryCatalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'shows'},
          ),
          policy: const DiscoveryFilterPolicy(
            primarySelectionMode: DiscoveryFilterSelectionMode.single,
            taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('discoveryFilterTaxonomyDivider')),
      findsOneWidget,
    );
    expect(
      find.byKey(
          const ValueKey<String>('discoveryFilterTaxonomyTitle_music_styles')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>(
          'discoveryFilterTaxonomyChip_music_styles_rock')),
      findsOneWidget,
    );
  });

  testWidgets('does not reserve taxonomy divider space when catalog has none',
      (tester) async {
    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: const DiscoveryFilterCatalog(
            surface: 'home.events',
            filters: <DiscoveryFilterCatalogItem>[
              DiscoveryFilterCatalogItem(
                key: 'events',
                label: 'Eventos',
                entities: <String>{'event'},
              ),
            ],
          ),
          selection: const DiscoveryFilterSelection(),
          policy: const DiscoveryFilterPolicy(),
          onSelectionChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('discoveryFilterTaxonomyDivider')),
      findsNothing,
    );
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('taxonomy config can hide title and enforce single selection',
      (tester) async {
    DiscoveryFilterSelection? changedSelection;

    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _hiddenTitleCatalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
            taxonomyTermKeys: <String, Set<String>>{
              'music_styles': <String>{'rock'},
            },
          ),
          policy: const DiscoveryFilterPolicy(
            taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
          ),
          onSelectionChanged: (selection) {
            changedSelection = selection;
          },
        ),
      ),
    );

    expect(
      find.byKey(
          const ValueKey<String>('discoveryFilterTaxonomyTitle_music_styles')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>(
          'discoveryFilterSelectedTaxonomy_music_styles_rock')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>(
          'discoveryFilterTaxonomyChip_music_styles_jazz')),
    );

    expect(
      changedSelection?.taxonomyTermKeys['music_styles'],
      <String>{'jazz'},
    );
  });

  testWidgets('selected primary shows loading affordance while disabled',
      (tester) async {
    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _catalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
          ),
          policy: const DiscoveryFilterPolicy(),
          isLoading: true,
          onSelectionChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(
          const ValueKey<String>('discoveryFilterPrimaryLoading_events')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('discoveryFilterPrimaryClear_events')),
      findsNothing,
    );
  });
}

const _catalog = DiscoveryFilterCatalog(
  surface: 'public_map.primary',
  filters: <DiscoveryFilterCatalogItem>[
    DiscoveryFilterCatalogItem(
      key: 'events',
      label: 'Eventos',
      target: 'map_poi',
      entities: <String>{'event'},
      typesByEntity: <String, Set<String>>{
        'event': <String>{'show'},
      },
      taxonomyConfigs: <String, DiscoveryFilterTaxonomyConfig>{
        'music_styles': DiscoveryFilterTaxonomyConfig(
          taxonomyKey: 'music_styles',
          labelOverride: 'Estilos',
          showLabel: true,
          selectionMode: DiscoveryFilterSelectionMode.single,
        ),
      },
    ),
    DiscoveryFilterCatalogItem(
      key: 'profiles',
      label: 'Perfis',
      target: 'map_poi',
      entities: <String>{'account_profile'},
    ),
  ],
  typeOptionsByEntity: <String, List<DiscoveryFilterTypeOption>>{
    'event': <DiscoveryFilterTypeOption>[
      DiscoveryFilterTypeOption(
        value: 'show',
        label: 'Show',
        allowedTaxonomyKeys: <String>{'music_styles'},
      ),
    ],
  },
  taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
    'music_styles': DiscoveryFilterTaxonomyGroupOption(
      key: 'music_styles',
      label: 'Estilos musicais',
      terms: <DiscoveryFilterTaxonomyTermOption>[
        DiscoveryFilterTaxonomyTermOption(value: 'rock', label: 'Rock'),
        DiscoveryFilterTaxonomyTermOption(value: 'jazz', label: 'Jazz'),
      ],
    ),
  },
);

const _unrestrictedPrimaryCatalog = DiscoveryFilterCatalog(
  surface: 'home.events',
  filters: <DiscoveryFilterCatalogItem>[
    DiscoveryFilterCatalogItem(
      key: 'shows',
      label: 'Shows',
      target: 'event_occurrence',
      entities: <String>{'event'},
      typesByEntity: <String, Set<String>>{
        'event': <String>{'show'},
      },
    ),
  ],
  taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
    'music_styles': DiscoveryFilterTaxonomyGroupOption(
      key: 'music_styles',
      label: 'Estilos musicais',
      terms: <DiscoveryFilterTaxonomyTermOption>[
        DiscoveryFilterTaxonomyTermOption(value: 'rock', label: 'Rock'),
      ],
    ),
  },
);

const _hiddenTitleCatalog = DiscoveryFilterCatalog(
  surface: 'public_map.primary',
  filters: <DiscoveryFilterCatalogItem>[
    DiscoveryFilterCatalogItem(
      key: 'events',
      label: 'Eventos',
      target: 'map_poi',
      entities: <String>{'event'},
      typesByEntity: <String, Set<String>>{
        'event': <String>{'show'},
      },
      taxonomyConfigs: <String, DiscoveryFilterTaxonomyConfig>{
        'music_styles': DiscoveryFilterTaxonomyConfig(
          taxonomyKey: 'music_styles',
          labelOverride: 'Estilos',
          showLabel: false,
          selectionMode: DiscoveryFilterSelectionMode.single,
        ),
      },
    ),
  ],
  typeOptionsByEntity: <String, List<DiscoveryFilterTypeOption>>{
    'event': <DiscoveryFilterTypeOption>[
      DiscoveryFilterTypeOption(
        value: 'show',
        label: 'Show',
        allowedTaxonomyKeys: <String>{'music_styles'},
      ),
    ],
  },
  taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
    'music_styles': DiscoveryFilterTaxonomyGroupOption(
      key: 'music_styles',
      label: 'Estilos musicais',
      terms: <DiscoveryFilterTaxonomyTermOption>[
        DiscoveryFilterTaxonomyTermOption(value: 'rock', label: 'Rock'),
        DiscoveryFilterTaxonomyTermOption(value: 'jazz', label: 'Jazz'),
      ],
    ),
  },
);

class _Harness extends StatelessWidget {
  const _Harness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
