import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_badge_glyph.dart';
import 'package:flutter/material.dart';

class FavoriteChip extends StatelessWidget {
  const FavoriteChip({
    super.key,
    required this.title,
    this.badge,
    this.imageUri,
    this.assetPath,
    this.onTap,
    this.isPrimary = false,
    this.iconImageUrl,
    this.primaryColor,
    this.resolvedVisual,
    this.haloState = FavoriteChipHaloState.none,
  });

  final String title;
  final FavoriteBadge? badge;
  final Uri? imageUri;
  final String? assetPath;
  final Function()? onTap;
  final bool isPrimary;
  final String? iconImageUrl;
  final Color? primaryColor;
  final ResolvedAccountProfileVisual? resolvedVisual;
  final FavoriteChipHaloState haloState;

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
                  padding: _haloPadding(haloState),
                  decoration: _haloDecoration(colorScheme, haloState),
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
          child: BellugaNetworkImage(
            iconImageUrl!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorWidget: badgeGlyph != null
                ? FavoriteBadgeGlyph(
                    codePoint: badgeGlyph.codePoint,
                    fontFamily: badgeGlyph.fontFamily,
                    size: 32,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.location_city,
                    size: 32,
                    color: Colors.white,
                  ),
          ),
        ),
      );
    }

    final preview = resolvedVisual;
    final previewImageUrl = preview?.compactImageUrl;
    if (previewImageUrl != null && previewImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: BellugaNetworkImage(
            previewImageUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorWidget: _fallbackVisual(colorScheme, badgeGlyph),
          ),
        ),
      );
    }

    final typeVisual = preview?.typeVisual;
    if (typeVisual?.isIcon == true && typeVisual?.iconData != null) {
      return CircleAvatar(
        radius: 32,
        backgroundColor:
            typeVisual?.backgroundColor ?? colorScheme.surfaceContainer,
        child: Icon(
          typeVisual!.iconData,
          size: 28,
          color: typeVisual.iconColor ?? colorScheme.onSurface,
        ),
      );
    }

    if (typeVisual?.isImage == true && typeVisual?.imageUrl != null) {
      return CircleAvatar(
        radius: 32,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: BellugaNetworkImage(
            typeVisual!.imageUrl!,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorWidget: _fallbackVisual(colorScheme, badgeGlyph),
          ),
        ),
      );
    }

    if (assetPath != null && assetPath!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: Image.asset(
            assetPath!,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackVisual(
              colorScheme,
              badgeGlyph,
            ),
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

  Widget _fallbackVisual(
    ColorScheme colorScheme,
    FavoriteBadge? badgeGlyph,
  ) {
    if (badgeGlyph != null) {
      return FavoriteBadgeGlyph(
        codePoint: badgeGlyph.codePoint,
        fontFamily: badgeGlyph.fontFamily,
        size: 24,
        color: colorScheme.onSurface,
      );
    }
    return Icon(
      Icons.add,
      color: colorScheme.onSurfaceVariant,
    );
  }

  EdgeInsets _haloPadding(FavoriteChipHaloState state) {
    switch (state) {
      case FavoriteChipHaloState.liveNow:
        return const EdgeInsets.all(4);
      case FavoriteChipHaloState.upcoming:
        return const EdgeInsets.all(3);
      case FavoriteChipHaloState.none:
        return const EdgeInsets.all(0);
    }
  }

  BoxDecoration _haloDecoration(
    ColorScheme colorScheme,
    FavoriteChipHaloState state,
  ) {
    switch (state) {
      case FavoriteChipHaloState.liveNow:
        return BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.55),
            width: 1.75,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.22),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        );
      case FavoriteChipHaloState.upcoming:
        return BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.85),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        );
      case FavoriteChipHaloState.none:
        return const BoxDecoration(shape: BoxShape.circle);
    }
  }

  FavoriteBadge? _resolveBadgeGlyph() {
    final badgeData = badge;
    if (badgeData == null) return null;
    if (badgeData.codePoint <= 0) return null;
    return badgeData;
  }
}
