import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';

class MapMarkerIconResolver {
  const MapMarkerIconResolver._();

  static const IconData fallbackIcon = MapMarkerVisualResolver.fallbackIcon;

  static IconData resolve(String? rawIcon) {
    return MapMarkerVisualResolver.resolveIcon(rawIcon);
  }

  static Color? tryParseHexColor(String? rawColor) {
    return MapMarkerVisualResolver.tryParseHexColor(rawColor);
  }
}
