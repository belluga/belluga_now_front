import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_category_theme.dart';
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

    if (poi.assetPath != null) {
      final isDynamicSponsor = poi.isDynamic;
      final baseSize = isDynamicSponsor ? 42.0 : 64.0;
      final selectedSize = isDynamicSponsor ? 48.0 : 72.0;
      final badgeColor =
          isDynamicSponsor ? theme.color.withOpacity(0.85) : theme.color;
      final badgeIcon =
          isDynamicSponsor ? Icons.shopping_bag_outlined : Icons.storefront;
      final scale = isSelected ? 1.18 : (isHovered ? 1.08 : 1.0);
      final shadowOpacity = isSelected ? 0.35 : (isHovered ? 0.3 : 0.25);

      return AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: scale,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: isSelected ? selectedSize : baseSize,
              height: isSelected ? selectedSize : baseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(shadowOpacity),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(poi.assetPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.surface,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    badgeIcon,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final scale = isSelected ? 1.12 : (isHovered ? 1.06 : 1.0);
    final shadowOpacity = isSelected ? 0.35 : (isHovered ? 0.3 : 0.25);

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.color.withOpacity(0.92),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(shadowOpacity),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            theme.icon,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
