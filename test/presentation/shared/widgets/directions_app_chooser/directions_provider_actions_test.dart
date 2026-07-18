import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_actions.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_brand_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders visible direct providers with their brand treatment', (
    tester,
  ) async {
    final launchedProviders = <DirectionsDirectProvider>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: DirectionsProviderActions(
              target: const DirectionsLaunchTarget(
                destinationName: 'Casa Marracini',
                latitude: -20.7389,
                longitude: -40.8212,
              ),
              isPrimary: true,
              wazeButtonKey: const Key('wazeButton'),
              uberButtonKey: const Key('uberButton'),
              otherButtonKey: const Key('otherDirectionsButton'),
              onOpenDirectDirections: (provider, _) async {
                launchedProviders.add(provider);
              },
              onOpenOtherDirections: (_) async {},
            ),
          ),
        ),
      ),
    );

    final wazeButton = _filledButtonUnder(tester, const Key('wazeButton'));
    expect(
      wazeButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      DirectionsProviderBrandCatalog.waze.backgroundColor,
    );
    expect(
      wazeButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      DirectionsProviderBrandCatalog.waze.foregroundColor,
    );
    final wazeImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('wazeButton')),
        matching: find.byType(Image),
      ),
    );
    final wazeAsset = wazeImage.image as AssetImage;
    expect(wazeAsset.assetName, DirectionsProviderBrandCatalog.waze.assetPath);
    expect(
      find.descendant(
        of: find.byKey(const Key('wazeButton')),
        matching: find.byIcon(Icons.alt_route_outlined),
      ),
      findsNothing,
    );

    final uberButton = _filledButtonUnder(tester, const Key('uberButton'));
    expect(
      uberButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      DirectionsProviderBrandCatalog.uber.backgroundColor,
    );
    expect(
      uberButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      DirectionsProviderBrandCatalog.uber.foregroundColor,
    );
    final uberLogo = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byKey(const Key('uberButton')),
        matching: find.byType(SvgPicture),
      ),
    );
    expect(
      uberLogo.bytesLoader.toString(),
      contains(DirectionsProviderBrandCatalog.uber.assetPath),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('uberButton')),
        matching: find.byIcon(Icons.local_taxi),
      ),
      findsNothing,
    );

    expect(find.bySemanticsLabel('Waze'), findsOneWidget);
    expect(find.bySemanticsLabel('Uber'), findsOneWidget);
    expect(find.bySemanticsLabel('Outros'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wazeButton')));
    await tester.tap(find.byKey(const Key('uberButton')));
    await tester.pump();

    expect(launchedProviders, <DirectionsDirectProvider>[
      DirectionsDirectProvider.waze,
      DirectionsDirectProvider.uber,
    ]);
  });

  testWidgets('compact mode keeps all provider actions as compact pills', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: DirectionsProviderActions(
              target: const DirectionsLaunchTarget(
                destinationName: 'Palco Central',
                latitude: -20.7389,
                longitude: -40.8212,
              ),
              isPrimary: false,
              compact: true,
              wazeButtonKey: const Key('compactWazeButton'),
              uberButtonKey: const Key('compactUberButton'),
              otherButtonKey: const Key('compactOtherDirectionsButton'),
              onOpenDirectDirections: (_, _) async {},
              onOpenOtherDirections: (_) async {},
            ),
          ),
        ),
      ),
    );

    final wazeSize = tester.getSize(find.byKey(const Key('compactWazeButton')));
    final uberSize = tester.getSize(find.byKey(const Key('compactUberButton')));
    final otherSize = tester.getSize(
      find.byKey(const Key('compactOtherDirectionsButton')),
    );

    expect(wazeSize.width, 48);
    expect(wazeSize.height, 48);
    expect(uberSize, const Size(48, 48));
    expect(otherSize, const Size(48, 48));

    final compactWazeIcon = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('compactWazeButton')),
        matching: find.byType(Image),
      ),
    );
    final compactWazeAsset = compactWazeIcon.image as AssetImage;
    expect(
      compactWazeAsset.assetName,
      DirectionsProviderBrandCatalog.waze.compactIconAssetPath,
    );

    final compactUberIcon = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('compactUberButton')),
        matching: find.byType(Image),
      ),
    );
    final compactUberAsset = compactUberIcon.image as AssetImage;
    expect(
      compactUberAsset.assetName,
      DirectionsProviderBrandCatalog.uber.compactIconAssetPath,
    );
  });

  testWidgets('enabled providers expose one tappable semantic node', (
    tester,
  ) async {
    for (final compact in <bool>[false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectionsProviderActions(
              target: const DirectionsLaunchTarget(
                destinationName: 'Casa Marracini',
                latitude: -20.7389,
                longitude: -40.8212,
              ),
              isPrimary: !compact,
              compact: compact,
              onOpenDirectDirections: (_, _) async {},
              onOpenOtherDirections: (_) async {},
            ),
          ),
        ),
      );

      for (final label in <String>['Waze', 'Uber', 'Outros']) {
        final semanticFinder = find.semantics.byLabel(label);

        expect(semanticFinder.evaluate(), hasLength(1));
        expect(
          semanticFinder.evaluate().single.getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
          isTrue,
        );
      }
    }
  });

  testWidgets('semantic and pointer activation share each callback once', (
    tester,
  ) async {
    final directProviders = <DirectionsDirectProvider>[];
    var otherDirectionsCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectionsProviderActions(
            target: const DirectionsLaunchTarget(
              destinationName: 'Casa Marracini',
              latitude: -20.7389,
              longitude: -40.8212,
            ),
            isPrimary: true,
            wazeButtonKey: const Key('semanticWazeButton'),
            uberButtonKey: const Key('semanticUberButton'),
            otherButtonKey: const Key('semanticOtherButton'),
            onOpenDirectDirections: (provider, _) async {
              directProviders.add(provider);
            },
            onOpenOtherDirections: (_) async {
              otherDirectionsCount += 1;
            },
          ),
        ),
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('Waze'));
    await tester.pump();
    expect(directProviders, <DirectionsDirectProvider>[
      DirectionsDirectProvider.waze,
    ]);

    await tester.tap(find.byKey(const Key('semanticWazeButton')));
    await tester.pump();
    expect(directProviders, <DirectionsDirectProvider>[
      DirectionsDirectProvider.waze,
      DirectionsDirectProvider.waze,
    ]);

    tester.semantics.tap(find.semantics.byLabel('Uber'));
    await tester.pump();
    expect(directProviders, <DirectionsDirectProvider>[
      DirectionsDirectProvider.waze,
      DirectionsDirectProvider.waze,
      DirectionsDirectProvider.uber,
    ]);

    await tester.tap(find.byKey(const Key('semanticUberButton')));
    await tester.pump();
    expect(directProviders, <DirectionsDirectProvider>[
      DirectionsDirectProvider.waze,
      DirectionsDirectProvider.waze,
      DirectionsDirectProvider.uber,
      DirectionsDirectProvider.uber,
    ]);

    tester.semantics.tap(find.semantics.byLabel('Outros'));
    await tester.pump();
    expect(otherDirectionsCount, 1);

    await tester.tap(find.byKey(const Key('semanticOtherButton')));
    await tester.pump();
    expect(otherDirectionsCount, 2);
  });

  testWidgets('disabled providers expose no executable semantic action', (
    tester,
  ) async {
    final directProviders = <DirectionsDirectProvider>[];

    for (final compact in <bool>[false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectionsProviderActions(
              target: const DirectionsLaunchTarget(
                destinationName: 'Sem mapa',
                address: 'Rua sem coordenadas',
              ),
              isPrimary: !compact,
              compact: compact,
              uberButtonKey: const Key('disabledUberButton'),
              otherButtonKey: const Key('disabledOtherButton'),
              onOpenDirectDirections: (provider, _) async {
                directProviders.add(provider);
              },
              onOpenOtherDirections: null,
            ),
          ),
        ),
      );

      final disabledControls = <(String, Key)>[
        ('Uber', const Key('disabledUberButton')),
        ('Outros', const Key('disabledOtherButton')),
      ];

      for (final (label, key) in disabledControls) {
        final data = tester.getSemantics(find.byKey(key)).getSemanticsData();

        expect(data.label, label);
        expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
      }

      await tester.tap(find.byKey(const Key('disabledUberButton')));
      await tester.tap(find.byKey(const Key('disabledOtherButton')));
      await tester.pump();
      expect(directProviders, isEmpty);
    }
  });
}

FilledButton _filledButtonUnder(WidgetTester tester, Key key) {
  return tester.widget<FilledButton>(
    find.descendant(of: find.byKey(key), matching: find.byType(FilledButton)),
  );
}
