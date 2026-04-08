import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant_public/static_assets/static_asset_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage()
class StaticAssetDetailRoute
    extends ResolverRoute<PublicStaticAssetModel, DiscoveryModule> {
  const StaticAssetDetailRoute({
    super.key,
    @PathParam('assetRef') required this.assetRef,
  });

  final String assetRef;

  @override
  RouteResolverParams get resolverParams => {'assetRef': assetRef};

  @override
  Widget buildScreen(BuildContext context, PublicStaticAssetModel model) {
    final coverUrl = model.coverUrl?.trim();
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return ImagePaletteTheme(
        imageProvider: NetworkImage(coverUrl),
        builder: (context, _) => StaticAssetDetailScreen(asset: model),
      );
    }

    return StaticAssetDetailScreen(asset: model);
  }
}
