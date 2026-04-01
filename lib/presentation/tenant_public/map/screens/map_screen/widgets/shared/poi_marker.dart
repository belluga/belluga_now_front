import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_marker_icon_resolver.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/marker_fallback_icon.dart';
import 'package:flutter/material.dart';

class PoiMarker extends StatelessWidget {
  const PoiMarker({
    super.key,
    required this.poi,
    required this.isSelected,
    this.isHovered = false,
    this.overrideVisual,
  });

  final CityPoiModel poi;
  final bool isSelected;
  final bool isHovered;
  final CityPoiVisual? overrideVisual;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasStack = poi.stackCount > 1;
    final stackLabel = '+${poi.stackCount - 1}';
    final visual = _resolvedVisual();

    if (visual?.isImage == true) {
      return _buildImageMarker(
        context,
        imageProvider: NetworkImage(visual!.imageUri!),
        hasStack: hasStack,
        stackLabel: stackLabel,
      );
    }

    final legacyAssetPath = poi.assetPath?.trim();
    if (legacyAssetPath != null && legacyAssetPath.isNotEmpty) {
      return _buildImageMarker(
        context,
        imageProvider: AssetImage(legacyAssetPath),
        hasStack: hasStack,
        stackLabel: stackLabel,
      );
    }

    final scale = isSelected ? 1.12 : (isHovered ? 1.06 : 1.0);
    final shadowOpacity = isSelected ? 0.35 : (isHovered ? 0.3 : 0.25);
    final icon = visual?.isIcon == true
        ? MapMarkerIconResolver.resolve(visual?.icon)
        : MapMarkerIconResolver.fallbackIcon;
    final markerColor = visual?.isIcon == true
        ? (MapMarkerIconResolver.tryParseHexColor(visual?.colorHex) ??
            scheme.primary)
        : scheme.primary;
    final iconColor = visual?.isIcon == true
        ? (MapMarkerIconResolver.tryParseHexColor(visual?.iconColorHex) ??
            Colors.white)
        : Colors.white;

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: scale,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final iconMax = poi.isDynamic ? 40.0 : 36.0;
          final iconSize = (side * 0.52).clamp(16.0, iconMax);
          final padding = (side - iconSize) / 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: markerColor.withValues(alpha: 0.92),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: shadowOpacity),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: iconColor,
                  ),
                ),
              ),
              if (hasStack)
                Positioned(
                  top: -2,
                  left: -2,
                  child: _buildStackBadge(
                    context: context,
                    label: stackLabel,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  CityPoiVisual? _resolvedVisual() {
    final override = overrideVisual;
    if (override != null && override.isValid) {
      return override;
    }

    final ownVisual = poi.visual;
    if (ownVisual != null && ownVisual.isValid) {
      return ownVisual;
    }

    return null;
  }

  Widget _buildImageMarker(
    BuildContext context, {
    required ImageProvider<Object> imageProvider,
    required bool hasStack,
    required String stackLabel,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final scale = isSelected ? 1.18 : (isHovered ? 1.08 : 1.0);
    final shadowOpacity = isSelected ? 0.35 : (isHovered ? 0.3 : 0.25);

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: scale,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final imageDiameter = side * 0.9;
          final badgeDiameter = (side * 0.28).clamp(12.0, 24.0);

          return SizedBox(
            width: side,
            height: side,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: side,
                  height: side,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: shadowOpacity),
                        blurRadius: (side * 0.18).clamp(6.0, 12.0),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: SizedBox(
                      width: imageDiameter,
                      height: imageDiameter,
                      child: ClipOval(
                        child: Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => MarkerFallbackIcon(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.surface,
                        width: 2,
                      ),
                    ),
                    child: SizedBox(
                      width: badgeDiameter,
                      height: badgeDiameter,
                      child: Icon(
                        Icons.image_outlined,
                        size: badgeDiameter * 0.55,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (hasStack)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: _buildStackBadge(
                      context: context,
                      label: stackLabel,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStackBadge({
    required BuildContext context,
    required String label,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
