import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorites_strip.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FavoritesSectionView extends StatelessWidget {
  const FavoritesSectionView({
    super.key,
    required this.controller,
  });

  final FavoritesSectionController controller;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<FavoriteResume>?>(
      streamValue: controller.favoritesStreamValue,
      onNullWidget: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      builder: (context, favorites) {
        return StreamValueBuilder<bool>(
          streamValue: controller.hasMoreFavoritesStreamValue,
          builder: (context, hasMore) {
            return StreamValueBuilder<bool>(
              streamValue: controller.isPageLoadingStreamValue,
              builder: (context, isPageLoading) {
                final all = favorites ?? const <FavoriteResume>[];
                final items = all.where((fav) => !fav.isPrimary).toList();
                final pinned = controller.buildPinnedFavorite();
                final router = context.router;

                return Row(
                  children: [
                    Expanded(
                      child: FavoritesStrip(
                        items: items,
                        pinned: pinned,
                        resolvedVisualForItem: controller.resolvedVisualFor,
                        haloStateForItem: controller.haloStateFor,
                        canLoadMore: hasMore,
                        isLoadingMore: isPageLoading,
                        onEndReached: controller.loadNextPage,
                        onSearchTap: () {
                          router.push(DiscoveryRoute());
                        },
                        onFavoriteTap: (favorite) {
                          _openFavoriteTarget(router, favorite);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _openFavoriteTarget(
    StackRouter router,
    FavoriteResume favorite,
  ) {
    controller.resolveNavigationTarget(favorite).then((target) {
      switch (target) {
        case FavoriteNavigationPrimary():
          return;
        case FavoriteNavigationPath():
          router.pushPath(target.path);
          return;
        case FavoriteNavigationUnavailable():
          return;
      }
    });
  }
}
