import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_choice.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_sheet.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

typedef DirectionsAvailableMapsLoader = Future<List<AvailableMap>> Function();
typedef DirectionsCanLaunchUrl = Future<bool> Function(Uri uri);
typedef DirectionsLaunchUrl = Future<bool> Function(Uri uri, LaunchMode mode);

class DirectionsAppChooser implements DirectionsAppChooserContract {
  DirectionsAppChooser({
    DirectionsAvailableMapsLoader? availableMapsLoader,
    DirectionsCanLaunchUrl? canLaunchUrl,
    DirectionsLaunchUrl? launchUrl,
    bool Function()? isWebProvider,
    TargetPlatform Function()? platformProvider,
  })  : _availableMapsLoader = availableMapsLoader ?? _defaultAvailableMaps,
        _canLaunchUrl = canLaunchUrl ?? _defaultCanLaunchUrl,
        _launchUrl = launchUrl ?? _defaultLaunchUrl,
        _isWebProvider = isWebProvider ?? (() => kIsWeb),
        _platformProvider = platformProvider ?? (() => defaultTargetPlatform);

  final DirectionsAvailableMapsLoader _availableMapsLoader;
  final DirectionsCanLaunchUrl _canLaunchUrl;
  final DirectionsLaunchUrl _launchUrl;
  final bool Function() _isWebProvider;
  final TargetPlatform Function() _platformProvider;

  static Future<List<AvailableMap>> _defaultAvailableMaps() =>
      MapLauncher.installedMaps;

  static Future<bool> _defaultCanLaunchUrl(Uri uri) => canLaunchUrl(uri);

  static Future<bool> _defaultLaunchUrl(Uri uri, LaunchMode mode) =>
      launchUrl(uri, mode: mode);

  @override
  Future<List<DirectionsAppChoice>> loadOptions({
    required DirectionsLaunchTarget target,
  }) async {
    if (!target.hasLaunchableDestination) {
      return const <DirectionsAppChoice>[];
    }

    if (_isWebProvider()) {
      return _buildWebChoices(target);
    }

    return _buildNativeChoices(target);
  }

  @override
  Future<void> present(
    BuildContext context, {
    required DirectionsLaunchTarget target,
    ValueChanged<String>? onStatusMessage,
  }) async {
    if (!target.hasLaunchableDestination) {
      onStatusMessage?.call(
        'Localização indisponível para ${target.destinationName}.',
      );
      return;
    }

    await DirectionsAppChooserSheet.show(
      context: context,
      title: 'Traçar rota',
      subtitle: 'Selecione seu aplicativo de preferência',
      loadOptions: () => loadOptions(target: target),
      onLaunchFailure: () {
        onStatusMessage?.call(
          'Não foi possível abrir rotas para ${target.destinationName}.',
        );
      },
    );
  }

  Future<List<DirectionsAppChoice>> _buildNativeChoices(
    DirectionsLaunchTarget target,
  ) async {
    final choices = <DirectionsAppChoice>[];
    if (target.hasCoordinates) {
      final destination = Coords(target.latitude!, target.longitude!);

      try {
        final maps = await _availableMapsLoader();
        for (final map in maps) {
          choices.add(
            DirectionsAppChoice(
              id: 'map:${map.mapType.name}',
              label: map.mapName,
              subtitle: 'Abrir navegação externa',
              visualType: DirectionsAppVisualType.mapAsset,
              assetPath: map.icon,
              onSelected: () async {
                try {
                  await map.showDirections(
                    destination: destination,
                    destinationTitle: target.destinationName,
                  );
                  return true;
                } catch (_) {
                  return false;
                }
              },
            ),
          );
        }
      } catch (_) {
        // Native discovery is best-effort. Browser fallback below still applies.
      }
    }

    choices.addAll(await _buildRideShareChoices(target, useWebUrisOnly: false));
    choices.add(_buildBrowserChoice(target));
    return choices;
  }

  Future<List<DirectionsAppChoice>> _buildWebChoices(
    DirectionsLaunchTarget target,
  ) async {
    final choices = <DirectionsAppChoice>[
      DirectionsAppChoice(
        id: 'web:google_maps',
        label: 'Google Maps',
        subtitle: 'Abrir navegação externa',
        visualType: DirectionsAppVisualType.googleMaps,
        onSelected: () => _launchFirstSupportedUri(
          _googleMapsUris(target, useWebUrisOnly: true),
        ),
      ),
      if (_isApplePlatform)
        DirectionsAppChoice(
          id: 'web:apple_maps',
          label: 'Apple Maps',
          subtitle: 'Abrir navegação externa',
          visualType: DirectionsAppVisualType.appleMaps,
          onSelected: () => _launchFirstSupportedUri(
            _appleMapsUris(target),
          ),
        ),
      DirectionsAppChoice(
        id: 'web:waze',
        label: 'Waze',
        subtitle: 'Abrir navegação externa',
        visualType: DirectionsAppVisualType.waze,
        onSelected: () => _launchFirstSupportedUri(
          _wazeUris(target),
        ),
      ),
    ];

    choices.addAll(await _buildRideShareChoices(target, useWebUrisOnly: true));
    choices.add(_buildBrowserChoice(target));
    return choices;
  }

  Future<List<DirectionsAppChoice>> _buildRideShareChoices(
    DirectionsLaunchTarget target, {
    required bool useWebUrisOnly,
  }) async {
    final choices = <DirectionsAppChoice>[];

    final uberUris = _uberUris(target, useWebUrisOnly: useWebUrisOnly);
    if (await _hasAnyLaunchHandler(uberUris, skipCapabilityCheck: useWebUrisOnly)) {
      choices.add(
        DirectionsAppChoice(
          id: 'ride:uber',
          label: 'Uber',
          subtitle: 'Abrir navegação externa',
          visualType: DirectionsAppVisualType.uber,
          onSelected: () => _launchFirstSupportedUri(uberUris),
        ),
      );
    }

    final ninetyNineUris =
        _ninetyNineUris(target, useWebUrisOnly: useWebUrisOnly);
    if (await _hasAnyLaunchHandler(
      ninetyNineUris,
      skipCapabilityCheck: useWebUrisOnly,
    )) {
      choices.add(
        DirectionsAppChoice(
          id: 'ride:99',
          label: '99',
          subtitle: 'Abrir navegação externa',
          visualType: DirectionsAppVisualType.ninetyNine,
          onSelected: () => _launchFirstSupportedUri(ninetyNineUris),
        ),
      );
    }

    return choices;
  }

  DirectionsAppChoice _buildBrowserChoice(DirectionsLaunchTarget target) {
    return DirectionsAppChoice(
      id: 'browser:fallback',
      label: 'Abrir no navegador',
      subtitle: 'Abrir navegação externa',
      visualType: DirectionsAppVisualType.browser,
      onSelected: () => _launchFirstSupportedUri(
        <Uri>[_buildBrowserDirectionsUri(target)],
      ),
    );
  }

  bool get _isApplePlatform {
    final platform = _platformProvider();
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  Uri _buildBrowserDirectionsUri(DirectionsLaunchTarget target) {
    final destination = _destinationQuery(target);
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${Uri.encodeComponent(destination)}',
    );
  }

  String _destinationQuery(DirectionsLaunchTarget target) {
    if (target.hasCoordinates) {
      return '${target.latitude},${target.longitude}';
    }
    return target.trimmedAddress;
  }

  List<Uri> _googleMapsUris(
    DirectionsLaunchTarget target, {
    required bool useWebUrisOnly,
  }) {
    if (useWebUrisOnly) {
      return <Uri>[
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
          '&destination=${Uri.encodeComponent(_destinationQuery(target))}',
        ),
      ];
    }
    return <Uri>[
      Uri.parse(
        'comgooglemaps://?daddr=${Uri.encodeComponent(_destinationQuery(target))}'
        '&directionsmode=driving',
      ),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${Uri.encodeComponent(_destinationQuery(target))}',
      ),
    ];
  }

  List<Uri> _appleMapsUris(DirectionsLaunchTarget target) {
    return <Uri>[
      Uri.parse(
        'https://maps.apple.com/?daddr=${Uri.encodeComponent(_destinationQuery(target))}'
        '&dirflg=d',
      ),
    ];
  }

  List<Uri> _wazeUris(DirectionsLaunchTarget target) {
    if (target.hasCoordinates) {
      return <Uri>[
        Uri.parse(
          'https://waze.com/ul?ll=${target.latitude},${target.longitude}'
          '&navigate=yes',
        ),
      ];
    }

    return <Uri>[
      Uri.parse(
        'https://waze.com/ul?q=${Uri.encodeComponent(target.trimmedAddress)}'
        '&navigate=yes',
      ),
    ];
  }

  List<Uri> _uberUris(
    DirectionsLaunchTarget target, {
    required bool useWebUrisOnly,
  }) {
    if (!target.hasCoordinates) {
      return const <Uri>[];
    }

    final latitude = target.latitude!;
    final longitude = target.longitude!;
    final encodedTitle = Uri.encodeComponent(target.destinationName);
    if (useWebUrisOnly) {
      return <Uri>[
        Uri.parse(
          'https://m.uber.com/ul/?action=setPickup'
          '&dropoff[latitude]=$latitude'
          '&dropoff[longitude]=$longitude'
          '&dropoff[nickname]=$encodedTitle',
        ),
      ];
    }
    return <Uri>[
      Uri.parse(
        'uber://?action=setPickup'
        '&dropoff[latitude]=$latitude'
        '&dropoff[longitude]=$longitude'
        '&dropoff[nickname]=$encodedTitle',
      ),
      Uri.parse(
        'https://m.uber.com/ul/?action=setPickup'
        '&dropoff[latitude]=$latitude'
        '&dropoff[longitude]=$longitude'
        '&dropoff[nickname]=$encodedTitle',
      ),
    ];
  }

  List<Uri> _ninetyNineUris(
    DirectionsLaunchTarget target, {
    required bool useWebUrisOnly,
  }) {
    if (!target.hasCoordinates) {
      return const <Uri>[];
    }

    final latitude = target.latitude!;
    final longitude = target.longitude!;
    final encodedTitle = Uri.encodeComponent(target.destinationName);
    if (useWebUrisOnly) {
      return <Uri>[
        Uri.parse(
          'https://app.99app.com/open?deep_link_value=ride'
          '&dropoff_latitude=$latitude'
          '&dropoff_longitude=$longitude'
          '&dropoff_title=$encodedTitle',
        ),
      ];
    }
    return <Uri>[
      Uri.parse(
        'ninetynine://ride?dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
      Uri.parse(
        'https://app.99app.com/open?deep_link_value=ride'
        '&dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
    ];
  }

  Future<bool> _launchFirstSupportedUri(List<Uri> uris) async {
    for (final uri in uris) {
      if (await _safeCanLaunch(uri)) {
        final launched = await _launchUrl(
          uri,
          _isWebProvider()
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
        );
        if (launched) {
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> _hasAnyLaunchHandler(
    List<Uri> uris, {
    required bool skipCapabilityCheck,
  }) async {
    if (skipCapabilityCheck) {
      return uris.isNotEmpty;
    }
    for (final uri in uris) {
      if (await _safeCanLaunch(uri)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _safeCanLaunch(Uri uri) async {
    try {
      return await _canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
