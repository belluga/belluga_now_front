import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_chip.dart';
import 'package:flutter/material.dart';

class FavoritesStrip extends StatelessWidget {
  const FavoritesStrip({
    super.key,
    required this.items,
    this.pinned,
    this.height = 118,
    this.spacing = 12,
    this.onPinnedTap,
    this.onFavoriteTap,
    this.onSearchTap,
  });

  final List<FavoriteResume> items;
  final FavoriteResume? pinned;
  final double height;
  final double spacing;
  final VoidCallback? onPinnedTap;
  final ValueChanged<FavoriteResume>? onFavoriteTap;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final pinned = this.pinned;
    final scrollItems = items;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinned != null)
            Padding(
              padding: EdgeInsets.only(right: spacing),
              child: FavoriteChip(
                title: pinned.title,
                imageUri: pinned.imageUri,
                badge: pinned.badge,
                onTap: onPinnedTap ?? () => onFavoriteTap?.call(pinned),
                isPrimary: pinned.isPrimary,
                iconImageUrl: pinned.iconImageUrl,
                primaryColor: pinned.primaryColor,
              ),
            ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: scrollItems.length + 1,
              padding: EdgeInsets.only(
                left: pinned != null ? 0 : spacing,
                right: spacing,
              ),
              separatorBuilder: (_, __) => SizedBox(width: spacing),
              itemBuilder: (context, index) {
                if (index == scrollItems.length) {
                  return FavoriteChip(
                    title: 'Procurar',
                    onTap: onSearchTap,
                  );
                }

                final item = scrollItems[index];
                return FavoriteChip(
                  title: item.title,
                  imageUri: item.imageUri,
                  badge: item.badge,
                  onTap: () => onFavoriteTap?.call(item),
                  isPrimary: item.isPrimary,
                  iconImageUrl: item.iconImageUrl,
                  primaryColor: item.primaryColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
