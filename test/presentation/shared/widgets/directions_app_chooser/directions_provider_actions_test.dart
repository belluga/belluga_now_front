import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_actions.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_brand_catalog.dart';
import 'package:flutter/material.dart';
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
    expect(
      wazeAsset.assetName,
      DirectionsProviderBrandCatalog.waze.assetPath,
    );
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
}

FilledButton _filledButtonUnder(WidgetTester tester, Key key) {
  return tester.widget<FilledButton>(
    find.descendant(
      of: find.byKey(key),
      matching: find.byType(FilledButton),
    ),
  );
}
