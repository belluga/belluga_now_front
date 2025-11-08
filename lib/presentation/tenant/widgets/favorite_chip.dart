import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/presentation/tenant/widgets/favorite_chip_image.dart';
import 'package:flutter/material.dart';

class FavoriteChip extends StatelessWidget {
  const FavoriteChip({super.key, required this.item});

  final FavoriteResume item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = item.isPrimary
        ? [colorScheme.primary, colorScheme.tertiary]
        : [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ];

    final badgeIcon = _resolveBadgeIcon();

    return SizedBox(
      width: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradientColors),
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 66,
                    height: 66,
                    child: FavoriteChipImage(item: item),
                  ),
                ),
              ),
              if (badgeIcon != null)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.surface,
                    child: Icon(
                      badgeIcon,
                      size: 14,
                      color: item.isPrimary
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  IconData? _resolveBadgeIcon() {
    final badge = item.badge;
    if (badge == null) {
      return null;
    }
    final codePoint = badge.codePoint;
    if (codePoint <= 0) {
      return null;
    }
    return IconData(
      codePoint,
      fontFamily: badge.fontFamily,
      fontPackage: badge.fontPackage,
    );
  }
}
