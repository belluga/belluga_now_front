import 'package:flutter/material.dart';

class FavoriteChip extends StatelessWidget {
  const FavoriteChip({
    super.key,
    required this.title,
    this.badge,
    this.imageUri,
    this.onTap,
    this.isPrimary = false,
    this.iconImageUrl,
    this.primaryColor,
  });

  final String title;
  final IconData? badge;
  final Uri? imageUri;
  final Function()? onTap;
  final bool isPrimary;
  final String? iconImageUrl;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final badgeIcon = _resolveBadgeIcon();

    return SizedBox(
      width: 82,
      child: InkWell(
        onTap: onTap,
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
                  ),
                  child: _buildAvatar(context, colorScheme, badgeIcon),
                ),
                if (badgeIcon != null && !isPrimary)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: colorScheme.surface,
                      child: Icon(
                        badgeIcon,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
      BuildContext context, ColorScheme colorScheme, IconData? badgeIcon) {
    // For app owner (primary), use colored background with icon image
    if (isPrimary && iconImageUrl != null) {
      final backgroundColor = primaryColor ?? colorScheme.primary;

      return CircleAvatar(
        radius: 32,
        backgroundColor: backgroundColor,
        child: ClipOval(
          child: Image.network(
            iconImageUrl!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to badge icon if image fails to load
              if (badgeIcon != null) {
                return Icon(
                  badgeIcon,
                  size: 32,
                  color: Colors.white,
                );
              }
              return Icon(
                Icons.location_city,
                size: 32,
                color: Colors.white,
              );
            },
          ),
        ),
      );
    }

    // For regular favorites, use image or add icon
    return CircleAvatar(
      radius: 32,
      backgroundImage:
          imageUri != null ? NetworkImage(imageUri.toString()) : null,
      child: imageUri == null ? Icon(Icons.add) : null,
    );
  }

  IconData? _resolveBadgeIcon() {
    final _badge = badge;
    if (_badge == null) {
      return null;
    }
    final codePoint = _badge.codePoint;
    if (codePoint <= 0) {
      return null;
    }
    return IconData(
      codePoint,
      fontFamily: _badge.fontFamily,
      fontPackage: _badge.fontPackage,
    );
  }
}
