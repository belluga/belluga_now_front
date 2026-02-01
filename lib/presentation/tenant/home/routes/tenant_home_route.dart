import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/home_module.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/tenant_home_screen.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantHomeRoute')
class TenantHomeRoutePage extends StatelessWidget {
  const TenantHomeRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<HomeModule>(
      child: TenantHomeScreen(
        controller: GetIt.I.get<TenantHomeController>(),
        favoritesController: GetIt.I.get<FavoritesSectionController>(),
        invitesBannerController: GetIt.I.get<InvitesBannerBuilderController>(),
        homeAgendaController: GetIt.I.get<TenantHomeAgendaController>(),
        appData: GetIt.I.get<AppData>(),
      ),
    );
  }
}
