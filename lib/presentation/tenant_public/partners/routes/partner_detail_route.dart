import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:belluga_now/presentation/tenant_public/partners/account_profile_detail_screen.dart';
import 'package:flutter/material.dart';
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
    final coverUri = model.coverUri;
    if (coverUri == null) {
      return AccountProfileDetailScreen(accountProfile: model);
    }

    return ImagePaletteTheme(
      imageProvider: NetworkImage(coverUri.toString()),
      builder: (context, _) => AccountProfileDetailScreen(
        accountProfile: model,
      ),
    );
  }
}
