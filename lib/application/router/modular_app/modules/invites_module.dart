import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class InvitesModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<InviteFlowScreenController>(
      () => InviteFlowScreenController(),
    );
    registerLazySingleton<InviteShareScreenController>(
      () => InviteShareScreenController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/convites',
          page: InviteFlowRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
        ),
        AutoRoute(
          path: '/invite',
          page: InviteEntryRoute.page,
          guards: [TenantRouteGuard()],
        ),
        AutoRoute(
          path: '/convites/compartilhar',
          page: InviteShareRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
        ),
      ];
}
