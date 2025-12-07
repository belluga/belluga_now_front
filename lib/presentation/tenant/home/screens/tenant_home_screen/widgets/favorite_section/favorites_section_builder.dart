import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorites_strip.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FavoritesSectionBuilder extends StatelessWidget {
  const FavoritesSectionBuilder({
    super.key,
    required this.controller,
  });

  final TenantHomeController controller;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<FavoriteResume>?>(
      streamValue: controller.favoritesStreamValue,
      onNullWidget: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      builder: (context, favorites) {
        final items = favorites ?? const <FavoriteResume>[];

        return Row(
          children: [
            Expanded(
              child: FavoritesStrip(items: items, pinFirst: true),
            ),
          ],
        );
      },
    );
  }
}
