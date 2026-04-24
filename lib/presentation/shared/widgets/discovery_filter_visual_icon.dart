import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:flutter/material.dart';

Widget buildDiscoveryFilterVisualIcon(
  BuildContext context,
  DiscoveryFilterCatalogItem item,
  bool isActive,
  Color foregroundColor,
) {
  final configuredColor =
      MapMarkerVisualResolver.tryParseHexColor(item.colorHex);
  return Icon(
    MapMarkerVisualResolver.resolveIcon(item.iconKey),
    size: 20,
    color: isActive ? foregroundColor : configuredColor ?? foregroundColor,
  );
}
