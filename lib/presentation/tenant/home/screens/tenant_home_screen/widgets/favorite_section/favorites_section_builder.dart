import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorites_strip.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FavoritesSectionBuilder extends StatefulWidget {
  const FavoritesSectionBuilder({
    super.key,
    required this.controller,
  });

  final FavoritesSectionController controller;

  @override
  State<FavoritesSectionBuilder> createState() =>
      _FavoritesSectionBuilderState();
}

class _FavoritesSectionBuilderState extends State<FavoritesSectionBuilder> {
  late final FavoritesSectionController _controller = widget.controller;
  StreamSubscription<FavoriteNavigationTarget?>? _navigationSubscription;

  @override
  void initState() {
    super.initState();
    _controller.init();
    _navigationSubscription =
        _controller.navigationTargetStreamValue.stream.listen(
      _handleNavigationTarget,
    );
    final target = _controller.navigationTargetStreamValue.value;
    if (target != null) {
      _handleNavigationTarget(target);
    }
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
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
                  _controller.requestNavigationTarget(favorite);
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

  void _handleNavigationTarget(FavoriteNavigationTarget? target) {
    if (target == null) return;
    final router = context.router;
    switch (target) {
      case FavoriteNavigationPrimary():
        _controller.clearNavigationTarget();
        return;
      case FavoriteNavigationPartner():
        router.push(
          PartnerDetailRoute(slug: target.slug),
        );
        _controller.clearNavigationTarget();
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
        _controller.clearNavigationTarget();
        return;
    }
  }
}
