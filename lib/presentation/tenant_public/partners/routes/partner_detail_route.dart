import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/shared/widgets/seed_palette_theme.dart';
import 'package:belluga_now/presentation/tenant_public/partners/account_profile_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage()
class PartnerDetailRoute
    extends ResolverRoute<AccountProfileModel, DiscoveryModule> {
  const PartnerDetailRoute({
    super.key,
    @PathParam('slug') required this.slug,
  });

  final String slug;

  @override
  RouteResolverParams get resolverParams => {'slug': slug};

  @override
  Widget buildScreen(BuildContext context, AccountProfileModel model) {
    final registry = GetIt.I.isRegistered<AppData>()
        ? GetIt.I.get<AppData>().profileTypeRegistry
        : null;
    final resolvedVisual = AccountProfileVisualResolver.resolve(
      accountProfile: model,
      registry: registry,
    );
    final imageUrl = resolvedVisual.surfaceImageUrl;
    if (imageUrl != null) {
      return ImagePaletteTheme(
        imageProvider: NetworkImage(imageUrl),
        builder: (context, _) => AccountProfileDetailScreen(
          accountProfile: model,
        ),
      );
    }

    final seedColor = resolvedVisual.themeSeedColor;
    if (seedColor != null) {
      return SeedPaletteTheme(
        seedColor: seedColor,
        builder: (context, _) => AccountProfileDetailScreen(
          accountProfile: model,
        ),
      );
    }

    return AccountProfileDetailScreen(accountProfile: model);
  }
}
