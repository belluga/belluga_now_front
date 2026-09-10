import 'dart:math' as math;

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

    expect(
      _materialUnder(tester, const Key('wazeButton')).color,
      DirectionsProviderBrandCatalog.waze.backgroundColor,
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

    expect(
      _materialUnder(tester, const Key('uberButton')).color,
      DirectionsProviderBrandCatalog.uber.backgroundColor,
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

  testWidgets(
    'keeps brand and disabled treatments while resolving accessible Outros icons',
    (tester) async {
      final schemes = <ColorScheme>[
        ColorScheme.light().copyWith(
          secondaryContainer: const Color(0xfff5f5f5),
          onSecondaryContainer: const Color(0xfff5f5f5),
          surfaceContainerHighest: const Color(0xfff5f5f5),
          onSurface: const Color(0xfff5f5f5),
        ),
        ColorScheme.dark().copyWith(
          secondaryContainer: const Color(0xff121212),
          onSecondaryContainer: const Color(0xff121212),
          surfaceContainerHighest: const Color(0xff121212),
          onSurface: const Color(0xff121212),
        ),
      ];

      for (final compact in [false, true]) {
        for (final enabled in [false, true]) {
          for (final scheme in schemes) {
            final openedOther = <bool>[];
            await tester.pumpWidget(
              MaterialApp(
                key: ValueKey(
                  'directionsContrast-$compact-$enabled-${scheme.brightness}',
                ),
                theme: ThemeData(
                  colorScheme: scheme,
                  splashFactory: NoSplash.splashFactory,
                ),
                home: Scaffold(
                  body: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 360,
                        child: DirectionsProviderActions(
                          target: const DirectionsLaunchTarget(
                            destinationName: 'Casa Marracini',
                            latitude: -20.7389,
                            longitude: -40.8212,
                          ),
                          isPrimary: true,
                          compact: compact,
                          wazeButtonKey: const Key('wazeContrastButton'),
                          uberButtonKey: const Key('uberContrastButton'),
                          otherButtonKey: const Key('otherContrastButton'),
                          onOpenDirectDirections: enabled
                              ? (_, _) async {}
                              : null,
                          onOpenOtherDirections: enabled
                              ? (_) async => openedOther.add(compact)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DisabledMaterialReference(
                        key: const Key('disabledOtherReference'),
                        compact: compact,
                        backgroundColor: compact
                            ? scheme.surfaceContainerHighest
                            : scheme.secondaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            );

            final otherBackground = _materialUnder(
              tester,
              const Key('otherContrastButton'),
            ).color;
            final otherForeground = _iconColorUnder(
              tester,
              const Key('otherContrastButton'),
            );
            final expectedBackground = compact
                ? scheme.surfaceContainerHighest
                : scheme.secondaryContainer;

            expect(otherBackground, enabled ? expectedBackground : isNotNull);
            expect(find.bySemanticsLabel('Outros'), findsOneWidget);
            expect(
              tester
                      .widget<FilledButton>(
                        find.descendant(
                          of: find.byKey(const Key('otherContrastButton')),
                          matching: find.byType(FilledButton),
                        ),
                      )
                      .onPressed !=
                  null,
              enabled,
            );
            if (enabled) {
              expect(
                _contrastRatio(otherBackground!, otherForeground),
                greaterThanOrEqualTo(4.5),
              );
            } else {
              expect(
                otherBackground,
                _materialUnder(
                  tester,
                  const Key('disabledOtherReference'),
                ).color,
              );
              expect(
                otherForeground,
                _iconColorUnder(tester, const Key('disabledOtherReference')),
              );
            }

            expect(
              _materialUnder(tester, const Key('wazeContrastButton')).color,
              enabled
                  ? DirectionsProviderBrandCatalog.waze.backgroundColor
                  : scheme.surfaceContainerHighest,
            );
            final wazeOpacity = tester.widget<Opacity>(
              find.descendant(
                of: find.byKey(const Key('wazeContrastButton')),
                matching: find.byType(Opacity),
              ),
            );
            expect(wazeOpacity.opacity, enabled ? 1 : 0.38);

            expect(
              _materialUnder(tester, const Key('uberContrastButton')).color,
              enabled
                  ? DirectionsProviderBrandCatalog.uber.backgroundColor
                  : scheme.surfaceContainerHighest,
            );
            if (compact) {
              expect(
                find.descendant(
                  of: find.byKey(const Key('uberContrastButton')),
                  matching: find.byType(Image),
                ),
                findsOneWidget,
              );
            } else {
              final uberLogo = tester.widget<SvgPicture>(
                find.descendant(
                  of: find.byKey(const Key('uberContrastButton')),
                  matching: find.byType(SvgPicture),
                ),
              );
              if (!enabled) {
                expect(
                  uberLogo.colorFilter,
                  ColorFilter.mode(
                    scheme.onSurface.withValues(alpha: 0.38),
                    BlendMode.srcIn,
                  ),
                );
              }
            }

            expect(
              tester.getTopLeft(find.byKey(const Key('wazeContrastButton'))).dx,
              lessThan(
                tester
                    .getTopLeft(find.byKey(const Key('uberContrastButton')))
                    .dx,
              ),
            );
            expect(
              tester.getTopLeft(find.byKey(const Key('uberContrastButton'))).dx,
              lessThan(
                tester
                    .getTopLeft(find.byKey(const Key('otherContrastButton')))
                    .dx,
              ),
            );
            await tester.tap(find.byKey(const Key('otherContrastButton')));
            await tester.pump();
            expect(openedOther, enabled ? [compact] : isEmpty);
          }
        }
      }
    },
  );
}

Material _materialUnder(WidgetTester tester, Key key) {
  return tester
      .widgetList<Material>(
        find.descendant(of: find.byKey(key), matching: find.byType(Material)),
      )
      .last;
}

Color _iconColorUnder(WidgetTester tester, Key key) {
  final icon = find.descendant(
    of: find.byKey(key),
    matching: find.byType(Icon),
  );
  return IconTheme.of(tester.element(icon)).color!;
}

class _DisabledMaterialReference extends StatelessWidget {
  const _DisabledMaterialReference({
    super.key,
    required this.compact,
    required this.backgroundColor,
  });

  final bool compact;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(backgroundColor: backgroundColor);
    final button = compact
        ? FilledButton(
            onPressed: null,
            style: style,
            child: const Icon(Icons.more_horiz),
          )
        : FilledButton.tonal(
            onPressed: null,
            style: style,
            child: const Icon(Icons.more_horiz),
          );
    return SizedBox(width: 56, height: 48, child: button);
  }
}

double _contrastRatio(Color background, Color foreground) {
  final light = math.max(
    background.computeLuminance(),
    foreground.computeLuminance(),
  );
  final dark = math.min(
    background.computeLuminance(),
    foreground.computeLuminance(),
  );
  return (light + 0.05) / (dark + 0.05);
}
