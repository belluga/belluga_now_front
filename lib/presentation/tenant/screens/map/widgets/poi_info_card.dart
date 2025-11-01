import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_category_theme.dart';
import 'package:flutter/material.dart';

class PoiInfoCard extends StatelessWidget {
  const PoiInfoCard({
    super.key,
    required this.poi,
    required this.onDismiss,
  });

  final CityPoiModel poi;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeData = categoryTheme(poi.category, scheme);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PoiAvatar(poi: poi, themeData: themeData),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        themeData.label,
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              poi.description,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    poi.address,
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PoiAvatar extends StatelessWidget {
  const _PoiAvatar({required this.poi, required this.themeData});

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
                  color: Colors.black.withOpacity(0.25),
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
                  color: Colors.white,
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
