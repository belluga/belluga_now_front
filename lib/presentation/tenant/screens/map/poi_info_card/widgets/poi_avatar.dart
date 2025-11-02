import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_category_theme.dart';
import 'package:flutter/material.dart';

class PoiAvatar extends StatelessWidget {
  const PoiAvatar({
    super.key,
    required this.poi,
    required this.themeData,
  });

  final CityPoiModel poi;
  final CityPoiCategoryThemeData themeData;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (poi.assetPath != null) {
      final isDynamicSponsor = poi.isDynamic;
      final size = isDynamicSponsor ? 48.0 : 64.0;
      final badgeIcon = isDynamicSponsor
          ? Icons.shopping_bag_outlined
          : Icons.storefront;

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              poi.assetPath!,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeData.color,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  badgeIcon,
                  size: 14,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeData.color.withOpacity(0.12),
      ),
      padding: const EdgeInsets.all(12),
      child: Icon(themeData.icon, color: themeData.color),
    );
  }
}
