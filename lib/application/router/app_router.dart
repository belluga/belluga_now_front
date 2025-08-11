import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: "/init", page: InitRoute.page, initial: true),
        AutoRoute(
          path: "/",
          page: TenantHomeRoute.page,
          guards: [TenantRouteGuard()],
        ),
        AutoRoute(path: "/", page: LandlordHomeRoute.page),
        AutoRoute(path: "/login", page: AuthLoginRoute.page),
        AutoRoute(path: "/recover_password", page: RecoveryPasswordRoute.page),
        AutoRoute(
            path: "/profile",
            page: ProfileRoute.page,
            guards: [AuthRouteGuard()]),
      ];
}
