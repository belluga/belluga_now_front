import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class AccountWorkspaceModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {}

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/workspace',
          page: AccountWorkspaceHomeRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
        ),
        AutoRoute(
          path: '/workspace/:accountSlug',
          page: AccountWorkspaceScopedRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
        ),
      ];
}
