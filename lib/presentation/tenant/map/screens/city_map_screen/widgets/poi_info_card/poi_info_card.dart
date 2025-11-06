import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/poi_info_card/widgets/poi_actions_row.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/poi_info_card/widgets/poi_avatar.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/poi_category_theme.dart';
import 'package:flutter/material.dart';

class PoiInfoCard extends StatelessWidget {
  const PoiInfoCard({
    super.key,
    required this.poi,
    required this.onDismiss,
    required this.onDetails,
    required this.onShare,
    required this.onRoute,
  });

  final CityPoiModel poi;
  final VoidCallback onDismiss;
  final VoidCallback onDetails;
  final VoidCallback onShare;
  final VoidCallback onRoute;

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
                PoiAvatar(
                  poi: poi,
                  themeData: themeData,
                ),
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
            const SizedBox(height: 16),
            PoiActionsRow(
              onDetails: onDetails,
              onShare: onShare,
              onRoute: onRoute,
            ),
          ],
        ),
      ),
    );
  }
}
