import 'package:flutter/material.dart';

enum DirectionsAppVisualType {
  mapAsset,
  googleMaps,
  appleMaps,
  waze,
  uber,
  ninetyNine,
  browser,
}

class DirectionsAppChoice {
  const DirectionsAppChoice({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.visualType,
    required this.onSelected,
    this.assetPath,
  });

  final String id;
  final String label;
  final String subtitle;
  final DirectionsAppVisualType visualType;
  final Future<bool> Function() onSelected;
  final String? assetPath;
}

IconData directionsChoiceIcon(DirectionsAppVisualType visualType) {
  switch (visualType) {
    case DirectionsAppVisualType.googleMaps:
      return Icons.map_outlined;
    case DirectionsAppVisualType.appleMaps:
      return Icons.explore_outlined;
    case DirectionsAppVisualType.waze:
      return Icons.alt_route_outlined;
    case DirectionsAppVisualType.uber:
      return Icons.local_taxi;
    case DirectionsAppVisualType.ninetyNine:
      return Icons.local_taxi_outlined;
    case DirectionsAppVisualType.browser:
      return Icons.language_outlined;
    case DirectionsAppVisualType.mapAsset:
      return Icons.map_outlined;
  }
}
