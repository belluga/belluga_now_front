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
  Future<bool> launchDirect({
    required DirectionsDirectProvider provider,
    required DirectionsLaunchTarget target,
  }) async {
    if (!target.hasLaunchableDestination) {
      return false;
    }

    final useWebUrisOnly = _isWebProvider();
    final uris = switch (provider) {
      DirectionsDirectProvider.waze => _wazeUris(target),
      DirectionsDirectProvider.uber => _uberUris(
          target,
          useWebUrisOnly: useWebUrisOnly,
        ),
    };
    if (uris.isEmpty) {
      return false;
    }
    return _launchFirstSupportedUri(uris);
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
          onSelected: () => _launchFirstSupportedUri(_appleMapsUris(target)),
        ),
      DirectionsAppChoice(
        id: 'web:waze',
        label: 'Waze',
        subtitle: 'Abrir navegação externa',
        visualType: DirectionsAppVisualType.waze,
        onSelected: () => _launchFirstSupportedUri(_wazeUris(target)),
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
    if (await _hasAnyLaunchHandler(
      uberUris,
      skipCapabilityCheck: useWebUrisOnly,
    )) {
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

    final ninetyNineUris = _ninetyNineUris(
      target,
      useWebUrisOnly: useWebUrisOnly,
    );
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
      onSelected: () =>
          _launchFirstSupportedUri(<Uri>[_buildBrowserDirectionsUri(target)]),
    );
  }

  bool get _isApplePlatform {
    final platform = _platformProvider();
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  Uri _buildBrowserDirectionsUri(DirectionsLaunchTarget target) {
    final destination = _destinationQuery(target);
    final origin = _encodedOriginQueryParam(target, parameterName: 'origin');
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '${origin ?? ''}'
      '&destination=${Uri.encodeComponent(destination)}',
    );
  }

  String _destinationQuery(DirectionsLaunchTarget target) {
    if (target.hasCoordinates) {
      return '${target.latitude},${target.longitude}';
    }
    return target.trimmedAddress;
  }

  String? _originQuery(DirectionsLaunchTarget target) {
    if (target.hasOriginCoordinates) {
      return '${target.originLatitude},${target.originLongitude}';
    }
    if (target.hasOriginAddress) {
      return target.trimmedOriginAddress;
    }
    return null;
  }

  String? _encodedOriginQueryParam(
    DirectionsLaunchTarget target, {
    required String parameterName,
  }) {
    final origin = _originQuery(target);
    if (origin == null || origin.trim().isEmpty) {
      return null;
    }
    return '&$parameterName=${Uri.encodeComponent(origin)}';
  }

  List<Uri> _googleMapsUris(
    DirectionsLaunchTarget target, {
    required bool useWebUrisOnly,
  }) {
    if (useWebUrisOnly) {
      final origin = _encodedOriginQueryParam(target, parameterName: 'origin');
      return <Uri>[
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
          '${origin ?? ''}'
          '&destination=${Uri.encodeComponent(_destinationQuery(target))}',
        ),
      ];
    }
    final appOrigin = _encodedOriginQueryParam(target, parameterName: 'saddr');
    final webOrigin = _encodedOriginQueryParam(target, parameterName: 'origin');
    return <Uri>[
      Uri.parse(
        'comgooglemaps://?${appOrigin == null ? '' : '${appOrigin.substring(1)}&'}'
        'daddr=${Uri.encodeComponent(_destinationQuery(target))}'
        '&directionsmode=driving',
      ),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '${webOrigin ?? ''}'
        '&destination=${Uri.encodeComponent(_destinationQuery(target))}',
      ),
    ];
  }

  List<Uri> _appleMapsUris(DirectionsLaunchTarget target) {
    final origin = _encodedOriginQueryParam(target, parameterName: 'saddr');
    return <Uri>[
      Uri.parse(
        'https://maps.apple.com/?daddr=${Uri.encodeComponent(_destinationQuery(target))}'
        '${origin ?? ''}'
        '&dirflg=d',
      ),
    ];
  }

  List<Uri> _wazeUris(DirectionsLaunchTarget target) {
    final origin = _encodedOriginQueryParam(target, parameterName: 'from');
    if (target.hasCoordinates) {
      return <Uri>[
        Uri.parse(
          'https://waze.com/ul?ll=${target.latitude},${target.longitude}'
          '${origin ?? ''}'
          '&navigate=yes',
        ),
      ];
    }

    return <Uri>[
      Uri.parse(
        'https://waze.com/ul?q=${Uri.encodeComponent(target.trimmedAddress)}'
        '${origin ?? ''}'
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
    final pickup = _uberPickupQuery(target);
    if (useWebUrisOnly) {
      return <Uri>[
        Uri.parse(
          'https://m.uber.com/ul/?action=setPickup'
          '$pickup'
          '&dropoff[latitude]=$latitude'
          '&dropoff[longitude]=$longitude'
          '&dropoff[nickname]=$encodedTitle',
        ),
      ];
    }
    return <Uri>[
      Uri.parse(
        'uber://?action=setPickup'
        '$pickup'
        '&dropoff[latitude]=$latitude'
        '&dropoff[longitude]=$longitude'
        '&dropoff[nickname]=$encodedTitle',
      ),
      Uri.parse(
        'https://m.uber.com/ul/?action=setPickup'
        '$pickup'
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
    final pickup = _ninetyNinePickupQuery(target);
    if (useWebUrisOnly) {
      return <Uri>[
        Uri.parse(
          'https://app.99app.com/open?deep_link_value=ride'
          '$pickup'
          '&dropoff_latitude=$latitude'
          '&dropoff_longitude=$longitude'
          '&dropoff_title=$encodedTitle',
        ),
      ];
    }
    return <Uri>[
      Uri.parse(
        'ninetynine://ride?$pickup'
        '${pickup.isEmpty ? '' : '&'}dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
      Uri.parse(
        'https://app.99app.com/open?deep_link_value=ride'
        '$pickup'
        '&dropoff_latitude=$latitude'
        '&dropoff_longitude=$longitude'
        '&dropoff_title=$encodedTitle',
      ),
    ];
  }

  String _uberPickupQuery(DirectionsLaunchTarget target) {
    if (!target.hasOriginCoordinates) {
      return '';
    }

    final pickupTitle = Uri.encodeComponent(target.originDisplayName);
    return '&pickup[latitude]=${target.originLatitude}'
        '&pickup[longitude]=${target.originLongitude}'
        '&pickup[nickname]=$pickupTitle';
  }

  String _ninetyNinePickupQuery(DirectionsLaunchTarget target) {
    if (!target.hasOriginCoordinates) {
      return '';
    }

    final pickupTitle = Uri.encodeComponent(target.originDisplayName);
    return '&pickup_latitude=${target.originLatitude}'
        '&pickup_longitude=${target.originLongitude}'
        '&pickup_title=$pickupTitle';
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
