import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/presentation/tenant/partners/controllers/partner_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/partners/partner_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage()
class PartnerDetailRoute extends StatelessWidget {
  const PartnerDetailRoute({
    super.key,
    @PathParam('slug') required this.slug,
  });

  final String slug;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<DiscoveryModule>(
      child: PartnerDetailScreen(
        slug: slug,
        controller: GetIt.I.get<PartnerDetailController>(),
      ),
    );
  }
}
