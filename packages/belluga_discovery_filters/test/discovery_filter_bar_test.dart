import 'dart:io';

import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets('does not render taxonomy groups before any primary is selected',
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
      findsNothing,
    );
    expect(
      find.byKey(
          const ValueKey<String>('discoveryFilterTaxonomyTitle_music_styles')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>(
          'discoveryFilterTaxonomyChip_music_styles_rock')),
      findsNothing,
    );
    expect(changedSelection, isNull);
  });

  testWidgets(
      'does not render taxonomy groups when selected primary has no allowed scope',
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
      findsNothing,
    );
    expect(
      find.byKey(
          const ValueKey<String>('discoveryFilterTaxonomyTitle_music_styles')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>(
          'discoveryFilterTaxonomyChip_music_styles_rock')),
      findsNothing,
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

  testWidgets('primary chips expose semantic wrappers and selected state',
      (tester) async {
    DiscoveryFilterSelection? changedSelection;

    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _catalog,
          selection: const DiscoveryFilterSelection(),
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
        const ValueKey<String>('discoveryFilterPrimarySemantics_events'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('discoveryFilterPrimarySemantics_events'),
      ),
    );
    await tester.pump();

    expect(changedSelection?.primaryKeys, <String>{'events'});

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
          onSelectionChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>(
            'discoveryFilterSelectedPrimarySemantics_events'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('taxonomy chips expose actionable semantic tap', (tester) async {
    DiscoveryFilterSelection? changedSelection;

    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _catalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
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

    final semantics = tester
        .getSemantics(
          find.byKey(
            const ValueKey<String>(
              'discoveryFilterTaxonomySemantics_music_styles_rock',
            ),
          ),
        )
        .getSemanticsData();

    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    expect(semantics.flagsCollection.isButton, isTrue);

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'discoveryFilterTaxonomySemantics_music_styles_rock',
        ),
      ),
    );
    await tester.pump();

    expect(
      changedSelection?.taxonomyTermKeys['music_styles'],
      <String>{'rock'},
    );
  });

  testWidgets('row taxonomy layout virtualizes large term lists',
      (tester) async {
    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _largeTaxonomyCatalog(),
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
          ),
          policy: const DiscoveryFilterPolicy(
            taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('discoveryFilterTaxonomyList_music_styles'),
      ),
      findsOneWidget,
    );
    expect(find.text('Term 0'), findsOneWidget);
    expect(find.text('Term 99'), findsNothing);
  });

  testWidgets('row primary layout reveals the selected chip inside viewport',
      (tester) async {
    await tester.pumpWidget(
      _NarrowHarness(
        width: 180,
        child: DiscoveryFilterBar(
          catalog: _widePrimaryCatalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'theatre'},
          ),
          policy: const DiscoveryFilterPolicy(
            primarySelectionMode: DiscoveryFilterSelectionMode.single,
            primaryLayoutMode: DiscoveryFilterLayoutMode.row,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    final viewportRect =
        tester.getRect(find.byKey(const ValueKey<String>('narrowHarness')));
    final selectedRect = tester.getRect(
      find.byKey(
        const ValueKey<String>('discoveryFilterSelectedPrimary_theatre'),
      ),
    );

    expect(selectedRect.left, greaterThanOrEqualTo(viewportRect.left - 0.1));
    expect(selectedRect.right, lessThanOrEqualTo(viewportRect.right + 0.1));
  });

  testWidgets('row taxonomy layout reveals the selected term inside viewport',
      (tester) async {
    await tester.pumpWidget(
      _NarrowHarness(
        width: 180,
        child: DiscoveryFilterBar(
          catalog: _scrollingTaxonomyCatalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
            taxonomyTermKeys: <String, Set<String>>{
              'music_styles': <String>{'samba'},
            },
          ),
          policy: const DiscoveryFilterPolicy(
            taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
            taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    final viewportRect =
        tester.getRect(find.byKey(const ValueKey<String>('narrowHarness')));
    final selectedRect = tester.getRect(
      find.byKey(
        const ValueKey<String>(
          'discoveryFilterSelectedTaxonomy_music_styles_samba',
        ),
      ),
    );

    expect(selectedRect.left, greaterThanOrEqualTo(viewportRect.left - 0.1));
    expect(selectedRect.right, lessThanOrEqualTo(viewportRect.right + 0.1));
  });

  test('horizontal primary row does not prebuild unused chip widgets', () {
    final source = File(
      'packages/belluga_discovery_filters/lib/src/discovery_filter_bar.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('final chips = filters')));
    expect(source, contains('discoveryFilterPrimaryList'));
  });

  testWidgets('iconBuilder receives the same foreground color as the label',
      (tester) async {
    Color? capturedForeground;

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
          iconBuilder: (context, item, isActive, foregroundColor) {
            if (item.key == 'events' && isActive) {
              capturedForeground = foregroundColor;
            }
            return Icon(Icons.ac_unit, color: foregroundColor);
          },
          onSelectionChanged: (_) {},
        ),
      ),
    );

    final labelText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('discoveryFilterSelectedPrimary_events'),
        ),
        matching: find.text('Eventos'),
      ),
    );
    expect(capturedForeground, labelText.style?.color);
  });
}

const _widePrimaryCatalog = DiscoveryFilterCatalog(
  surface: 'home.events',
  filters: <DiscoveryFilterCatalogItem>[
    DiscoveryFilterCatalogItem(
      key: 'music',
      label: 'Música',
      target: 'event_occurrence',
      entities: <String>{'event'},
    ),
    DiscoveryFilterCatalogItem(
      key: 'food',
      label: 'Comida',
      target: 'event_occurrence',
      entities: <String>{'event'},
    ),
    DiscoveryFilterCatalogItem(
      key: 'theatre',
      label: 'Teatro',
      target: 'event_occurrence',
      entities: <String>{'event'},
    ),
  ],
);

const _scrollingTaxonomyCatalog = DiscoveryFilterCatalog(
  surface: 'home.events',
  filters: <DiscoveryFilterCatalogItem>[
    DiscoveryFilterCatalogItem(
      key: 'events',
      label: 'Eventos',
      target: 'event_occurrence',
      entities: <String>{'event'},
      typesByEntity: <String, Set<String>>{
        'event': <String>{'show'},
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
        DiscoveryFilterTaxonomyTermOption(value: 'mpb', label: 'MPB'),
        DiscoveryFilterTaxonomyTermOption(value: 'samba', label: 'Samba'),
      ],
    ),
  },
);

DiscoveryFilterCatalog _largeTaxonomyCatalog() {
  return DiscoveryFilterCatalog(
    surface: 'home.events',
    filters: const <DiscoveryFilterCatalogItem>[
      DiscoveryFilterCatalogItem(
        key: 'events',
        label: 'Eventos',
        target: 'event_occurrence',
        entities: <String>{'event'},
        typesByEntity: <String, Set<String>>{
          'event': <String>{'show'},
        },
      ),
    ],
    typeOptionsByEntity: const <String, List<DiscoveryFilterTypeOption>>{
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
        terms: List<DiscoveryFilterTaxonomyTermOption>.generate(
          100,
          (index) => DiscoveryFilterTaxonomyTermOption(
            value: 'term_$index',
            label: 'Term $index',
          ),
        ),
      ),
    },
  );
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

class _NarrowHarness extends StatelessWidget {
  const _NarrowHarness({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: const ValueKey<String>('narrowHarness'),
            width: width,
            child: child,
          ),
        ),
      ),
    );
  }
}
