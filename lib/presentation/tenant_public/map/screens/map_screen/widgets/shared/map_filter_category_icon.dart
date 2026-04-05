import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:flutter/material.dart';

class MapFilterCategoryIcon extends StatelessWidget {
  const MapFilterCategoryIcon({
    super.key,
    required this.category,
    required this.isActive,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.size = 18,
  });

  final PoiFilterCategory category;
  final bool isActive;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final overrideVisual = category.markerOverrideVisual;
    if (overrideVisual != null && overrideVisual.isValid) {
      if (overrideVisual.isIcon) {
        final iconData =
            MapMarkerVisualResolver.resolveIcon(overrideVisual.icon);
        final configuredIconColor = MapMarkerVisualResolver.tryParseHexColor(
          overrideVisual.iconColorHex,
        );
        final iconColor =
            isActive ? (configuredIconColor ?? Colors.white) : fallbackColor;
        return Icon(
          iconData,
          size: size,
          color: iconColor,
        );
      }
      final overrideImageUri = overrideVisual.imageUri?.trim() ?? '';
      if (overrideImageUri.isNotEmpty) {
        return _ImageFallbackIcon(
          imageUri: overrideImageUri,
          fallbackIcon: fallbackIcon,
          fallbackColor: fallbackColor,
          size: size + 2,
        );
      }
    }

    final legacyImageUri = category.imageUri?.trim() ?? '';
    if (legacyImageUri.isNotEmpty) {
      return _ImageFallbackIcon(
        imageUri: legacyImageUri,
        fallbackIcon: fallbackIcon,
        fallbackColor: fallbackColor,
        size: size + 2,
      );
    }

    return Icon(
      fallbackIcon,
      size: size,
      color: fallbackColor,
    );
  }
}

class _ImageFallbackIcon extends StatelessWidget {
  const _ImageFallbackIcon({
    required this.imageUri,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.size,
  });

  final String imageUri;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.network(
        key: ValueKey(imageUri),
        imageUri,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          fallbackIcon,
          size: size - 2,
          color: fallbackColor,
        ),
      ),
    );
  }
}
