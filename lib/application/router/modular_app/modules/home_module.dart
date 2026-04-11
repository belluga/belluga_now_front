import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class HomeModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<TenantHomeAgendaController>(
      () => TenantHomeAgendaController(),
    );

    registerLazySingleton<TenantHomeController>(
      () => TenantHomeController(),
    );

    registerLazySingleton(FavoritesSectionController.new);
    registerLazySingleton(InvitesBannerBuilderController.new);
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: TenantHomeRoute.page,
          guards: [TenantRouteGuard()],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.tenantHome),
        ),
        AutoRoute(
          path: '/privacy-policy',
          page: TenantPrivacyPolicyRoute.page,
          guards: [TenantRouteGuard()],
          meta: canonicalRouteMeta(
            family: CanonicalRouteFamily.tenantPrivacyPolicy,
          ),
        ),
        RedirectRoute(
          path: '/politica-de-privacidade',
          redirectTo: '/privacy-policy',
        ),
        RedirectRoute(
          path: '/home',
          redirectTo: '/',
        ),
      ];
}
