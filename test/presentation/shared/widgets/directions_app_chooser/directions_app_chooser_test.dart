import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_choice.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_sheet.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_launcher/map_launcher.dart';

void main() {
  test('native chooser keeps options dynamic from installed maps and providers',
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

    final labels = options.map((option) => option.label).toList(growable: false);
    expect(labels, containsAll(<String>[
      'Google Maps',
      'Waze',
      'Uber',
      '99',
      'Abrir no navegador',
    ]));
  });

  test('mobile web chooser exposes viable curated options by platform',
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

    final labels = options.map((option) => option.label).toList(growable: false);
    expect(labels, contains('Google Maps'));
    expect(labels, contains('Apple Maps'));
    expect(labels, contains('Waze'));
    expect(labels, contains('Uber'));
    expect(labels, contains('99'));
    expect(labels, contains('Abrir no navegador'));
  });

  test('native chooser skips installed map apps when destination has no coordinates',
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

    final labels = options.map((option) => option.label).toList(growable: false);
    expect(labels, isNot(contains('Google Maps')));
    expect(labels, contains('Abrir no navegador'));
  });

  testWidgets('sheet renders provided dynamic options and close button',
      (tester) async {
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

    expect(find.byKey(const Key('directionsChooserCloseButton')), findsOneWidget);
    expect(find.text('Boora Maps'), findsOneWidget);
    expect(find.text('City Route'), findsOneWidget);
  });
}
