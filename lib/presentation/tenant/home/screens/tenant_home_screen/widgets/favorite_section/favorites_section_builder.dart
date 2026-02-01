import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorites_strip.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FavoritesSectionBuilder extends StatefulWidget {
  const FavoritesSectionBuilder({super.key});

  @override
  State<FavoritesSectionBuilder> createState() =>
      _FavoritesSectionBuilderState();
}

class _FavoritesSectionBuilderState extends State<FavoritesSectionBuilder> {
  late final FavoritesSectionController _controller =
      GetIt.I.get<FavoritesSectionController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<FavoriteResume>?>(
      streamValue: _controller.favoritesStreamValue,
      onNullWidget: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      builder: (context, favorites) {
        final all = favorites ?? const <FavoriteResume>[];
        final items = all.where((fav) => !fav.isPrimary).toList();
        final pinned = _controller.buildPinnedFavorite();

        return Row(
          children: [
            Expanded(
              child: FavoritesStrip(
                items: items,
                pinned: pinned,
                onSearchTap: () {
                  context.router.push(DiscoveryRoute());
                },
                onFavoriteTap: (favorite) {
                  _handleFavoriteTap(favorite);
                },
                onPinnedTap: () {
                  // TODO(Delphi): Route to About screen once available in AutoRoute map.
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleFavoriteTap(FavoriteResume favorite) async {
    final target = await _controller.resolveNavigationTarget(favorite);
    if (!mounted) return;

    switch (target) {
      case FavoriteNavigationPrimary():
        return;
      case FavoriteNavigationPartner():
        context.router.push(
          PartnerDetailRoute(slug: target.slug),
        );
        return;
      case FavoriteNavigationSearch():
        context.router.replaceAll(
          [
            EventSearchRoute(
              startSearchActive: true,
              initialSearchQuery: target.query,
            ),
          ],
        );
        return;
    }
  }
}
