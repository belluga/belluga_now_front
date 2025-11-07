import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
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
                    child: _FavoriteImage(item: item),
                  ),
                ),
              ),
              if (item.badgeIcon != null)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.surface,
                    child: Icon(
                      item.badgeIcon,
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
}

class _FavoriteImage extends StatelessWidget {
  const _FavoriteImage({required this.item});

  final FavoriteResume item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (item.assetPath != null) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.cover,
      );
    }

    final imageUrl = item.imageUri?.toString();
    if (imageUrl == null) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
