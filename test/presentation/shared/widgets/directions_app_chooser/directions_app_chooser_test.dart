import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_choice.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_sheet.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_brand_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_launcher/map_launcher.dart';

void main() {
  test(
    'native chooser keeps options dynamic from installed maps and providers',
    () async {
      final chooser = DirectionsAppChooser(
        isWebProvider: () => false,
        platformProvider: () => TargetPlatform.android,
        availableMapsLoader: () async => <AvailableMap>[
          AvailableMap(
            mapName: 'Google Maps',
            mapType: MapType.google,
            icon: 'packages/map_launcher/assets/icons/google.svg',
          ),
          AvailableMap(
            mapName: 'Waze',
            mapType: MapType.waze,
            icon: 'packages/map_launcher/assets/icons/waze.svg',
          ),
        ],
        canLaunchUrl: (_) async => true,
        launchUrl: (_, __) async => true,
      );

      final options = await chooser.loadOptions(
        target: const DirectionsLaunchTarget(
          destinationName: 'Casa Marracini',
          latitude: -20.7389,
          longitude: -40.8212,
        ),
      );

      final labels =
          options.map((option) => option.label).toList(growable: false);
      expect(
        labels,
        containsAll(<String>[
          'Google Maps',
          'Waze',
          'Uber',
          '99',
          'Abrir no navegador',
        ]),
      );
    },
  );

  test(
    'mobile web chooser exposes viable curated options by platform',
    () async {
      final chooser = DirectionsAppChooser(
        isWebProvider: () => true,
        platformProvider: () => TargetPlatform.iOS,
        availableMapsLoader: () async => const <AvailableMap>[],
        canLaunchUrl: (_) async => true,
        launchUrl: (_, __) async => true,
      );

      final options = await chooser.loadOptions(
        target: const DirectionsLaunchTarget(
          destinationName: 'Casa Marracini',
          latitude: -20.7389,
          longitude: -40.8212,
        ),
      );

      final labels =
          options.map((option) => option.label).toList(growable: false);
      expect(labels, contains('Google Maps'));
      expect(labels, contains('Apple Maps'));
      expect(labels, contains('Waze'));
      expect(labels, contains('Uber'));
      expect(labels, contains('99'));
      expect(labels, isNot(contains('Abrir no navegador')));
    },
  );

  test(
    'native chooser skips installed map apps when destination has no coordinates',
    () async {
      final chooser = DirectionsAppChooser(
        isWebProvider: () => false,
        platformProvider: () => TargetPlatform.android,
        availableMapsLoader: () async => <AvailableMap>[
          AvailableMap(
            mapName: 'Google Maps',
            mapType: MapType.google,
            icon: 'packages/map_launcher/assets/icons/google.svg',
          ),
        ],
        canLaunchUrl: (_) async => true,
        launchUrl: (_, __) async => true,
      );

      final options = await chooser.loadOptions(
        target: const DirectionsLaunchTarget(
          destinationName: 'Casa Marracini',
          address: 'Rua Teste, 123',
        ),
      );

      final labels =
          options.map((option) => option.label).toList(growable: false);
      expect(labels, isNot(contains('Google Maps')));
      expect(labels, contains('Abrir no navegador'));
    },
  );

  test('web provider launch uris include reference point origin', () async {
    final launchedUris = <Uri>[];
    final chooser = DirectionsAppChooser(
      isWebProvider: () => true,
      platformProvider: () => TargetPlatform.android,
      availableMapsLoader: () async => const <AvailableMap>[],
      canLaunchUrl: (_) async => true,
      launchUrl: (uri, __) async {
        launchedUris.add(uri);
        return true;
      },
    );

    final options = await chooser.loadOptions(
      target: const DirectionsLaunchTarget(
        destinationName: 'Casa Marracini',
        latitude: -20.7389,
        longitude: -40.8212,
        originName: 'Hotel Base',
        originLatitude: -20.6736,
        originLongitude: -40.4976,
      ),
    );

    await options
        .singleWhere((option) => option.label == 'Google Maps')
        .onSelected();
    await options.singleWhere((option) => option.label == 'Waze').onSelected();
    await options.singleWhere((option) => option.label == 'Uber').onSelected();
    await options.singleWhere((option) => option.label == '99').onSelected();

    final uriStrings = launchedUris.map((uri) => uri.toString()).join('\n');
    expect(uriStrings, contains('origin=-20.6736%2C-40.4976'));
    expect(uriStrings, contains('from=-20.6736%2C-40.4976'));
    expect(uriStrings, contains('pickup%5Blatitude%5D=-20.6736'));
    expect(uriStrings, contains('pickup%5Blongitude%5D=-40.4976'));
    expect(uriStrings, contains('pickup_latitude=-20.6736'));
    expect(uriStrings, contains('pickup_longitude=-40.4976'));
  });

  test('direct provider launch skips chooser options and launches provider uri',
      () async {
    final launchedUris = <Uri>[];
    final chooser = DirectionsAppChooser(
      isWebProvider: () => true,
      platformProvider: () => TargetPlatform.android,
      availableMapsLoader: () async => const <AvailableMap>[],
      canLaunchUrl: (_) async => true,
      launchUrl: (uri, __) async {
        launchedUris.add(uri);
        return true;
      },
    );

    final launched = await chooser.launchDirect(
      provider: DirectionsDirectProvider.waze,
      target: const DirectionsLaunchTarget(
        destinationName: 'Casa Marracini',
        latitude: -20.7389,
        longitude: -40.8212,
      ),
    );

    expect(launched, isTrue);
    expect(launchedUris, hasLength(1));
    expect(launchedUris.single.toString(), startsWith('https://waze.com/ul'));
  });

  testWidgets('sheet renders provided dynamic options and close button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    DirectionsAppChooserSheet.show(
                      context: context,
                      title: 'Traçar rota',
                      subtitle: 'Selecione seu aplicativo de preferência',
                      loadOptions: () async => <DirectionsAppChoice>[
                        DirectionsAppChoice(
                          id: 'custom:boora',
                          label: 'Boora Maps',
                          subtitle: 'Abrir navegação externa',
                          visualType: DirectionsAppVisualType.browser,
                          onSelected: () async => true,
                        ),
                        DirectionsAppChoice(
                          id: 'custom:city',
                          label: 'City Route',
                          subtitle: 'Abrir navegação externa',
                          visualType: DirectionsAppVisualType.browser,
                          onSelected: () async => true,
                        ),
                      ],
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const Key('directionsChooserCloseButton')),
      findsOneWidget,
    );
    expect(find.text('Boora Maps'), findsOneWidget);
    expect(find.text('City Route'), findsOneWidget);
    expect(find.text('Abrir navegação externa'), findsNothing);
  });

  testWidgets('sheet renders branded route options with brand assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    DirectionsAppChooserSheet.show(
                      context: context,
                      title: 'Traçar rota',
                      subtitle: 'Selecione seu aplicativo de preferência',
                      loadOptions: () async => <DirectionsAppChoice>[
                        DirectionsAppChoice(
                          id: 'google:web',
                          label: 'Google Maps',
                          subtitle: 'Abrir navegação externa',
                          visualType: DirectionsAppVisualType.googleMaps,
                          onSelected: () async => true,
                        ),
                        DirectionsAppChoice(
                          id: 'waze:web',
                          label: 'Waze',
                          subtitle: 'Abrir navegação externa',
                          visualType: DirectionsAppVisualType.waze,
                          onSelected: () async => true,
                        ),
                        DirectionsAppChoice(
                          id: 'uber:web',
                          label: 'Uber',
                          subtitle: 'Abrir navegação externa',
                          visualType: DirectionsAppVisualType.uber,
                          onSelected: () async => true,
                        ),
                        DirectionsAppChoice(
                          id: '99:web',
                          label: '99',
                          subtitle: 'Abrir navegação externa',
                          visualType: DirectionsAppVisualType.ninetyNine,
                          onSelected: () async => true,
                        ),
                      ],
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final googleLogo = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
    expect(
      googleLogo.first.bytesLoader.toString(),
      contains(DirectionsProviderBrandCatalog.googleMaps.assetPath),
    );

    final wazeImage = tester.widget<Image>(
      find.byType(Image).first,
    );
    final wazeAsset = wazeImage.image as AssetImage;
    expect(
      wazeAsset.assetName,
      DirectionsProviderBrandCatalog.waze.assetPath,
    );

    final svgLogos = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
    expect(
      svgLogos.map((logo) => logo.bytesLoader.toString()).join('\n'),
      contains(DirectionsProviderBrandCatalog.uber.assetPath),
    );

    final rasterAssets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList(growable: false);
    expect(rasterAssets,
        contains(DirectionsProviderBrandCatalog.ninetyNine.assetPath));
  });
}
