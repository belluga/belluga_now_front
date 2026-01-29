import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/shared/poi_category_theme.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class PoiMarker extends StatelessWidget {
  const PoiMarker({
    super.key,
    required this.poi,
    required this.isSelected,
    this.isHovered = false,
  });

  final CityPoiModel poi;
  final bool isSelected;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = categoryTheme(poi.category, scheme);

    if (poi.assetPath != null) {
      final isDynamicSponsor = poi.isDynamic;
      final scale = isSelected ? 1.18 : (isHovered ? 1.08 : 1.0);
      final shadowOpacity = isSelected ? 0.35 : (isHovered ? 0.3 : 0.25);

      return AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: scale,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.biggest.shortestSide;
            final imageDiameter = side * (isDynamicSponsor ? 0.82 : 0.9);
            final badgeDiameter =
                (side * (isDynamicSponsor ? 0.32 : 0.28)).clamp(12.0, 24.0);
            final badgeColor = isDynamicSponsor
                ? theme.color.withValues(alpha: 0.85)
                : theme.color;
            final badgeIcon = isDynamicSponsor
                ? Icons.shopping_bag_outlined
                : Icons.storefront;

            return SizedBox(
              width: side,
              height: side,
              child: Stack(
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
                      child: Container(
                        width: imageDiameter,
                        height: imageDiameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(poi.assetPath!),
                            fit: BoxFit.cover,
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
                        color: badgeColor,
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
                          badgeIcon,
                          size: badgeDiameter * 0.55,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final scale = isSelected ? 1.12 : (isHovered ? 1.06 : 1.0);
    final shadowOpacity = isSelected ? 0.35 : (isHovered ? 0.3 : 0.25);

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: scale,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          // Linear map icon size: 26px -> 16px, 65px -> 36px
          final iconSize =
              lerpDouble(16, 36, ((side - 26) / (65 - 26)).clamp(0.0, 1.0))!;
          final padding = (side - iconSize) / 2;
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.color.withValues(alpha: 0.92),
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
                theme.icon,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
