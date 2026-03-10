import 'dart:ui';

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_category_theme.dart';
import 'package:flutter/material.dart';

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
    final hasStack = poi.stackCount > 1;
    final stackLabel = '+${poi.stackCount - 1}';
    final markerColor = poi.isDynamic ? const Color(0xFFE53935) : theme.color;

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
            final badgeColor =
                isDynamicSponsor ? theme.color.withValues(alpha: 0.85) : theme.color;
            final badgeIcon =
                isDynamicSponsor ? Icons.shopping_bag_outlined : Icons.storefront;

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

    final scale = isSelected ? 1.12 : (isHovered ? 1.06 : 1.0);
    final shadowOpacity = isSelected ? 0.35 : (isHovered ? 0.3 : 0.25);

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: scale,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final iconSize =
              lerpDouble(16, 36, ((side - 26) / (65 - 26)).clamp(0.0, 1.0))!;
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
                    poi.isDynamic ? Icons.local_activity : theme.icon,
                    size: iconSize,
                    color: Colors.white,
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
