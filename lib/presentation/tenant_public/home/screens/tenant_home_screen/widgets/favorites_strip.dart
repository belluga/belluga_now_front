import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_chip.dart';
import 'package:flutter/material.dart';

class FavoritesStrip extends StatelessWidget {
  static const double _paginationThreshold = 72.0;

  const FavoritesStrip({
    super.key,
    required this.items,
    this.pinned,
    this.height = 118,
    this.spacing = 12,
    this.onPinnedTap,
    this.onFavoriteTap,
    this.onSearchTap,
    this.resolvedVisualForItem,
    this.haloStateForItem,
    this.canLoadMore = false,
    this.isLoadingMore = false,
    this.onEndReached,
  });

  final List<FavoriteResume> items;
  final FavoriteResume? pinned;
  final double height;
  final double spacing;
  final VoidCallback? onPinnedTap;
  final ValueChanged<FavoriteResume>? onFavoriteTap;
  final VoidCallback? onSearchTap;
  final ResolvedAccountProfileVisual? Function(FavoriteResume item)?
  resolvedVisualForItem;
  final FavoriteChipHaloState Function(FavoriteResume item)? haloStateForItem;
  final bool canLoadMore;
  final bool isLoadingMore;
  final VoidCallback? onEndReached;

  @override
  Widget build(BuildContext context) {
    final pinned = this.pinned;
    final scrollItems = items;
    final hasLoadingIndicator = isLoadingMore;
    final trailingCount = hasLoadingIndicator ? 2 : 1;

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
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScroll,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: scrollItems.length + trailingCount,
                padding: EdgeInsets.only(
                  left: pinned != null ? 0 : spacing,
                  right: spacing,
                ),
                separatorBuilder: (_, _) => SizedBox(width: spacing),
                itemBuilder: (context, index) {
                  if (index == scrollItems.length) {
                    if (hasLoadingIndicator) {
                      return SizedBox(
                        width: 56,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    return FavoriteChip(title: 'Procurar', onTap: onSearchTap);
                  }

                  if (hasLoadingIndicator && index == scrollItems.length + 1) {
                    return FavoriteChip(title: 'Procurar', onTap: onSearchTap);
                  }

                  final item = scrollItems[index];
                  return FavoriteChip(
                    title: item.title,
                    imageUri: item.imageUri,
                    assetPath: item.assetPath,
                    badge: item.badge,
                    onTap: () => onFavoriteTap?.call(item),
                    isPrimary: item.isPrimary,
                    iconImageUrl: item.iconImageUrl,
                    primaryColor: item.primaryColor,
                    resolvedVisual: resolvedVisualForItem?.call(item),
                    haloState:
                        haloStateForItem?.call(item) ??
                        FavoriteChipHaloState.none,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _handleScroll(ScrollNotification notification) {
    if (onEndReached == null || !canLoadMore || isLoadingMore) {
      return false;
    }

    if (notification.metrics.axis != Axis.horizontal) {
      return false;
    }

    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification &&
        notification is! UserScrollNotification) {
      return false;
    }

    final metrics = notification.metrics;
    if (metrics.pixels <= 0 || metrics.extentAfter > _paginationThreshold) {
      return false;
    }

    onEndReached?.call();
    return false;
  }
}
