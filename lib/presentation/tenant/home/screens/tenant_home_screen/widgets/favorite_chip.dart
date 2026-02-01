import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_badge_glyph.dart';
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
  final FavoriteBadge? badge;
  final Uri? imageUri;
  final Function()? onTap;
  final bool isPrimary;
  final String? iconImageUrl;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final badgeGlyph = _resolveBadgeGlyph();

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
                  child: _buildAvatar(context, colorScheme, badgeGlyph),
                ),
                if (badgeGlyph != null && !isPrimary)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: colorScheme.surface,
                      child: FavoriteBadgeGlyph(
                        codePoint: badgeGlyph.codePoint,
                        fontFamily: badgeGlyph.fontFamily,
                        size: 14,
                        color: colorScheme.onSurface,
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
      BuildContext context, ColorScheme colorScheme, FavoriteBadge? badgeGlyph) {
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
              if (badgeGlyph != null) {
                return FavoriteBadgeGlyph(
                  codePoint: badgeGlyph.codePoint,
                  fontFamily: badgeGlyph.fontFamily,
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

  FavoriteBadge? _resolveBadgeGlyph() {
    final badgeData = badge;
    if (badgeData == null) return null;
    if (badgeData.codePoint <= 0) return null;
    return badgeData;
  }
}
