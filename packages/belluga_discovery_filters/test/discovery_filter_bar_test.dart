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

    expect(find.byKey(const ValueKey<String>('discoveryFilterPrimary_events')),
        findsOneWidget);
    expect(find.text('Eventos'), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('discoveryFilterPrimary_profiles')),
        findsOneWidget);
    expect(find.text('Perfis'), findsOneWidget);

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
          'discoveryFilterTaxonomyChip_music_styles_rock')),
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

  testWidgets(
      'selected primary shows loading affordance while inactive options stay actionable',
      (tester) async {
    DiscoveryFilterSelection? changedSelection;

    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _catalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
          ),
          policy: const DiscoveryFilterPolicy(),
          isLoading: true,
          onSelectionChanged: (selection) {
            changedSelection = selection;
          },
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

    await tester.tap(
      find.byKey(const ValueKey<String>('discoveryFilterPrimary_profiles')),
    );
    await tester.pump();

    expect(changedSelection?.primaryKeys, <String>{'profiles'});
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
    expect(find.text('Eventos'), findsOneWidget);
    expect(find.text('Perfis'), findsOneWidget);

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
        const ValueKey<String>('discoveryFilterPrimarySemantics_events'),
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

  testWidgets('row taxonomy layout eagerly mounts the nominal term envelope',
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
    expect(find.text('Term 99'), findsOneWidget);
  });

  testWidgets('hidden reveal opt-out emits no horizontal scroll activity',
      (tester) async {
    var horizontalNotifications = 0;
    await tester.pumpWidget(
      _NarrowHarness(
        width: 180,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.horizontal) {
              horizontalNotifications++;
            }
            return false;
          },
          child: DiscoveryFilterBar(
            catalog: _widePrimaryCatalog,
            selection: const DiscoveryFilterSelection(
              primaryKeys: <String>{'theatre'},
            ),
            policy: const DiscoveryFilterPolicy(
              primaryLayoutMode: DiscoveryFilterLayoutMode.row,
            ),
            autoRevealSelectedChips: false,
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(horizontalNotifications, 0);
    expect(
      tester
          .getRect(find.byKey(const ValueKey<String>(
            'discoveryFilterPrimary_theatre',
          )))
          .left,
      greaterThan(180),
    );
  });

  testWidgets('equivalent rebuild does not replay the primary reveal',
      (tester) async {
    var horizontalNotifications = 0;
    Widget build() => _NarrowHarness(
          width: 180,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.horizontal) {
                horizontalNotifications++;
              }
              return false;
            },
            child: DiscoveryFilterBar(
              key: const ValueKey<String>('stableBar'),
              catalog: _widePrimaryCatalog,
              selection: const DiscoveryFilterSelection(
                primaryKeys: <String>{'theatre'},
              ),
              policy: const DiscoveryFilterPolicy(
                primaryLayoutMode: DiscoveryFilterLayoutMode.row,
              ),
              onSelectionChanged: (_) {},
            ),
          ),
        );

    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    final afterFirstReveal = horizontalNotifications;
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(afterFirstReveal, greaterThan(0));
    expect(horizontalNotifications, afterFirstReveal);
  });

  testWidgets('pending reveal follows the latest hydrated anchor',
      (tester) async {
    Widget build(DiscoveryFilterSelection selection) => _NarrowHarness(
          width: 180,
          child: DiscoveryFilterBar(
            key: const ValueKey<String>('latestAnchorBar'),
            catalog: _widePrimaryCatalog,
            selection: selection,
            policy: const DiscoveryFilterPolicy(
              primaryLayoutMode: DiscoveryFilterLayoutMode.row,
            ),
            onSelectionChanged: (_) {},
          ),
        );

    await tester.pumpWidget(build(const DiscoveryFilterSelection()));
    await tester.pumpWidget(
      build(const DiscoveryFilterSelection(primaryKeys: <String>{'food'})),
    );
    await tester.pumpWidget(
      build(const DiscoveryFilterSelection(primaryKeys: <String>{'theatre'})),
    );
    await tester.pumpAndSettle();

    final theatre = tester.getRect(
      find.byKey(const ValueKey<String>('discoveryFilterPrimary_theatre')),
    );
    expect(theatre.right, lessThanOrEqualTo(180));
  });

  testWidgets('primary catalog arrival reveals a persisted selected anchor',
      (tester) async {
    Widget build(DiscoveryFilterCatalog catalog) => _NarrowHarness(
          width: 180,
          child: DiscoveryFilterBar(
            key: const ValueKey<String>('primaryCatalogArrival'),
            catalog: catalog,
            selection: const DiscoveryFilterSelection(
              primaryKeys: <String>{'theatre'},
            ),
            policy: const DiscoveryFilterPolicy(
              primaryLayoutMode: DiscoveryFilterLayoutMode.row,
            ),
            onSelectionChanged: (_) {},
          ),
        );

    await tester.pumpWidget(build(const DiscoveryFilterCatalog(
      surface: 'home.events',
    )));
    await tester.pumpAndSettle();
    await tester.pumpWidget(build(_widePrimaryCatalog));
    await tester.pumpAndSettle();

    expect(
      tester
          .getRect(find.byKey(const ValueKey<String>(
            'discoveryFilterPrimary_theatre',
          )))
          .right,
      lessThanOrEqualTo(180),
    );
    expect(_rowPixels(tester, 'discoveryFilterPrimaryList'), greaterThan(0));
  });

  testWidgets('later hydration back to a prior primary anchor reveals again',
      (tester) async {
    var horizontalNotifications = 0;
    Widget build(String primaryKey) => _NarrowHarness(
          width: 180,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.horizontal) {
                horizontalNotifications++;
              }
              return false;
            },
            child: DiscoveryFilterBar(
              key: const ValueKey<String>('anchorCycleBar'),
              catalog: _widePrimaryCatalog,
              selection: DiscoveryFilterSelection(
                primaryKeys: <String>{primaryKey},
              ),
              policy: const DiscoveryFilterPolicy(
                primaryLayoutMode: DiscoveryFilterLayoutMode.row,
              ),
              onSelectionChanged: (_) {},
            ),
          ),
        );

    await tester.pumpWidget(build('theatre'));
    await tester.pumpAndSettle();
    expect(_rowPixels(tester, 'discoveryFilterPrimaryList'), greaterThan(0));

    await tester.pumpWidget(build('music'));
    await tester.pumpAndSettle();
    horizontalNotifications = 0;
    await tester.pumpWidget(build('theatre'));
    await tester.pumpAndSettle();

    expect(horizontalNotifications, greaterThan(0));
    expect(
      tester
          .getRect(find.byKey(const ValueKey<String>(
            'discoveryFilterPrimary_theatre',
          )))
          .right,
      lessThanOrEqualTo(180),
    );
  });

  testWidgets('taxonomy catalog replacement reveals a persisted term anchor',
      (tester) async {
    Widget build(DiscoveryFilterCatalog catalog) => _NarrowHarness(
          width: 180,
          child: DiscoveryFilterBar(
            key: const ValueKey<String>('taxonomyCatalogArrival'),
            catalog: catalog,
            selection: const DiscoveryFilterSelection(
              primaryKeys: <String>{'events'},
              taxonomyTermKeys: <String, Set<String>>{
                'music_styles': <String>{'term_99'},
              },
            ),
            policy: const DiscoveryFilterPolicy(
              taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
            ),
            onSelectionChanged: (_) {},
          ),
        );

    await tester.pumpWidget(build(const DiscoveryFilterCatalog(
      surface: 'home.events',
    )));
    await tester.pumpAndSettle();
    await tester.pumpWidget(build(_largeTaxonomyCatalog()));
    await tester.pumpAndSettle();

    expect(
      tester
          .getRect(find.byKey(const ValueKey<String>(
            'discoveryFilterTaxonomyChip_music_styles_term_99',
          )))
          .right,
      lessThanOrEqualTo(180),
    );
    expect(
      _rowPixels(tester, 'discoveryFilterTaxonomyList_music_styles'),
      greaterThan(0),
    );
  });

  testWidgets('catalog order selects the first primary anchor', (tester) async {
    await tester.pumpWidget(
      _NarrowHarness(
        width: 180,
        child: DiscoveryFilterBar(
          catalog: _widePrimaryCatalog,
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'theatre', 'food'},
          ),
          policy: const DiscoveryFilterPolicy(
            primaryLayoutMode: DiscoveryFilterLayoutMode.row,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final food = tester.getRect(
      find.byKey(const ValueKey<String>('discoveryFilterPrimary_food')),
    );
    final theatre = tester.getRect(
      find.byKey(const ValueKey<String>('discoveryFilterPrimary_theatre')),
    );
    expect(food.right, lessThanOrEqualTo(180));
    expect(theatre.right, greaterThan(180));
  });

  testWidgets('interactive taxonomy add and removal do not replay reveal',
      (tester) async {
    DiscoveryFilterSelection selection = const DiscoveryFilterSelection(
      primaryKeys: <String>{'events'},
    );
    var horizontalNotifications = 0;
    Widget build() => _NarrowHarness(
          width: 180,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.horizontal) {
                horizontalNotifications++;
              }
              return false;
            },
            child: DiscoveryFilterBar(
              key: const ValueKey<String>('interactiveBar'),
              catalog: _largeTaxonomyCatalog(),
              selection: selection,
              policy: const DiscoveryFilterPolicy(
                taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
              ),
              onSelectionChanged: (next) => selection = next,
            ),
          ),
        );

    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(
        const ValueKey<String>('discoveryFilterTaxonomyList_music_styles'),
      ),
      const Offset(-12000, 0),
    );
    await tester.pumpAndSettle();
    horizontalNotifications = 0;
    await tester.tap(find.text('Term 99'));
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(selection.taxonomyTermKeys['music_styles'], <String>{'term_99'});
    expect(horizontalNotifications, 0);

    await tester.tap(find.text('Term 99'));
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(selection.taxonomyTermKeys['music_styles'], isNull);
    expect(horizontalNotifications, 0);
  });

  testWidgets(
      'non-anchor taxonomy interaction does not suppress later hydrated anchor',
      (tester) async {
    var selection = const DiscoveryFilterSelection(
      primaryKeys: <String>{'events'},
      taxonomyTermKeys: <String, Set<String>>{
        'music_styles': <String>{'term_0'},
      },
    );
    Widget build() => _NarrowHarness(
          width: 180,
          child: DiscoveryFilterBar(
            key: const ValueKey<String>('suppressionRegressionBar'),
            catalog: _largeTaxonomyCatalog(),
            selection: selection,
            policy: const DiscoveryFilterPolicy(
              taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
            ),
            onSelectionChanged: (next) => selection = next,
          ),
        );

    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Term 1'));
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    selection = const DiscoveryFilterSelection(
      primaryKeys: <String>{'events'},
      taxonomyTermKeys: <String, Set<String>>{
        'music_styles': <String>{'term_99'},
      },
    );
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(
      tester
          .getRect(find.byKey(const ValueKey<String>(
            'discoveryFilterTaxonomyChip_music_styles_term_99',
          )))
          .right,
      lessThanOrEqualTo(180),
    );
    expect(
      _rowPixels(tester, 'discoveryFilterTaxonomyList_music_styles'),
      greaterThan(0),
    );
  });

  testWidgets(
      'unrelated loading rebuild does not consume pending interaction suppression',
      (tester) async {
    var selection = const DiscoveryFilterSelection(
      primaryKeys: <String>{'events'},
    );
    DiscoveryFilterSelection? publishedSelection;
    var isLoading = false;
    var horizontalNotifications = 0;
    Widget build() => _NarrowHarness(
          width: 180,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.horizontal) {
                horizontalNotifications++;
              }
              return false;
            },
            child: DiscoveryFilterBar(
              key: const ValueKey<String>('delayedSelectionBar'),
              catalog: _largeTaxonomyCatalog(),
              selection: selection,
              isLoading: isLoading,
              policy: const DiscoveryFilterPolicy(
                taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
              ),
              onSelectionChanged: (next) => publishedSelection = next,
            ),
          ),
        );

    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    final row = find.byKey(
      const ValueKey<String>('discoveryFilterTaxonomyList_music_styles'),
    );
    await tester.drag(row, const Offset(-12000, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Term 99'));
    expect(publishedSelection, isNotNull);

    isLoading = true;
    await tester.pumpWidget(build());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(row, const Offset(12000, 0));
    await tester.pump(const Duration(milliseconds: 300));
    horizontalNotifications = 0;
    selection = publishedSelection!;
    await tester.pumpWidget(build());
    await tester.pump(const Duration(milliseconds: 300));

    expect(horizontalNotifications, 0);
    expect(
      tester
          .getRect(find.byKey(const ValueKey<String>(
            'discoveryFilterTaxonomyChip_music_styles_term_99',
          )))
          .left,
      greaterThan(180),
    );
  });

  testWidgets(
      'intervening external selection does not consume pending interaction suppression',
      (tester) async {
    var selection = const DiscoveryFilterSelection(
      primaryKeys: <String>{'events'},
    );
    DiscoveryFilterSelection? publishedSelection;
    var horizontalNotifications = 0;
    Widget build() => _NarrowHarness(
          width: 180,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.horizontal) {
                horizontalNotifications++;
              }
              return false;
            },
            child: DiscoveryFilterBar(
              key: const ValueKey<String>('interleavedSelectionBar'),
              catalog: _largeTaxonomyCatalog(),
              selection: selection,
              policy: const DiscoveryFilterPolicy(
                taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
              ),
              onSelectionChanged: (next) => publishedSelection = next,
            ),
          ),
        );

    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    final row = find.byKey(
      const ValueKey<String>('discoveryFilterTaxonomyList_music_styles'),
    );
    await tester.drag(row, const Offset(-12000, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Term 99'));
    expect(publishedSelection, isNotNull);

    selection = const DiscoveryFilterSelection(
      primaryKeys: <String>{'events'},
      taxonomyTermKeys: <String, Set<String>>{
        'music_styles': <String>{'term_50'},
      },
    );
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    await tester.drag(row, const Offset(12000, 0));
    await tester.pumpAndSettle();
    horizontalNotifications = 0;

    selection = publishedSelection!;
    await tester.pumpWidget(build());
    await tester.pump(const Duration(milliseconds: 300));

    expect(horizontalNotifications, 0);
    expect(
      tester
          .getRect(find.byKey(const ValueKey<String>(
            'discoveryFilterTaxonomyChip_music_styles_term_99',
          )))
          .left,
      greaterThan(180),
    );
  });

  testWidgets(
      'disposing before the reveal callback is inert (scroll operation is not observable)',
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
            primaryLayoutMode: DiscoveryFilterLayoutMode.row,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'already-visible primary selection keeps its offset and is silent',
      (tester) async {
    var horizontalNotifications = 0;
    await tester.pumpWidget(
      _NarrowHarness(
        width: 180,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.horizontal) {
              horizontalNotifications++;
            }
            return false;
          },
          child: DiscoveryFilterBar(
            catalog: _widePrimaryCatalog,
            selection: const DiscoveryFilterSelection(
              primaryKeys: <String>{'music'},
            ),
            policy: const DiscoveryFilterPolicy(
              primaryLayoutMode: DiscoveryFilterLayoutMode.row,
            ),
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final beforePixels = _rowPixels(tester, 'discoveryFilterPrimaryList');
    await tester.pump();
    final afterPixels = _rowPixels(tester, 'discoveryFilterPrimaryList');
    expect(horizontalNotifications, 0);
    expect(beforePixels, 0);
    expect(afterPixels, beforePixels);
    expect(
      tester
          .getRect(find.byKey(const ValueKey<String>(
            'discoveryFilterPrimary_music',
          )))
          .left,
      greaterThanOrEqualTo(0),
    );
  });

  testWidgets(
      'already-visible taxonomy selection keeps its offset and is silent',
      (tester) async {
    var horizontalNotifications = 0;
    await tester.pumpWidget(
      _NarrowHarness(
        width: 180,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.horizontal) {
              horizontalNotifications++;
            }
            return false;
          },
          child: DiscoveryFilterBar(
            catalog: _largeTaxonomyCatalog(),
            selection: const DiscoveryFilterSelection(
              primaryKeys: <String>{'events'},
              taxonomyTermKeys: <String, Set<String>>{
                'music_styles': <String>{'term_0'},
              },
            ),
            policy: const DiscoveryFilterPolicy(
              taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
            ),
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final beforePixels =
        _rowPixels(tester, 'discoveryFilterTaxonomyList_music_styles');
    await tester.pump();
    final afterPixels =
        _rowPixels(tester, 'discoveryFilterTaxonomyList_music_styles');
    expect(horizontalNotifications, 0);
    expect(beforePixels, 0);
    expect(afterPixels, beforePixels);
    expect(find.text('Term 0'), findsOneWidget);
  });

  testWidgets(
      'taxonomy anchor follows catalog order despite reverse set insertion',
      (tester) async {
    await tester.pumpWidget(
      _NarrowHarness(
        width: 180,
        child: DiscoveryFilterBar(
          catalog: _largeTaxonomyCatalog(),
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
            taxonomyTermKeys: <String, Set<String>>{
              'music_styles': <String>{'term_99', 'term_3'},
            },
          ),
          policy: const DiscoveryFilterPolicy(
            taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final catalogFirst = tester.getRect(find.byKey(const ValueKey<String>(
      'discoveryFilterTaxonomyChip_music_styles_term_3',
    )));
    final later = tester.getRect(find.byKey(const ValueKey<String>(
      'discoveryFilterTaxonomyChip_music_styles_term_99',
    )));
    expect(catalogFirst.right, lessThanOrEqualTo(180));
    expect(later.left, greaterThan(180));
  });

  testWidgets('eagerly mounts 100 primary and 200-term taxonomy envelopes',
      (tester) async {
    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _nominalEnvelopeCatalog(),
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'primary_99'},
          ),
          policy: const DiscoveryFilterPolicy(
            taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Primary 99'), findsOneWidget);
    expect(find.text('Term 199'), findsOneWidget);
  });

  testWidgets('eagerly mounts the 1000-term multi-group envelope',
      (tester) async {
    await tester.pumpWidget(
      _Harness(
        child: DiscoveryFilterBar(
          catalog: _thousandTermCatalog(),
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

    expect(find.text('T199'), findsNWidgets(5));
  });

  testWidgets('selected taxonomy rows reveal independently', (tester) async {
    await tester.pumpWidget(
      _NarrowHarness(
        width: 180,
        child: DiscoveryFilterBar(
          catalog: _thousandTermCatalog(),
          selection: const DiscoveryFilterSelection(
            primaryKeys: <String>{'events'},
            taxonomyTermKeys: <String, Set<String>>{
              'group_0': <String>{'term_199'},
              'group_4': <String>{'term_199'},
            },
          ),
          policy: const DiscoveryFilterPolicy(
            taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final group in <String>['group_0', 'group_4']) {
      final rect = tester.getRect(
        find.byKey(
          ValueKey<String>('discoveryFilterTaxonomyChip_${group}_term_199'),
        ),
      );
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(180));
      final scrollable = find.descendant(
        of: find.byKey(ValueKey<String>('discoveryFilterTaxonomyList_$group')),
        matching: find.byType(Scrollable),
      );
      expect(tester.state<ScrollableState>(scrollable).position.pixels,
          greaterThan(0));
    }
    expect(_rowPixels(tester, 'discoveryFilterTaxonomyList_group_1'), 0);
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
        const ValueKey<String>('discoveryFilterPrimary_theatre'),
      ),
    );

    expect(selectedRect.left, greaterThanOrEqualTo(viewportRect.left - 0.1));
    expect(selectedRect.right, lessThanOrEqualTo(viewportRect.right + 0.1));
  });

  testWidgets('row primary layout keeps chips wider than icon-only pills',
      (tester) async {
    const rowCatalog = DiscoveryFilterCatalog(
      surface: 'home.events',
      filters: <DiscoveryFilterCatalogItem>[
        DiscoveryFilterCatalogItem(
          key: 'show',
          label: 'Filtro de Show',
          target: 'event_occurrence',
          entities: <String>{'event'},
        ),
        DiscoveryFilterCatalogItem(
          key: 'fair',
          label: 'Filtro de Feira',
          target: 'event_occurrence',
          entities: <String>{'event'},
        ),
      ],
    );

    await tester.pumpWidget(
      _NarrowHarness(
        width: 360,
        child: DiscoveryFilterBar(
          catalog: rowCatalog,
          selection: const DiscoveryFilterSelection(),
          policy: const DiscoveryFilterPolicy(
            primarySelectionMode: DiscoveryFilterSelectionMode.single,
            primaryLayoutMode: DiscoveryFilterLayoutMode.row,
          ),
          onSelectionChanged: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    final firstRect = tester.getRect(
      find.byKey(const ValueKey<String>('discoveryFilterPrimary_show')),
    );
    final secondRect = tester.getRect(
      find.byKey(const ValueKey<String>('discoveryFilterPrimary_fair')),
    );

    expect(firstRect.width, greaterThan(96));
    expect(secondRect.width, greaterThan(96));
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
          'discoveryFilterTaxonomyChip_music_styles_samba',
        ),
      ),
    );

    expect(selectedRect.left, greaterThanOrEqualTo(viewportRect.left - 0.1));
    expect(selectedRect.right, lessThanOrEqualTo(viewportRect.right + 0.1));
  });

  test('horizontal primary row uses an eager scrolling viewport', () {
    const candidates = <String>[
      'lib/src/discovery_filter_bar.dart',
      'packages/belluga_discovery_filters/lib/src/discovery_filter_bar.dart',
    ];
    final sourceFile =
        candidates.map(File.new).firstWhere((file) => file.existsSync());
    final source = sourceFile.readAsStringSync();

    expect(source, contains('SingleChildScrollView'));
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
          const ValueKey<String>('discoveryFilterPrimary_events'),
        ),
        matching: find.text('Eventos'),
      ),
    );
    expect(capturedForeground, labelText.style?.color);
  });
}

double _rowPixels(WidgetTester tester, String rowKey) {
  final scrollable = find.descendant(
    of: find.byKey(ValueKey<String>(rowKey)),
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(scrollable).position.pixels;
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

DiscoveryFilterCatalog _nominalEnvelopeCatalog() {
  return DiscoveryFilterCatalog(
    surface: 'home.events',
    filters: List<DiscoveryFilterCatalogItem>.generate(
      100,
      (index) => DiscoveryFilterCatalogItem(
        key: 'primary_$index',
        label: 'Primary $index',
        entities: const <String>{'event'},
        taxonomyConfigs: const <String, DiscoveryFilterTaxonomyConfig>{
          'terms': DiscoveryFilterTaxonomyConfig(taxonomyKey: 'terms'),
        },
      ),
    ),
    taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
      'terms': DiscoveryFilterTaxonomyGroupOption(
        key: 'terms',
        label: 'Terms',
        terms: List<DiscoveryFilterTaxonomyTermOption>.generate(
          200,
          (index) => DiscoveryFilterTaxonomyTermOption(
            value: 'term_$index',
            label: 'Term $index',
          ),
        ),
      ),
    },
  );
}

DiscoveryFilterCatalog _thousandTermCatalog() {
  final configs = <String, DiscoveryFilterTaxonomyConfig>{
    for (var group = 0; group < 5; group++)
      'group_$group': DiscoveryFilterTaxonomyConfig(
        taxonomyKey: 'group_$group',
      ),
  };
  return DiscoveryFilterCatalog(
    surface: 'home.events',
    filters: <DiscoveryFilterCatalogItem>[
      DiscoveryFilterCatalogItem(
        key: 'events',
        label: 'Events',
        entities: const <String>{'event'},
        taxonomyConfigs: configs,
      ),
    ],
    taxonomyOptionsByKey: <String, DiscoveryFilterTaxonomyGroupOption>{
      for (var group = 0; group < 5; group++)
        'group_$group': DiscoveryFilterTaxonomyGroupOption(
          key: 'group_$group',
          label: 'Group $group',
          terms: List<DiscoveryFilterTaxonomyTermOption>.generate(
            200,
            (term) => DiscoveryFilterTaxonomyTermOption(
              value: 'term_$term',
              label: 'T$term',
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
