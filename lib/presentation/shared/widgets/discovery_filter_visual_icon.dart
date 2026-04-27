import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

Widget buildDiscoveryFilterVisualIcon(
  BuildContext context,
  DiscoveryFilterCatalogItem item,
  bool isActive,
  Color foregroundColor,
) {
  final configuredColor =
      MapMarkerVisualResolver.tryParseHexColor(item.colorHex);
  final imageUri = item.imageUri?.trim();
  if (imageUri != null && imageUri.isNotEmpty) {
    final fallbackColor =
        isActive ? foregroundColor : configuredColor ?? foregroundColor;
    return SizedBox.square(
      dimension: 24,
      child: ClipOval(
        child: BellugaNetworkImage(
          imageUri,
          key: ValueKey<String>('discoveryFilterVisualImage_${item.key}'),
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          cacheWidth: 48,
          cacheHeight: 48,
          excludeFromSemantics: true,
          errorWidget: Icon(
            MapMarkerVisualResolver.resolveIcon(item.iconKey),
            size: 20,
            color: fallbackColor,
          ),
        ),
      ),
    );
  }

  return Icon(
    MapMarkerVisualResolver.resolveIcon(item.iconKey),
    size: 20,
    color: isActive ? foregroundColor : configuredColor ?? foregroundColor,
  );
}
