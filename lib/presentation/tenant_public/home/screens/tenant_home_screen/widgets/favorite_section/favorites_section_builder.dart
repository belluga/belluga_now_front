import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorites_strip.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FavoritesSectionBuilder extends StatefulWidget {
  const FavoritesSectionBuilder({
    super.key,
    this.controller,
  });

  final FavoritesSectionController? controller;

  @override
  State<FavoritesSectionBuilder> createState() =>
      _FavoritesSectionBuilderState();
}

class _FavoritesSectionBuilderState extends State<FavoritesSectionBuilder> {
  late final FavoritesSectionController _controller =
      widget.controller ?? GetIt.I.get<FavoritesSectionController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() => super.dispose();

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
        final router = context.router;

        return Row(
          children: [
            Expanded(
              child: FavoritesStrip(
                items: items,
                pinned: pinned,
                onSearchTap: () {
                  router.push(DiscoveryRoute());
                },
                onFavoriteTap: (favorite) {
                  unawaited(_openFavoriteTarget(router, favorite));
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

  Future<void> _openFavoriteTarget(
    StackRouter router,
    FavoriteResume favorite,
  ) async {
    final target = await _controller.resolveNavigationTarget(favorite);
    switch (target) {
      case FavoriteNavigationPrimary():
        return;
      case FavoriteNavigationPartner():
        router.push(
          PartnerDetailRoute(slug: target.slug),
        );
        return;
      case FavoriteNavigationSearch():
        router.replaceAll(
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
